import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from wave1_baseline_compare import combine


class ComparisonTests(unittest.TestCase):
    def settings(self):
        shipped = {
            "source_commit": "known",
            "rates": {"birds": 2},
            "lobbies": 2,
            "selected_seeds": [1, 2],
            "config": {"tribes_per_lobby": 5, "card_size_caps": True, "card_rate_limits": True},
            "lines": {"line_birds_homecoming": {"median": 300}},
        }
        checkpoint = copy.deepcopy(shipped)
        checkpoint["config"].update(card_size_caps=False, card_rate_limits=False)
        return shipped, checkpoint

    def test_human_examples_are_case_comparisons_not_a_population_estimate(self):
        result = combine(*self.settings())
        self.assertAlmostEqual(result["human_comparison"]["shipped"]["human_a_div_script_median"], 772 / 300)
        self.assertIn("not a skilled-player population", result["human_scope"])
        self.assertEqual(len(result["deciding_measures"]), 2)

    def test_changed_seeds_or_dials_are_not_a_valid_caps_comparison(self):
        for field, changed in [("selected_seeds", [1, 3]), ("rates", {"birds": 3})]:
            shipped, checkpoint = self.settings()
            checkpoint[field] = changed
            with self.assertRaises(ValueError):
                combine(shipped, checkpoint)

    def test_reversed_caps_or_wrong_rotation_are_rejected(self):
        for key, changed in [("tribes_per_lobby", 0), ("card_size_caps", True)]:
            shipped, checkpoint = self.settings()
            checkpoint["config"][key] = changed
            with self.assertRaises(ValueError):
                combine(shipped, checkpoint)
