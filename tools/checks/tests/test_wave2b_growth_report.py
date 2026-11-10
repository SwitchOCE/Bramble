"""Fixed synthetic rows pin growth, paired-cohort and shopping denominators."""

import unittest

from tools.sim.wave2b_growth_report import summarize


def snapshot(seat, round_number, stats):
    return {
        "seat": seat,
        "round": round_number,
        "assigned_line": "hedgerow_supper",
        "active_stats": stats,
        "including_bellies": stats * 2,
    }


def shop(seat, line, build, buys, offers):
    return {
        "seat": seat,
        "assigned_line": line,
        "build": build,
        "buys_by_tribe": {"Hedgerow folk": buys},
        "offers_by_tribe": {"Hedgerow folk": offers},
    }


class Wave2bGrowthReportTest(unittest.TestCase):
    def test_matched_cohort_differs_from_survivor_endpoint_and_keeps_raw_rows(self):
        record = {
            "seed": 11,
            "pre_start": [snapshot(0, 8, 1), snapshot(1, 8, 100), snapshot(1, 12, 900), snapshot(1, 14, 6400)],
        }
        report = summarize([record, record], {}, {"hedgerow_supper": 1800})
        line = report["lines"]["hedgerow_supper"]
        self.assertEqual(line["survivor_counts"], {"r8": 2, "r12": 1, "r14": 1})
        self.assertEqual(report["unique_pre_start_rows"], 4)
        self.assertAlmostEqual(line["endpoint_growth"]["active_stats"], (6400 / 50.5) ** (1 / 6))
        paired = line["paired_r14_survivors"]
        self.assertEqual(paired["count"], 1)
        self.assertAlmostEqual(paired["metrics"]["active_stats"]["matched_medians_growth"], 2)
        self.assertAlmostEqual(paired["metrics"]["including_bellies"]["median_individual_growth"], 2)
        self.assertEqual(paired["raw_rows"][0]["seed"], 11)
        self.assertEqual(paired["raw_rows"][0]["seat"], 1)
        self.assertEqual(line["r12_accounting"]["active_stats"]["median_divided_by_900"], 1)
        self.assertEqual(line["r12_accounting"]["including_bellies"]["median_divided_by_paper"], 1)
        self.assertIsNone(line["rounds"]["9"]["active_stats"])

    def test_conflicting_duplicates_fail(self):
        with self.assertRaisesRegex(ValueError, "conflicting duplicate"):
            summarize([{"seed": 1, "pre_start": [snapshot(0, 8, 2), snapshot(0, 8, 3)]}], {})
        with self.assertRaisesRegex(ValueError, "conflicting duplicate"):
            summarize(
                [{"seed": 1, "shopping": [shop(0, "hard:varied", "x", 1, 2), shop(0, "hard:varied", "x", 2, 2)]}], {}
            )

    def test_splash_uses_declared_highest_weight_and_excludes_line_seats(self):
        strategies = {
            "mixed": {"tribes": {"Hedgerow folk": 2, "Birds": 3}},
            "hedge": {"tribes": {"Hedgerow folk": 3, "Birds": 1}},
        }
        shopping = [
            shop(0, "hard:varied", "mixed", 2, 20),
            shop(1, "hard:varied", "hedge", 5, 10),
            shop(2, "hedgerow_supper", "mixed", 99, 100),
            shop(3, "hard:varied", "missing", 1, 4),
        ]
        splash = summarize([{"seed": 1, "shopping": shopping}], strategies)["splash"]
        self.assertEqual(splash["groups"]["off_build"]["buys"], 2)
        self.assertEqual(splash["groups"]["own_build"]["unique_offers"], 10)
        self.assertEqual(splash["groups"]["unknown_build"]["seats"], 1)
        self.assertEqual(len(splash["raw_seats"]), 3)
        self.assertAlmostEqual(splash["off_vs_own_buy_rate_ratio"], 0.2)

    def test_zero_denominators_are_null_and_zero_start_cohort_is_retained(self):
        report = summarize([{"seed": 1, "pre_start": [snapshot(0, 8, 0), snapshot(0, 14, 64)]}], {})
        line = report["lines"]["hedgerow_supper"]
        self.assertIsNone(line["endpoint_growth"]["active_stats"])
        self.assertIsNone(line["paired_r14_survivors"]["raw_rows"][0]["active_stats"]["growth"])
        self.assertEqual(line["paired_r14_survivors"]["metrics"]["active_stats"]["individual_growth_samples"], 0)
        self.assertIsNone(report["splash"]["off_vs_own_buy_rate_ratio"])

    def test_early_finished_lobbies_are_counted_once_not_filled_with_zeroes(self):
        record = {"seed": 5, "rounds": 13, "pre_start": [snapshot(0, 8, 10)]}
        report = summarize([record, record], {})
        self.assertEqual(report["lobbies_ending_before_r14"]["count"], 1)
        self.assertEqual(report["lobbies_ending_before_r14"]["seeds"], [5])
        self.assertIsNone(report["lines"]["hedgerow_supper"]["rounds"]["14"]["active_stats"])

    def test_median_individual_growth_is_distinct_from_growth_of_matched_medians(self):
        rows = [snapshot(0, 8, 1), snapshot(0, 14, 64), snapshot(1, 8, 100), snapshot(1, 14, 100)]
        paired = summarize([{"seed": 1, "pre_start": rows}], {})["lines"]["hedgerow_supper"]["paired_r14_survivors"]
        result = paired["metrics"]["active_stats"]
        self.assertAlmostEqual(result["median_individual_growth"], 1.5)
        self.assertAlmostEqual(result["matched_medians_growth"], (82 / 50.5) ** (1 / 6))


class ReportTribeBoundaryTests(unittest.TestCase):
    def test_known_neutral_builds_are_off_build_not_unknown(self):
        report = summarize(
            [{"seed": 3, "shopping": [shop(0, "hard:varied", "neutral", 2, 8)]}],
            {"neutral": {"tribes": {}}},
        )
        self.assertEqual(report["splash"]["groups"]["off_build"]["buys_per_unique_offer"], 0.25)
        self.assertEqual(report["splash"]["groups"]["unknown_build"]["seats"], 0)

    def test_measured_tribe_is_read_from_records_and_mixed_inputs_fail(self):
        record = {
            "seed": 4,
            "tribe": "Oozes",
            "shopping": [
                {
                    "seat": 0,
                    "assigned_line": "hard:varied",
                    "build": "ooze",
                    "buys_by_tribe": {"Oozes": 3},
                    "offers_by_tribe": {"Oozes": 10},
                }
            ],
        }
        report = summarize([record], {"ooze": {"tribes": {"Oozes": 1}}})
        self.assertEqual(report["splash"]["tribe"], "Oozes")
        self.assertEqual(report["splash"]["groups"]["own_build"]["buys_per_unique_offer"], 0.3)
        with self.assertRaisesRegex(ValueError, "mixed measured tribes"):
            summarize([record, {"seed": 5, "tribe": "Hedgerow folk"}], {})
