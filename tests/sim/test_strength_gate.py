"""Frozen lever-build strength reader; synthetic complete rank data, no Godot."""

import copy
import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from lever_sweep import digest, file_sha
from strength_gate import summarize, validate_plan


def plan():
    return {
        "version": 1,
        "source_commit": "a" * 40,
        "source_fingerprint": "b" * 64,
        "profiles_sha256": "c" * 64,
        "profiles": "tools/sim/line_profiles.committed.json",
        "builds": [
            {
                "id": build,
                "overrides": {"card_size_caps": False, "card_rate_limits": False, "scale_engine_percent": percent},
                "comparisons": [
                    {
                        "id": name,
                        "candidate": candidate,
                        "incumbent": "hard_field",
                        "independent_seeds": 80,
                        "first_seed": 150001 + offset * 1000 + number * 100,
                    }
                    for number, (name, candidate) in enumerate(
                        [("best", "line_hedgerow_tempo"), ("mixture", "tribal_mixture")]
                    )
                ],
            }
            for offset, (build, percent) in enumerate([("g25", 25), ("g50", 50)])
        ],
    }


def fixture(folder, frozen, best="positive", mixture="negative"):
    for build in frozen["builds"]:
        for comparison in build["comparisons"]:
            name = f"{build['id']}-{comparison['id']}"
            path = folder / f"{name}.players.csv"
            rows = []
            effect = best if comparison["id"] == "best" else mixture
            for seed in range(comparison["first_seed"], comparison["first_seed"] + 80):
                for leg in range(2):
                    counts = {"candidate": 0, "incumbent": 0}
                    for seat in range(8):
                        side = "candidate" if (seat < 4) == (leg == 0) else "incumbent"
                        counts[side] += 1
                        if effect == "null":
                            place = seat + 1
                        else:
                            top = "candidate" if effect == "positive" else "incumbent"
                            place = counts[side] + (0 if side == top else 4)
                        rows.append(
                            {
                                "seed": seed,
                                "leg": leg,
                                "seat": seat,
                                "side": side,
                                "place": place,
                                "candidate": comparison["candidate"],
                                "incumbent": "hard_field",
                                "strategy": "line_hedgerow_tempo" if side == "candidate" else "hard_field",
                            }
                        )
            with path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
            metadata = {
                "completed": True,
                "plan_sha256": digest(frozen),
                "source_commit": frozen["source_commit"],
                "source_fingerprint": frozen["source_fingerprint"],
                "profiles_sha256": frozen["profiles_sha256"],
                "config_sha256": digest(build["overrides"]),
                "players_sha256": file_sha(path),
            }
            (folder / f"{name}.run.json").write_text(json.dumps(metadata))


class StrengthGateTests(unittest.TestCase):
    def run_fixture(self, best):
        with tempfile.TemporaryDirectory() as directory:
            frozen = plan()
            folder = Path(directory)
            fixture(folder, frozen, best=best)
            with patch("strength_gate.line_outcome_rates", return_value={"tested_separately": True}):
                return summarize(frozen, folder)

    def test_positive_best_opens_gate_while_negative_mixture_remains_visible(self):
        report = self.run_fixture("positive")
        self.assertTrue(report["passes"])
        self.assertEqual(report["builds"]["g25"]["comparisons"]["best"]["ci95"], [4, 4])
        self.assertFalse(report["builds"]["g50"]["comparisons"]["mixture"]["passes"])
        self.assertEqual(report["builds"]["g50"]["comparisons"]["mixture"]["mean_place_gain"], -4)

    def test_real_per_line_first_and_top_four_rates_are_included(self):
        with tempfile.TemporaryDirectory() as directory:
            frozen = plan()
            folder = Path(directory)
            fixture(folder, frozen)
            report = summarize(frozen, folder)
        rates = report["builds"]["g25"]["comparisons"]["best"]["line_outcome_rates"]["lines"]
        self.assertEqual(rates["line_hedgerow_tempo"]["first_place"]["rate"], 0.25)
        self.assertEqual(rates["line_hedgerow_tempo"]["top_four"]["rate"], 1.0)
        self.assertEqual(rates["hard_field"]["top_four"]["rate"], 0.0)
        self.assertEqual(rates["hard_field"]["top_four"]["seed_clusters"], 80)

    def test_null_and_negative_best_cannot_open_gate(self):
        self.assertFalse(self.run_fixture("null")["passes"])
        self.assertFalse(self.run_fixture("negative")["passes"])

    def test_incomplete_positive_sample_is_rejected_even_with_updated_csv_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            frozen = plan()
            fixture(folder, frozen)
            path = folder / "g25-best.players.csv"
            lines = path.read_text().splitlines()
            path.write_text("\n".join(lines[:-16]) + "\n")
            meta = folder / "g25-best.run.json"
            data = json.loads(meta.read_text())
            data["players_sha256"] = file_sha(path)
            meta.write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "completed seed set"):
                summarize(frozen, folder)

    def test_source_config_profile_and_plan_provenance_mismatches_fail_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            frozen = plan()
            fixture(folder, frozen)
            path = folder / "g25-best.run.json"
            original = json.loads(path.read_text())
            for key in ["source_fingerprint", "source_commit", "profiles_sha256", "config_sha256", "plan_sha256"]:
                with self.subTest(key=key):
                    changed = {**original, key: "bad"}
                    path.write_text(json.dumps(changed))
                    with self.assertRaisesRegex(ValueError, key):
                        summarize(frozen, folder)
            path.write_text(json.dumps(original))
            changed_plan = copy.deepcopy(frozen)
            changed_plan["builds"][0]["comparisons"][0]["candidate"] = "hard_field"
            with self.assertRaisesRegex(ValueError, "candidate/incumbent"):
                validate_plan(changed_plan)

    def test_overlap_missing_comparison_and_wrong_budget_are_rejected(self):
        frozen = plan()
        changed = copy.deepcopy(frozen)
        changed["builds"][1]["comparisons"][0]["first_seed"] = 150001
        with self.assertRaisesRegex(ValueError, "overlap"):
            validate_plan(changed)
        changed = copy.deepcopy(frozen)
        changed["builds"][0]["comparisons"].pop()
        with self.assertRaisesRegex(ValueError, "both best and mixture"):
            validate_plan(changed)
        changed = copy.deepcopy(frozen)
        changed["builds"][0]["comparisons"][0]["independent_seeds"] = 81
        with self.assertRaisesRegex(ValueError, "exactly 80"):
            validate_plan(changed)

    def test_missing_metadata_cannot_produce_gate(self):
        with tempfile.TemporaryDirectory() as directory, self.assertRaises(FileNotFoundError):
            summarize(plan(), Path(directory))


if __name__ == "__main__":
    unittest.main()
