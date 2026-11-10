"""Tests for tools/sim/sim_job.py, the Actions sim job's entry point: configs are checked before
any runner starts, every seed lands in exactly one shard, and a soak merge counts what it finds."""

from __future__ import annotations

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "sim"))

from tools.checks import sim_job  # noqa: E402


class SimJobTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def config(self, **values):
        path = self.dir / "c.json"
        path.write_text(json.dumps(values))
        return sim_job.load_config(path)

    def test_lines_config_and_round_robin_shards(self) -> None:
        config = self.config(kind="lines", preset="B", first_seed=100, lobbies=32, shards=8)
        self.assertEqual(config["suite"], "quilboar_h1")
        shards = [sim_job.shard_seeds(config, i) for i in range(1, 9)]
        self.assertEqual(sorted(s for shard in shards for s in shard), list(range(100, 132)))
        self.assertEqual(shards[0], [100, 108, 116, 124])

    def test_soak_shards_are_contiguous_blocks(self) -> None:
        config = self.config(kind="soak", preset="B", first_seed=1, lobbies=200, shards=8)
        shards = [sim_job.shard_seeds(config, i) for i in range(1, 9)]
        self.assertEqual(sorted(s for shard in shards for s in shard), list(range(1, 201)))
        for shard in shards:
            self.assertEqual(shard, list(range(shard[0], shard[0] + len(shard))))

    def test_bad_configs_are_refused(self) -> None:
        bad = [
            {"kind": "fights", "preset": "B", "seeds": [1]},
            {"kind": "lines", "preset": "Z", "seeds": [1]},
            {"kind": "lines", "preset": "B", "seeds": [1, 1]},
            {"kind": "lines", "preset": "B", "seeds": [1, 2], "lobbies": 3},
            {"kind": "lines", "preset": "B", "seeds": [1], "shards": 9},
            {"kind": "lines", "preset": "B", "seeds": [1], "suite": "lines"},
            {"kind": "soak", "preset": "B", "seeds": [1, 3]},
            {"kind": "soak", "preset": "Q", "seeds": [1]},
        ]
        for values in bad:
            with self.assertRaises(ValueError, msg=str(values)):
                self.config(**values)

    def test_runs_groups_contiguous_seeds_in_chunks(self) -> None:
        self.assertEqual(sim_job.runs([5, 1, 2, 3, 4, 9]), [[1, 4], [5, 1], [9, 1]])

    def test_rates_override_the_game_config(self) -> None:
        config = self.config(kind="lines", preset="C", seeds=[1], rates={"bog_soak_keep": 4})
        values = sim_job.game_config(config)
        self.assertEqual(values["pass3_preset"], "C")
        self.assertEqual(values["bog_soak_keep"], 4)

    def test_soak_merge_counts_violations_and_crashes(self) -> None:
        config = self.config(kind="soak", preset="B", first_seed=1, lobbies=4, shards=2)
        base = {
            "dropped": {},
            "seconds": 1,
            "field_skipped": 0,
            "synthetic": 0,
            "synthetic_violations": 0,
            "reported_games": 2,
        }
        receipts = [
            {**base, "shard": 1, "seeds": [1, 2], "exit": 1, "played": 2, "mix": {"preset": 2}, "violations": 1,
             "violation_lines": ["seed 1 round 3: x"], "synthetic_violation_lines": [], "crashes": [],
             "log_problems": False},
            {**base, "shard": 2, "seeds": [3, 4], "exit": 139, "played": 1, "mix": {"other": 1}, "violations": 0,
             "violation_lines": [], "synthetic_violation_lines": [], "crashes": [], "log_problems": False},
        ]  # fmt: skip
        summary = sim_job.merge_soak(config, receipts, self.dir)
        self.assertEqual(summary["violations"], 1)
        self.assertEqual(summary["mix"], {"other": 1, "preset": 2})
        self.assertEqual(summary["crashes"], ["shard 2: exit 139"])
        self.assertFalse(summary["passes"])

    def test_balanced_soak_shards_never_empty(self):
        for count in range(1, 34):
            config = self.config(kind="soak", preset="B", first_seed=1, lobbies=count, shards=8)
            shards = [sim_job.shard_seeds(config, i) for i in range(1, config["shards"] + 1)]
            self.assertTrue(all(shards))
            self.assertLessEqual(max(map(len, shards)) - min(map(len, shards)), 1)
            self.assertEqual([seed for block in shards for seed in block], list(range(1, count + 1)))

    def complete_receipt(self):
        return {
            "shard": 1,
            "seeds": [1, 2],
            "dropped": {},
            "seconds": 1,
            "reported_games": 2,
            "played": 2,
            "field_skipped": 0,
            "synthetic": 0,
            "synthetic_violations": 0,
            "mix": {"preset": 2},
            "violations": 0,
            "violation_lines": [],
            "synthetic_violation_lines": [],
            "crashes": [],
            "log_problems": False,
            "exit": 0,
        }

    def test_soak_requires_complete_counts_and_explained_exit(self):
        config = self.config(kind="soak", preset="B", seeds=[1, 2], shards=1)
        receipt = self.complete_receipt()
        self.assertTrue(sim_job.merge_soak(config, [receipt], self.dir)["passes"])
        for changes in (
            {"played": 0},
            {"violations": None},
            {"reported_games": None},
            {"exit": 1},
            {"field_skipped": 2},
            {"mix": {"other": 2}},
        ):
            with self.subTest(changes=changes):
                result = sim_job.merge_soak(config, [{**receipt, **changes}], self.dir)
                self.assertFalse(result["passes"])

    def test_soak_missing_duplicate_or_reassigned_receipts_rejected(self):
        config = self.config(kind="soak", preset="B", seeds=[1, 2], shards=1)
        receipt = self.complete_receipt()
        for receipts in ([], [receipt, receipt], [{**receipt, "seeds": [9, 10]}]):
            with self.assertRaises(ValueError):
                sim_job.merge_soak(config, receipts, self.dir)

    def test_persistent_line_failure_is_written_and_fails_cli(self):
        config_path = self.dir / "lines.json"
        config_path.write_text(json.dumps({"kind": "lines", "preset": "B", "seeds": [1], "shards": 1}))
        output = self.dir / "output"
        with (
            patch.object(sim_job, "bench", side_effect=RuntimeError("planted execution failure")),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            status = sim_job.main(["local", str(config_path), str(output)])
        self.assertEqual(status, 1)
        result = json.loads((output / "result/summary.json").read_text())
        self.assertFalse(result["passes"])
        self.assertIn("1", result["sim_job"]["dropped"])


if __name__ == "__main__":
    unittest.main()
