import itertools
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from field import field_report, quotas, sample_field


class FieldTests(unittest.TestCase):
    def boards(self):
        return [
            {"id": str(i), "round": 6, "line": "hard" if i < 80 else "tribal" if i < 99 else "rare"} for i in range(100)
        ]

    def test_stratified_reservoir_is_repeatable_and_preserves_population_weights(self):
        field = sample_field(self.boards(), (6,), 8)
        self.assertEqual(field, sample_field(self.boards(), (6,), 8))
        data = field["rounds"]["6"]
        self.assertEqual(len(data["boards"]), 8)
        self.assertEqual(data["line_weights"], {"hard": 0.8, "tribal": 0.19, "rare": 0.01})
        self.assertAlmostEqual(sum(b["weight"] for b in data["boards"]), 1)
        for line, weight in data["line_weights"].items():
            self.assertAlmostEqual(sum(b["weight"] for b in data["boards"] if b["line"] == line), weight)

    def test_missing_hard_and_insufficient_fields_fail(self):
        with self.assertRaises(ValueError):
            quotas({"tribal": 100}, 64)
        with self.assertRaises(ValueError):
            quotas({"hard": 2}, 64)

    def test_known_winner_and_null_draws_are_scored_with_a_hard_floor(self):
        field = sample_field(self.boards(), (6,), 4)
        pairs = []
        for a, b in itertools.combinations(field["rounds"]["6"]["boards"], 2):
            hard_a, hard_b = a["line"] == "hard", b["line"] == "hard"
            pairs.append(
                {
                    "round": 6,
                    "a": a["id"],
                    "b": b["id"],
                    "wins_a": 2 if hard_a and not hard_b else 0,
                    "wins_b": 2 if hard_b and not hard_a else 0,
                    "draws": 2 if hard_a == hard_b else 0,
                    "trials": 2,
                }
            )
        report = field_report(field, pairs)
        self.assertTrue(report["rounds"]["6"]["hard_floor_passes"])
        self.assertEqual(report["rounds"]["6"]["strongest_line"], "hard")
        self.assertEqual(report["rounds"]["6"]["win_matrix"]["hard"]["tribal"], 1)
        self.assertTrue(any(p["p_win_a"] is None for p in report["pairs"]))
        with self.assertRaises(ValueError):
            field_report(field, pairs[:-1])
        with self.assertRaises(ValueError):
            field_report(field, [*pairs, pairs[0]])
