"""Fast statistical known answers; run: python3 -m unittest discover -s tests/sim."""

import copy
import csv
import hashlib
import random
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from check_lines import head_to_head, line_breakdown, validate_profiles
from size_line_check import required_seeds
from tune_lines import gain, variants


class LineToolsTests(unittest.TestCase):
    def _rows(self, strong):
        rows = []
        for seed in range(6):
            for leg in range(2):
                counts = {"candidate": 0, "incumbent": 0}
                for seat in range(8):
                    side = "candidate" if (seat < 4) == (leg == 0) else "incumbent"
                    counts[side] += 1
                    place = counts[side] + (0 if side == "candidate" else 4) if strong else seat + 1
                    rows.append(
                        {
                            "seed": seed,
                            "leg": leg,
                            "seat": seat,
                            "side": side,
                            "place": place,
                            "candidate": "line_fast",
                            "incumbent": "hard",
                        }
                    )
        return rows

    def _report(self, rows, plan=None):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "players.csv"
            with path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
            return head_to_head(path, plan)

    def test_clear_gain_passes_and_a_null_policy_does_not(self):
        strong = self._report(self._rows(True))
        self.assertEqual(strong["independent_seeds"], 6)
        self.assertEqual(strong["mean_place_gain"], 4)
        self.assertTrue(strong["passes"])
        self.assertFalse(self._report(self._rows(False))["passes"])

    def test_incomplete_or_duplicate_pairs_fail(self):
        rows = self._rows(True)
        with self.assertRaises(ValueError):
            self._report(rows[:-1])
        with self.assertRaises(ValueError):
            self._report([*rows, rows[0]])

    def test_plan_rejects_positive_but_incomplete_samples(self):
        plan = {"candidate": "line_fast", "incumbent": "hard", "independent_seeds": 6, "seed_range": [0, 5]}
        self.assertTrue(self._report(self._rows(True), plan)["passes"])
        with self.assertRaises(ValueError):
            self._report(self._rows(True)[:-16], plan)
        plan["candidate"] = "different_policy"
        with self.assertRaises(ValueError):
            self._report(self._rows(True), plan)

    def test_power_sizing_uses_seed_variance(self):
        self.assertEqual(required_seeds(1.2268693220279547, 0.3958333333333333), 76)
        self.assertGreater(required_seeds(2, 0.4), required_seeds(1, 0.4))
        with self.assertRaises(ValueError):
            required_seeds(1, 0)

    def test_frozen_profile_table_rejects_changed_data(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "profiles.json"
            path.write_text('{"policy_version":1}')
            plan = {"profiles_sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
            validate_profiles(path, plan)
            path.write_text('{"policy_version":2}')
            with self.assertRaises(ValueError):
                validate_profiles(path, plan)

    def test_breakdown_counts_seed_clusters_and_controls_seat_roles(self):
        rows = self._rows(True)
        for row in rows:
            row["strategy"] = "line_hunters_engine" if row["side"] == "candidate" else "hunters_pact"
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "players.csv"
            with path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
            report = line_breakdown(path, {"line_hunters_engine": {"tribe": "Hunters"}})
        group = report["groups"]["tribe:Hunters"]
        self.assertEqual(group["seed_clusters"], 6)
        self.assertEqual(group["candidate_seats"], 48)
        self.assertEqual(group["mean_place_gain"], 4)
        self.assertEqual(group["ci95"], [4, 4])

    def test_variants_leave_the_reference_profile_untouched(self):
        original = {"climb_schedule": [3, 5, 7, 9, 11], "priority_weight": 12, "save_threshold": 2, "engine": True}
        before = copy.deepcopy(original)
        candidates = variants(original, 3, random.Random(1))
        self.assertEqual(len(candidates), 4)
        self.assertEqual(original, before)
        candidates[0]["climb_schedule"][0] = 99
        self.assertEqual(original, before)

    def test_held_out_gain_uses_independent_samples(self):
        result = gain({"places": [5, 6]}, {"places": [1, 2]})
        self.assertEqual(result["places"], 4)
        self.assertLess(result["normal_ci95"][0], 4)
        self.assertGreater(result["normal_ci95"][0], 0)


if __name__ == "__main__":
    unittest.main()
