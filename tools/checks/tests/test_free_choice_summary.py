"""Final-board rates must include mixed seats in the denominator and retain unpicked tribes."""

import unittest

from tools.sim.summarize_bench import free_choice_rates


class TestFreeChoiceSummary(unittest.TestCase):
    def test_denominators_and_missing_tribes(self):
        rows = [
            {"final_tribe": "Birds", "place": "1", "strategy": "irrelevant"},
            {"final_tribe": "Birds", "place": "7", "strategy": "another_route"},
            {"final_tribe": "no_tribe", "place": "2", "strategy": "birds_highway"},
            {"final_tribe": "Hunters", "place": "8", "strategy": "birds_highway"},
        ]
        rates = {rate["tribe"]: rate for rate in free_choice_rates(rows)}
        self.assertEqual(rates["Birds"]["pick_rate"], 0.5)
        self.assertEqual(rates["Birds"]["avg_place"], 4)
        self.assertEqual(rates["Birds"]["first_rate"], 0.5)
        self.assertEqual(rates["no_tribe"]["pick_rate"], 0.25)
        self.assertEqual(rates["no_tribe"]["first_rate"], 0)
        self.assertEqual(rates["Fairies"]["seats"], 0)
        self.assertIsNone(rates["Fairies"]["avg_place"])
        self.assertIsNone(rates["Fairies"]["first_rate"])
        self.assertEqual(sum(rate["pick_rate"] for rate in rates.values()), 1)

    def test_empty_run_is_not_a_zero_win_observation(self):
        rates = free_choice_rates([])
        self.assertEqual(len(rates), 7)
        self.assertTrue(all(rate["avg_place"] is None for rate in rates))
