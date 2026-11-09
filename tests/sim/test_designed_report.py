"""Designed-field reports validate budgets and cluster paired orientations."""

import copy
import itertools
import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from designed_report import interval, markdown, summarize


def board(identifier, shape="carry", answer="none", **changes):
    return {
        "id": identifier,
        "design": {
            "scale": "typical",
            "distribution": shape,
            "keywords": [],
            "answer": answer,
            "target_total": 500,
            "realized_total": 500,
            "bodies": 7,
            **changes,
        },
    }


def field():
    return {
        "rounds": {
            "12": {
                "boards": [
                    board("carry"),
                    board("wide", "even"),
                    board("carry-answer", answer="biggest"),
                    board("wide-answer", "even", "biggest"),
                ]
            }
        }
    }


def trials(source, reps=4):
    return [
        {
            "round": int(number),
            "a": a["id"],
            "b": b["id"],
            "replicate": rep,
            "seed": str(1000 + rep),
            "wins_a": 2,
            "wins_b": 0,
            "draws": 0,
            "trials": 2,
        }
        for number, data in source["rounds"].items()
        for a, b in itertools.combinations(data["boards"], 2)
        for rep in range(reps)
    ]


class DesignedReportTests(unittest.TestCase):
    def test_known_wins_draws_and_all_four_matched_answer_combinations(self):
        source = field()
        rows = trials(source)
        rows[0].update(wins_a=0, wins_b=0, draws=2)
        report = summarize(source, rows, 4)
        pair = report["pairs"][0]
        self.assertEqual(pair["win_rate_a"], 0.75)
        self.assertEqual(pair["point_rate_a"], 0.875)
        self.assertEqual(pair["draw_rate"], 0.25)
        self.assertEqual(report["fights"], 48)
        matched = report["matched_carry_vs_even"]
        self.assertEqual(len(matched), 1)
        self.assertEqual(len(matched[0]["comparisons"]), 4)
        # This pair appears reversed in field ordering. Carry must get B's wins.
        reverse = matched[0]["comparisons"]["carry=biggest;wide=none"]
        self.assertEqual(reverse["carry_win_rate"], 0)
        self.assertIn("draws 25.0%", markdown(report))

    def test_interval_uses_independent_seeds_not_twice_the_orientation_count(self):
        lo, hi = interval(0.5, 64)
        radius = math.sqrt(math.log(40) / 128)
        self.assertAlmostEqual(hi - 0.5, radius)
        self.assertAlmostEqual(0.5 - lo, radius)
        self.assertGreater(hi - lo, interval(0.5, 128)[1] - interval(0.5, 128)[0])
        self.assertGreater(interval(0, 64)[1], 0)
        self.assertLess(interval(1, 64)[0], 1)

    def test_missing_duplicate_unexpected_and_malformed_outcomes_rejected(self):
        source = field()
        rows = trials(source)
        with self.assertRaisesRegex(ValueError, "missing replicate"):
            summarize(source, rows[:-1], 4)
        with self.assertRaisesRegex(ValueError, "duplicate"):
            summarize(source, rows + rows[:1], 4)
        for change, message in [
            ({"a": "unknown"}, "unexpected"),
            ({"trials": 1}, "both orientations"),
            ({"wins_b": 1}, "both orientations"),
            ({"wins_a": True}, "integer"),
            ({"replicate": 4}, "replicate"),
            ({"seed": "01"}, "canonical"),
            ({"round": "12"}, "integer"),
        ]:
            with self.subTest(change=change):
                changed = copy.deepcopy(rows)
                changed[0].update(change)
                with self.assertRaisesRegex(ValueError, message):
                    summarize(source, changed, 4)

    def test_repeated_seed_does_not_count_as_independent_replication(self):
        source = field()
        rows = trials(source)
        rows[1]["seed"] = rows[0]["seed"]
        with self.assertRaisesRegex(ValueError, "distinct"):
            summarize(source, rows, 4)

    def test_main_matches_require_equal_requested_and_realized_total_and_keywords(self):
        for change in [{"target_total": 700}, {"realized_total": 490}, {"keywords": ["shield"]}, {"scale": "strong"}]:
            with self.subTest(change=change):
                source = {"rounds": {"12": {"boards": [board("carry"), board("wide", "even", **change)]}}}
                self.assertEqual(summarize(source, trials(source), 4)["matched_carry_vs_even"], [])

    def test_boundary_cases_are_reported_separately_with_clamp_metadata(self):
        source = {
            "rounds": {
                "15": {
                    "boards": [
                        board("carry", scale="boundary", target_total=4200000000, realized_total=2000000000),
                        board("wide", "even", scale="boundary", target_total=3000000000, realized_total=3000000000),
                    ]
                }
            }
        }
        report = summarize(source, trials(source), 4)
        self.assertEqual(report["matched_carry_vs_even"], [])
        self.assertEqual(len(report["boundary_comparisons"]), 1)
        self.assertEqual(report["board_designs"][0]["realized_total"], 2000000000)
        self.assertIn("Clamp-boundary", markdown(report))

    def test_bad_design_duplicate_ids_and_invalid_reps_fail(self):
        source = field()
        source["rounds"]["12"]["boards"][1]["id"] = "carry"
        with self.assertRaisesRegex(ValueError, "unique"):
            summarize(source, [], 4)
        source = field()
        del source["rounds"]["12"]["boards"][0]["design"]["bodies"]
        with self.assertRaisesRegex(ValueError, "incomplete"):
            summarize(source, [], 4)
        with self.assertRaisesRegex(ValueError, "positive"):
            summarize(field(), [], 0)


if __name__ == "__main__":
    unittest.main()
