import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from metrics import clustered_rate, percentile, summarize


def board(seed, seat, number, stats, line="hard", tier=1, iid=None):
    return {
        "seed": seed,
        "leg": 0,
        "seat": seat,
        "round": number,
        "line": line,
        "tier": tier,
        "board": [{"iid": iid if iid is not None else seat + 1}],
        "combat_start": {
            "active_stats": stats,
            "health": 40,
            "largest_share": 1,
            "gold_spent_game": number * 3,
            "gold_spent_turn": 3,
            "units": [
                {
                    "active": True,
                    "attack": stats / 2,
                    "health": stats / 2,
                    "slot": 0,
                    "tier": tier,
                    "golden": False,
                    "def_id": "plain",
                }
            ],
        },
    }


class MetricsTests(unittest.TestCase):
    def test_linear_shape_and_percentiles_are_known(self):
        boards = [board(seed, seat, r, 10 * r) for seed in (1, 2) for r in range(1, 17) for seat in range(4)]
        players = [
            {"seed": seed, "leg": 0, "seat": seat, "place": seat + 1, "rounds": 16}
            for seed in (1, 2)
            for seat in range(4)
        ]
        result = summarize(boards, players)
        self.assertTrue(result["historical_flat_shape_check"]["matches_historical_flat_shape"])
        self.assertEqual(result["historical_flat_shape_check"]["slope"], 10)
        self.assertEqual(result["rounds"]["8"]["growth_delta"]["p50"], 10)
        self.assertEqual(percentile([0, 10], 0.9), 9)
        self.assertEqual(result["outcomes"]["r8_stat_leader_wins"]["rate"], 0.25)

    def test_own_median_is_the_tier_arrival_denominator(self):
        result = summarize(
            [board(1, 0, 7, 100), board(1, 0, 8, 200, tier=2, iid=9)],
            [{"seed": 1, "leg": 0, "seat": 0, "place": 1, "rounds": 8}],
            {"plain": {"attack": 2, "health": 3}},
        )
        self.assertEqual(result["tier_arrivals"]["2"]["arrival_ratio"]["p50"], 2)
        self.assertEqual(result["tier_arrivals"]["2"]["printed_ratio"]["p50"], 0.05)

    def test_pooled_tail_is_separate_from_within_line_and_draws_are_not_uncertain(self):
        boards = [
            board(1, seat, 8, stats, "high" if seat == 3 else "low") for seat, stats in enumerate([98, 100, 102, 1000])
        ]
        players = [
            {"seed": 1, "leg": 0, "seat": seat, "place": place, "rounds": 16} for seat, place in enumerate([2, 3, 4, 1])
        ]
        field = {
            "pairs": [
                {"round": 10, "p_win_a": 0.5, "p_win_a_ci95": [0.3, 0.7], "pair_weight": 0.1},
                {"round": 12, "p_win_a": None, "p_win_a_ci95": None, "pair_weight": 0.3},
            ]
        }
        result = summarize(boards, players, field=field)
        self.assertEqual(result["rounds"]["8"]["share_2x_round_median"], 0.25)
        self.assertEqual(result["within_line"]["high"]["8"]["share_2x_round_median"], 0)
        self.assertEqual(result["outcomes"]["r8_below_pooled_median_top2"]["rate"], 0.5)
        uncertain = result["outcomes"]["field_uncertainty_r10_14"]
        self.assertEqual(uncertain["share_20_80"], 0.5)
        self.assertAlmostEqual(uncertain["weighted_share_20_80"], 0.25)

    def test_rate_clusters_are_seeds_not_seats(self):
        rate = clustered_rate([(1, 1, 1)] * 8 + [(2, 0, 1)] * 8)
        self.assertEqual(rate["seed_clusters"], 2)
        self.assertEqual(rate["n"], 16)
        self.assertEqual(rate["rate"], 0.5)
