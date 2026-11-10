from __future__ import annotations

import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
import stone_soup_report as soup


def fixture():
    records = []
    for seed in range(32):
        has_soup = seed < 20
        eliminated = 20 <= seed < 24
        shopping = []
        for seat in range(8):
            shopping.append(
                {
                    "seat": seat,
                    "assigned_line": soup.ENGINE if seat == 0 else "hard:varied",
                    "placement": 8 if eliminated else 1,
                    "elimination_round": 10 if eliminated else None,
                    "offers_by_card": {"stone_soup": 2},
                    "buys_by_card": {"stone_soup": int(has_soup)},
                    "swallows_by_card": {"mouse": 1},
                    "nell_meals_by_card": {"mouse": 3},
                }
            )
        rows = []
        for number in (6, 8, 10, 12, 14):
            if eliminated and number > 10:
                continue
            rows.append(
                {
                    "seat": 0,
                    "round": number,
                    "cards": ["stone_soup"] if has_soup else ["mouse"],
                    "active_stats": 1000 if has_soup else 10,
                    "including_bellies": 1005 if has_soup else 15,
                }
            )
        records.append({"seed": seed, "shopping": shopping, "pre_start": rows})
    return records


class StoneSoupReportTests(unittest.TestCase):
    def test_known_thresholds_and_survivor_denominators(self):
        report = soup.summarize(fixture(), list(range(32)))
        self.assertTrue(report["all_bars_pass"])
        self.assertEqual(report["bars"]["fielded_by_r6"]["count"], 20)
        survival = report["bars"]["eliminated_before_r12"]
        self.assertEqual(survival["soup_cohort"], {"seats": 20, "out": 0, "rate": 0})
        self.assertEqual(survival["other_engine_seats"]["rate"], 4 / 12)
        self.assertEqual(report["rounds"]["12"]["engine_boards_observed"], 28)
        self.assertEqual(report["rounds"]["12"]["engine_eliminated_before_round"], 4)
        self.assertEqual(report["rounds"]["12"]["survivor_median_active_stats"], 1000)
        self.assertEqual(report["engine_card_totals"]["nell_meals_by_card"], {"mouse": 96})

    def test_late_soup_changes_prevalence_and_cutoff_sensitivity(self):
        records = fixture()
        records[25]["pre_start"][2]["cards"] = ["stone_soup"]  # First seen at R10.
        records[26]["pre_start"][3]["cards"] = ["stone_soup"]  # First seen at R12.
        report = soup.summarize(records, list(range(32)))
        self.assertEqual(report["cohort_sensitivity"]["by_r6"]["soup"]["seats"], 20)
        self.assertEqual(report["cohort_sensitivity"]["by_r10"]["soup"]["seats"], 21)
        self.assertEqual(report["bars"]["eliminated_before_r12"]["soup_cohort"]["seats"], 21)
        self.assertEqual(report["bars"]["soup_on_r12_engine_boards"]["count"], 21)
        self.assertFalse(report["engine_seat_details"][26]["soup_before_r12"])

    def test_incomplete_duplicate_or_wrong_engine_cohorts_are_rejected(self):
        records = fixture()
        for changed in (records[:-1], [*records[:-1], records[0]]):
            with self.assertRaises(ValueError):
                soup.summarize(changed, list(range(32)))
        wrong = copy.deepcopy(records)
        wrong[0]["shopping"][1]["assigned_line"] = soup.ENGINE
        with self.assertRaises(ValueError):
            soup.summarize(wrong, list(range(32)))

    def test_empty_comparator_does_not_claim_survival_bar_pass(self):
        records = fixture()
        for record in records:
            for row in record["pre_start"]:
                row["cards"] = ["stone_soup"]
        report = soup.summarize(records, list(range(32)))
        self.assertFalse(report["bars"]["eliminated_before_r12"]["passes"])
        self.assertIsNone(report["bars"]["eliminated_before_r12"]["other_engine_seats"]["rate"])


if __name__ == "__main__":
    unittest.main()
