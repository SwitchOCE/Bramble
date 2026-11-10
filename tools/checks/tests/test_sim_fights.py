"""Exact pair/seed transport around the existing native field and designed readers."""

from __future__ import annotations

import importlib
import json
import tempfile
import unittest
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import patch

from tools.checks import sim_fights

# sim_fights adds the measurement readers to sys.path.
recipes = importlib.import_module("designed_setups")


class SimFightsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.work = Path(self.tmp.name)
        self.document = recipes.make_document(
            [
                recipes.make_board(12, 50, distribution="carry"),
                recipes.make_board(12, 50, distribution="even"),
            ]
        )
        self.path = self.work / "designed.json"
        self.path.write_text(json.dumps(self.document))
        self.config = {"kind": "designed", "preset": "B", "seeds": [123, 9007199254740993], "input": str(self.path)}

    def rows(self):
        field = sim_fights.load_field(self.config)
        return [
            {"round": number, "a": left, "b": right, "seed": str(seed), "replicate": index,
             "wins_a": 1, "wins_b": 1, "draws": 0, "trials": 2}
            for number, left, right in sim_fights._pairs(field)
            for index, seed in enumerate(self.config["seeds"])
        ]  # fmt: skip

    def records(self):
        return [
            {"seed": seed, "pairs": [row for row in self.rows() if row["seed"] == str(seed)]}
            for seed in self.config["seeds"]
        ]

    def test_constructed_setups_use_existing_weighted_and_carry_even_readers(self):
        sim_fights.validate(self.config)
        summary = sim_fights.summarize(self.config, self.records())
        self.assertEqual(summary["fights"], 4)
        self.assertEqual(summary["source_mode"], "designed_only")
        comparisons = summary["constructed_comparisons"]
        self.assertEqual(comparisons["replicates_per_pair"], 2)
        self.assertEqual(comparisons["pairs"][0]["win_rate_a"], 0.5)
        self.assertEqual(comparisons["matched_carry_vs_even"][0]["total"], 50)

    def test_sampled_field_and_rates_preserve_full_board_state(self):
        field = sim_fights.load_field(self.config)
        records = self.records()
        self.path.write_text(json.dumps(field))
        config = {**self.config, "kind": "field", "preset": "C", "rates": {"bog_soak_keep": 7}}
        sim_fights.validate(config)
        changed = sim_fights.load_field(config)
        before = field["rounds"]["12"]["boards"][0]
        after = changed["rounds"]["12"]["boards"][0]
        self.assertEqual(after["board"], before["board"])
        self.assertEqual(after["fight_rules"], before["fight_rules"])
        self.assertEqual(after["slots"], before["slots"])
        self.assertEqual(after["config"]["pass3_preset"], "C")
        self.assertEqual(after["config"]["bog_soak_keep"], 7)
        exact = json.loads(after["config"]["pass3_rates_exact_json"])
        self.assertEqual(exact["bog_soak_keep"], 7)
        summary = sim_fights.summarize(config, records)
        self.assertNotIn("constructed_comparisons", summary)

    def test_native_invocation_preserves_large_seed_and_checks_all_orientations(self):
        def fake_run(args, **kwargs):
            output = Path(args[args.index("--") + 2])
            seeds = json.loads(Path(args[-1]).read_text())
            self.assertEqual(seeds, [str(seed) for seed in self.config["seeds"]])
            self.assertEqual(kwargs["env"]["GODOT_SLOT_CLASS"], "worker")
            output.write_text("\n".join(json.dumps(row) for row in self.rows()))
            return CompletedProcess(args, 0)

        with patch.object(sim_fights.subprocess, "run", side_effect=fake_run):
            records, receipt = sim_fights.shard(self.config, self.config["seeds"], self.work / "shard")
        self.assertEqual(records, self.records())
        self.assertEqual(receipt["fights"], 4)
        self.assertEqual(len(receipt["input_sha256"]), 64)

    def test_missing_duplicate_and_cross_seed_pairs_are_rejected(self):
        records = self.records()
        records[0]["pairs"] = []
        with self.assertRaisesRegex(ValueError, "incomplete"):
            sim_fights.summarize(self.config, records)
        records = self.records()
        records[0]["pairs"] *= 2
        with self.assertRaisesRegex(ValueError, "duplicate"):
            sim_fights.summarize(self.config, records)
        records = self.records()
        records[0]["pairs"][0]["seed"] = str(self.config["seeds"][1])
        with self.assertRaisesRegex(ValueError, "disagrees"):
            sim_fights.summarize(self.config, records)

    def test_native_failure_and_truncated_success_are_rejected(self):
        with (
            patch.object(sim_fights.subprocess, "run", return_value=CompletedProcess([], 1)),
            self.assertRaisesRegex(RuntimeError, "exited 1"),
        ):
            sim_fights.shard(self.config, self.config["seeds"], self.work / "failure")

        def truncated(args, **_kwargs):
            Path(args[args.index("--") + 2]).write_text("")
            return CompletedProcess(args, 0)

        with (
            patch.object(sim_fights.subprocess, "run", side_effect=truncated),
            self.assertRaisesRegex(ValueError, "incomplete"),
        ):
            sim_fights.shard(self.config, self.config["seeds"], self.work / "truncated")

    def test_invalid_fixture_and_out_of_range_seed_fail_before_godot(self):
        self.document["boards"][0]["fight_rules"].pop("nests")
        self.path.write_text(json.dumps(self.document))
        with self.assertRaisesRegex(ValueError, "missing required"):
            sim_fights.validate(self.config)
        with self.assertRaisesRegex(ValueError, "64-bit"):
            sim_fights.validate({**self.config, "seeds": [2**63]})


if __name__ == "__main__":
    unittest.main()
