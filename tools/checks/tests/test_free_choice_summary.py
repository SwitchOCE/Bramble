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

    def test_offered_denominator_and_clustered_intervals(self):
        rows = [
            {"seed": "1", "final_tribe": "Birds", "place": "1", "lobby_tribes": "Birds+Hunters"},
            {"seed": "1", "final_tribe": "Birds", "place": "7", "lobby_tribes": "Birds+Hunters"},
            {"seed": "2", "final_tribe": "Hunters", "place": "2", "lobby_tribes": "Hunters"},
            {"seed": "2", "final_tribe": "no_tribe", "place": "8", "lobby_tribes": "Hunters"},
        ]
        rates = {r["tribe"]: r for r in free_choice_rates(rows)}
        self.assertEqual(rates["Birds"]["lobby_seats"], 2)
        self.assertEqual(rates["Birds"]["lobby_pick_rate"], 1)
        self.assertEqual(rates["Birds"]["pick_rate_low"], 0)
        self.assertEqual(rates["Birds"]["pick_rate_high"], 1)
        self.assertIsNone(rates["no_tribe"]["lobby_pick_rate"])
        self.assertIsNone(rates["Fairies"]["avg_place_low"])
        single = free_choice_rates(rows[:2])[0]
        self.assertIsNone(single["pick_rate_low"], "one lobby cannot estimate cluster variance")

    def test_no_tribe_breakdown_preserves_ties_and_neutral_boards(self):
        from tools.sim.summarize_bench import no_tribe_rates

        rows = [
            {
                "final_tribe": "no_tribe",
                "place": "1",
                "no_tribe_reason": "mixed",
                "plurality_tribe": "Birds",
                "plurality_share": "0.5",
            },
            {
                "final_tribe": "no_tribe",
                "place": "3",
                "no_tribe_reason": "tied_plurality",
                "plurality_tribe": "Birds+Fairies",
                "plurality_share": "0.4",
            },
            {
                "final_tribe": "no_tribe",
                "place": "8",
                "no_tribe_reason": "neutral_only",
                "plurality_tribe": "no_tribe",
                "plurality_share": "0",
            },
            {"final_tribe": "Birds", "place": "2"},
        ]
        breakdown = no_tribe_rates(rows)
        self.assertEqual(sum(r["seats"] for r in breakdown), 3)
        self.assertEqual(len(breakdown), 3)
        self.assertAlmostEqual(sum(r["share_of_no_tribe"] for r in breakdown), 1)
        self.assertEqual(breakdown[0]["plurality"], "Birds")
