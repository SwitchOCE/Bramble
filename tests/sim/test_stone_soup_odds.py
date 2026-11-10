from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
import stone_soup_odds as odds


def fixture():
    metrics = []
    probe = {"offers": [], "events": [], "draws": [], "parity_boards_checked": 1536}
    for seed in range(32):
        metrics.append(
            {
                "seed": seed,
                "shopping": [
                    {
                        "seat": 0,
                        "assigned_line": "line_oozes_engine",
                        "first_soup_fielded_round": 3 if seed < 17 else None,
                    }
                ],
            }
        )
        probe["draws"].append(
            {
                "seed": seed,
                "engine": True,
                "round": 1,
                "shop_tier": 1,
                "hazard": 0.05,
                "soup_left": 15,
                "tier1_left": 300,
                "tier1_weight": 1.0,
                "other_seats_owned_soup_copies": 0,
            }
        )
        if seed < 18:
            probe["offers"].append({"seed": seed, "engine": True, "round": 3, "card": "stone_soup"})
        if seed < 17:
            probe["events"].append({"seed": seed, "type": "buy", "round": 3, "fields": {"unit": "stone_soup"}})
    return probe, metrics


class SoupOddsTests(unittest.TestCase):
    def test_availability_and_purchase_gap_have_separate_denominators(self):
        probe, metrics = fixture()
        result = odds.report(probe, metrics)
        self.assertEqual(
            (result["soup_seen_by_r6"], result["soup_bought_by_r6"], result["soup_fielded_by_r6"]), (18, 17, 17)
        )
        self.assertEqual(result["opportunity_shortfall"], 2)
        self.assertEqual(result["observed_selection_gap"], 1)
        self.assertFalse(result["bar_attainable_by_buy_selection_only_on_this_route"])
        self.assertEqual(len(result["seats"][17]["missed_offer_details"]), 1)
        self.assertAlmostEqual(result["mean_realized_pool_route_reference"], 0.05)

    def test_realized_hazards_and_original_round_route_are_used(self):
        probe, metrics = fixture()
        probe["draws"].append(
            {
                "seed": 0,
                "engine": True,
                "round": 2,
                "shop_tier": 2,
                "hazard": 0.1,
                "soup_left": 10,
                "tier1_left": 50,
                "tier1_weight": 0.5,
                "other_seats_owned_soup_copies": 3,
            }
        )
        route = [
            {"seed": "0", "seat": "0", "round": "6", "tier": "3", "paid_refreshes": "2", "gold_left": "3"},
            {"seed": "0", "seat": "0", "round": "7", "tier": "4", "paid_refreshes": "9", "gold_left": "0"},
        ]
        result = odds.report(probe, metrics, route)
        self.assertAlmostEqual(result["seats"][0]["realized_pool_route_reference"], 1 - 0.95 * 0.9)
        self.assertEqual(result["engine_paid_refreshes_by_r6"], 2)
        self.assertEqual(result["seats"][0]["other_seat_owned_soup_max"], 3)
        self.assertEqual(result["seats"][0]["tier1_copies_left_range"], [50, 300])
        self.assertEqual(len(result["seats"][0]["actual_round_route"]), 1)

    def test_first_arrival_estimate_stops_at_first_hit(self):
        probe, metrics = fixture()
        probe["draws"][0]["drawn"] = "stone_soup"
        later = dict(probe["draws"][0], round=2, hazard=0.9, drawn="other")
        probe["draws"].append(later)
        result = odds.report(probe, metrics)
        self.assertAlmostEqual(result["seats"][0]["first_arrival_hazard"], 0.05)
        self.assertAlmostEqual(result["first_arrival_probability_estimate"], 0.05)
        self.assertGreater(result["seats"][0]["realized_pool_route_reference"], 0.9)
        self.assertAlmostEqual(result["first_arrival_bootstrap_90"][0], 0.05)
        self.assertAlmostEqual(result["first_arrival_bootstrap_90"][1], 0.05)

    def test_missing_draws_and_duplicate_source_lobbies_are_rejected(self):
        probe, metrics = fixture()
        with self.assertRaises(ValueError):
            odds.report(probe, metrics[:-1])
        with self.assertRaises(ValueError):
            odds.report(probe, [*metrics[:-1], metrics[0]])
        probe["draws"] = probe["draws"][:-1]
        with self.assertRaises(ValueError):
            odds.report(probe, metrics)


if __name__ == "__main__":
    unittest.main()
