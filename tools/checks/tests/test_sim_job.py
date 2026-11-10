"""Tests for tools/sim/sim_job.py, the Actions sim job's entry point: configs are checked before
any runner starts, every seed lands in exactly one shard, and a soak merge counts what it finds."""

from __future__ import annotations

import contextlib
import io
import json
import shutil
import subprocess
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

    def test_build8_suite_uses_native_pool_without_reference_quilboar(self) -> None:
        config = self.config(kind="lines", suite="a35_run1", preset="B", first_seed=2911001, lobbies=32)
        values = sim_job.game_config(config)
        self.assertFalse(values["reference_quilboar"])
        self.assertFalse(values["card_size_caps"])
        self.assertEqual(values["pass3_preset"], "B")

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

    def test_optional_recruit_trace_never_changes_game_configuration(self) -> None:
        base = {"kind": "lines", "suite": "a35_run1", "preset": "B", "seeds": [1]}
        normal = self.config(**base)
        traced = self.config(**base, recruit_trace=True)
        self.assertEqual(sim_job.game_config(normal), sim_job.game_config(traced))
        self.assertNotIn("recruit_trace", sim_job.game_config(traced))
        with self.assertRaisesRegex(ValueError, "recruit_trace"):
            self.config(**base, recruit_trace="on")

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

    def test_exit_zero_line_logs_reject_every_gate_problem_before_compaction(self):
        config = self.config(kind="lines", preset="B", seeds=[1], shards=1)
        real_run = subprocess.run
        for problem in (
            "SCRIPT ERROR: planted runtime error",
            "ERROR: planted engine error",
            "WARNING: planted warning",
            "Parse Error: planted parser error",
            "[GUT ERROR] planted error",
            "[GUT WARNING] planted warning",
            "handle_crash: planted crash",
        ):

            def run(args, logged_problem=problem, **kwargs):
                if args[0] == "bash":
                    return real_run(args, **kwargs)
                kwargs["stdout"].write(logged_problem + "\ncomplete-looking capture written\n")
                return subprocess.CompletedProcess(args, 0)

            with (
                self.subTest(problem=problem),
                patch.object(sim_job.subprocess, "run", side_effect=run),
                patch.object(sim_job, "compact", return_value=[{"seed": 1}]) as compact,
            ):
                lobbies, dropped = sim_job.run_chunk(config, self.dir, 1, 1)
                self.assertEqual(lobbies, [])
                self.assertIn(problem, dropped[1])
                compact.assert_not_called()

    def test_log_hook_accepts_clean_logs_and_honors_the_shared_allowlist(self):
        scripts = self.dir / "scripts"
        checks = self.dir / "tools/checks"
        scripts.mkdir()
        checks.mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts/godot_log.sh", scripts / "godot_log.sh")
        (checks / "log_allowlist.txt").write_text("# permitted fixture\n^WARNING: harmless$\n")
        log = self.dir / "bench.log"
        with patch.object(sim_job, "ROOT", self.dir):
            for content in ("Godot Engine\ncompleted\n", "WARNING: harmless\n"):
                log.write_text(content)
                sim_job.check_godot_log(log)
            log.write_text("WARNING: harmful\n")
            with self.assertRaisesRegex(RuntimeError, "WARNING: harmful"):
                sim_job.check_godot_log(log)

    def test_ten_seeds_over_eight_shards_counts_the_skip_only_shard(self):
        config = self.config(kind="soak", preset="B", first_seed=1, lobbies=10, shards=8)
        shards = self.dir / "shards"

        def run(args, **_kwargs):
            first = int(args[args.index("--first-seed") + 1])
            count = int(args[args.index("tools/checks/soak.sh") + 1])
            seeds = range(first, first + count)
            mix = {}
            skipped = 0
            for seed in seeds:
                if seed % 5 == 4:
                    skipped += 1
                else:
                    kind = "other" if seed % 5 == 3 else "preset"
                    mix[kind] = mix.get(kind, 0) + 1
            report = (
                f"soak: games {count} (seeds {first}-{first + count - 1}), played {count - skipped}\n"
                f"soak: mix {json.dumps(mix)}; field skipped {skipped}; synthetic games 0\n"
                "soak: synthetic violations 0\nsoak: violations 0\n"
            )
            return subprocess.CompletedProcess(args, 0, stdout=report, stderr="")

        with patch.object(sim_job.subprocess, "run", side_effect=run) as execute:
            receipts = [sim_job.shard(config, i, shards) for i in range(1, 9)]
        self.assertEqual(execute.call_count, 7)
        self.assertEqual(receipts[6]["seeds"], [9])
        self.assertEqual(receipts[6]["played"], 0)
        self.assertEqual(receipts[6]["field_skipped"], 1)
        self.assertEqual(receipts[6]["violations"], 0)
        summary, _ = sim_job.merge(config, shards, self.dir / "result")
        self.assertTrue(summary["passes"])
        self.assertEqual((summary["games"], summary["played"], summary["field_skipped"]), (10, 8, 2))
        receipts[6]["field_skipped"] = 0
        self.assertFalse(sim_job.merge_soak(config, receipts, self.dir)["passes"])
        (shards / "shard-7.receipt.json").unlink()
        with self.assertRaisesRegex(ValueError, "shard 7: expected one receipt"):
            sim_job.merge(config, shards, self.dir / "result")

    def test_whole_soak_with_only_skipped_seeds_still_fails(self):
        config = self.config(kind="soak", preset="B", seeds=[9], shards=1)
        with patch.object(sim_job.subprocess, "run") as execute:
            receipt = sim_job.shard(config, 1, self.dir / "shards")
        execute.assert_not_called()
        summary = sim_job.merge_soak(config, [receipt], self.dir)
        self.assertEqual((summary["played"], summary["field_skipped"]), (0, 1))
        self.assertEqual(summary["report_problems"], [])
        self.assertFalse(summary["passes"])


if __name__ == "__main__":
    unittest.main()
