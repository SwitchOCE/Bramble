import json
import random
import statistics
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from field import boards_from_capture
from metrics import (
    placement_ranking,
    checkpoint_growth,
    clustered_rate,
    curvature_check,
    curvature_with_intervals,
    percentile,
    summarize,
)


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
    def test_checkpoint_growth_known_answer_reads_capture_transport(self):
        records = []
        for seed in (1, 2):
            for leg in (0, 1):
                for number in range(8, 15):
                    sides = [board(seed, seat, number, 10 * 2 ** (number - 8)) for seat in (0, 1)]
                    snapshots = [{**side["combat_start"], "layout": "blind"} for side in sides]
                    after = [
                        {
                            **snapshot,
                            "active_stats": 10 * 3 ** (number - 8),
                            "units": [
                                {
                                    **snapshot["units"][0],
                                    "attack": 5 * 3 ** (number - 8),
                                    "health": 5 * 3 ** (number - 8),
                                }
                            ],
                        }
                        for snapshot in snapshots
                    ]
                    records.append(
                        {
                            "seed": seed,
                            "leg": leg,
                            "input": {
                                "round": number,
                                "player_ids": [0, 1],
                                "boards": [side["board"] for side in sides],
                                "slots": [[0], [0]],
                                "fight_rules": [[], []],
                                "hero_effects": [[], []],
                                "tiers": [1, 1],
                                "config": {},
                            },
                            "combat_start": snapshots,
                            "after_start_effects": after,
                        }
                    )
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "known-answer.fights.jsonl"
            path.write_text("".join(json.dumps(record) + "\n" for record in records))
            players = [
                {"seed": seed, "leg": leg, "seat": seat, "place": seat + 1, "rounds": 14}
                for seed in (1, 2)
                for leg in (0, 1)
                for seat in (0, 1)
            ]
            result = summarize(boards_from_capture([path]), players)["checkpoint_1_growth"]
        for phase, expected in (("pre_start", 2), ("post_start", 3)):
            self.assertAlmostEqual(result[phase]["per_round_factor"], expected)
            self.assertEqual(result[phase]["boards_by_round"], dict.fromkeys(map(str, range(8, 15)), 8))
            for bound in result[phase]["ci95"]:
                self.assertAlmostEqual(bound, expected)
        self.assertEqual(result["deciding_phase"], "pre_start")
        self.assertEqual(result["uncertainty"]["seed_clusters"], 2)

    def test_checkpoint_bootstrap_matches_whole_seed_reconstruction_with_survivors(self):
        rows = [
            {
                "seed": seed,
                "leg": leg,
                "seat": seat,
                "round": number,
                "pre_start_stats": 100 + seed * (number - 7) ** 2 + seat,
                "stats": 100 + seed * (number - 7) ** 3 + seat,
                "stats_phase": "after_start_effects",
            }
            for seed in (1, 2, 3)
            for leg in (0, 1)
            for number in range(8, 15)
            for seat in range(seed + 2 if number < 12 else seed)
        ]
        result = checkpoint_growth(rows, replicates=128, bootstrap_seed=71)
        rng = random.Random(71)
        draws = {phase: [] for phase in ("pre_start", "post_start")}
        for _ in range(128):
            sample = [row for seed in rng.choices([1, 2, 3], k=3) for row in rows if row["seed"] == seed]
            for phase, key in (("pre_start", "pre_start_stats"), ("post_start", "stats")):
                start, end = [statistics.median(row[key] for row in sample if row["round"] == n) for n in (8, 14)]
                draws[phase].append((end / start) ** (1 / 6))
        for phase, values in draws.items():
            self.assertEqual(result[phase]["ci95"], [percentile(values, 0.025), percentile(values, 0.975)])
        duplicated = checkpoint_growth(rows * 2, replicates=128, bootstrap_seed=71)
        for phase in draws:
            self.assertEqual(result[phase]["per_round_factor"], duplicated[phase]["per_round_factor"])
            self.assertEqual(result[phase]["ci95"], duplicated[phase]["ci95"])
        self.assertEqual(result["uncertainty"], duplicated["uncertainty"])

    def test_checkpoint_unsupported_endpoints_and_intervals_are_explicit(self):
        def row(seed, number, stats):
            return {
                "seed": seed,
                "round": number,
                "pre_start_stats": stats,
                "stats": stats,
                "stats_phase": "pre_start_fallback",
            }

        result = checkpoint_growth([row(1, 8, 10), row(1, 14, 100)])["pre_start"]
        self.assertIsNotNone(result["per_round_factor"])
        self.assertIsNone(result["ci95"])
        self.assertEqual(result["interval_unsupported_reason"], "fewer_than_two_independent_seeds")
        for rows, reason in (
            ([row(1, 8, 10)], "missing_round_14"),
            ([row(1, 8, 0), row(2, 14, 10)], "nonpositive_or_nonfinite_round_8_median"),
        ):
            result = checkpoint_growth(rows)
            self.assertIsNone(result["pre_start"]["per_round_factor"])
            self.assertEqual(result["pre_start"]["unsupported_reason"], reason)
            self.assertIsNone(result["post_start"]["per_round_factor"])
            self.assertEqual(result["post_start"]["unsupported_reason"], "missing_round_8")

    def test_linear_shape_and_percentiles_are_known(self):
        boards = [board(seed, seat, r, 10 * r) for seed in (1, 2) for r in range(1, 17) for seat in range(4)]
        players = [
            {"seed": seed, "leg": 0, "seat": seat, "place": seat + 1, "rounds": 16}
            for seed in (1, 2)
            for seat in range(4)
        ]
        result = summarize(boards, players)
        self.assertTrue(result["curvature_check"]["flat"])
        self.assertEqual(result["curvature_check"]["slope"], 10)
        self.assertEqual(result["rounds"]["8"]["growth_delta"]["p50"], 10)
        self.assertEqual(percentile([0, 10], 0.9), 9)
        self.assertEqual(result["outcomes"]["r8_stat_leader_wins"]["rate"], 0.25)

    def test_fifteen_percent_compounding_fails_the_curvature_flat_check(self):
        result = curvature_check([(r, 100 * 1.15 ** (r - 6)) for r in range(6, 17)])
        self.assertFalse(result["flat"])
        self.assertGreater(result["late_early_growth_ratio"], 2)

    def test_curvature_rmse_bar_can_fail_while_growth_ratio_passes(self):
        result = curvature_check([(r, 100 + 10 * (r - 6) + (40 if r == 11 else 0)) for r in range(6, 17)])
        self.assertGreater(result["linear_relative_rmse"], result["relative_rmse_limit"])
        self.assertEqual(result["late_early_growth_ratio"], 1)
        self.assertFalse(result["flat"])

    def test_curvature_growth_ratio_bar_can_fail_while_rmse_passes(self):
        result = curvature_check([(r, 1000 + 10 * (r - 6) + (r - 6) ** 2) for r in range(6, 17)])
        self.assertLess(result["linear_relative_rmse"], result["relative_rmse_limit"])
        self.assertGreater(abs(result["late_early_growth_ratio"] - 1), result["growth_ratio_tolerance"])
        self.assertFalse(result["flat"])

    def test_curvature_intervals_match_an_independent_whole_seed_resample(self):
        rows = [
            {"seed": seed, "leg": leg, "round": r, "stats": 100 + seed * (r - 6) ** 2 + seat}
            for seed in (1, 2, 3)
            for leg in (0, 1)
            for r in range(6, 17)
            for seat in range(seed)
        ]
        result = curvature_with_intervals(rows, replicates=128, bootstrap_seed=71)
        rng = random.Random(71)
        draws = {key: [] for key in ("linear_relative_rmse", "late_early_growth_ratio")}
        for _ in range(128):
            sample = [row for seed in rng.choices([1, 2, 3], k=3) for row in rows if row["seed"] == seed]
            fit = curvature_check(
                [(r, statistics.median(row["stats"] for row in sample if row["round"] == r)) for r in range(6, 17)]
            )
            for key in draws:
                draws[key].append(fit[key])
        for key, values in draws.items():
            self.assertEqual(result[f"{key}_ci95"], [percentile(values, 0.025), percentile(values, 0.975)])
        self.assertEqual(result["uncertainty"]["seed_clusters"], 3)
        self.assertEqual(result["uncertainty"]["supported_round_grid_draws"], 128)
        self.assertEqual(result, curvature_with_intervals(rows, replicates=128, bootstrap_seed=71))
        self.assertEqual(result, curvature_with_intervals(rows * 2, replicates=128, bootstrap_seed=71))

    def test_curvature_bootstrap_does_not_treat_many_seats_as_independent(self):
        rows = [
            {"seed": seed, "round": r, "stats": 10 * r if seed == 1 else 100 * 1.15 ** (r - 6)}
            for seed, seats in [(1, 8), (2, 1)]
            for r in range(6, 17)
            for _ in range(seats)
        ]
        result = curvature_with_intervals(rows, replicates=400)
        compound = curvature_check([(r, 100 * 1.15 ** (r - 6)) for r in range(6, 17)])
        self.assertAlmostEqual(result["late_early_growth_ratio_ci95"][1], compound["late_early_growth_ratio"])
        self.assertEqual(result["uncertainty"]["seed_clusters"], 2)

    def test_curvature_interval_is_unknown_with_one_seed(self):
        result = curvature_with_intervals([{"seed": 1, "round": r, "stats": r * 10} for r in range(6, 17)])
        self.assertTrue(result["flat"])
        self.assertIsNone(result["linear_relative_rmse_ci95"])
        self.assertIsNone(result["late_early_growth_ratio_ci95"])

    def test_curvature_bootstrap_reports_draws_without_the_complete_round_grid(self):
        rows = [{"seed": 1 if r <= 11 else 2, "round": r, "stats": 10 * r} for r in range(6, 17)]
        result = curvature_with_intervals(rows, replicates=100)
        self.assertGreater(result["uncertainty"]["supported_round_grid_draws"], 0)
        self.assertLess(result["uncertainty"]["supported_round_grid_draws"], 100)

    def test_post_start_stats_and_concentration_have_a_reader(self):
        row = board(1, 0, 8, 100)
        after = {
            **row["combat_start"],
            "active_stats": 400,
            "largest_share": 0.75,
            "units": [{**row["combat_start"]["units"][0], "attack": 200, "health": 200}],
        }
        row["after_start_effects"] = after
        result = summarize([row], [{"seed": 1, "seat": 0, "place": 1, "rounds": 8}])
        self.assertEqual(result["rounds"]["8"]["stats"]["p50"], 400)
        self.assertEqual(result["rounds"]["8"]["largest_share"]["p50"], 0.75)
        self.assertEqual(result["rounds"]["8"]["start_effect_delta"]["p50"], 300)
        self.assertEqual(result["stats_phase_counts"], {"after_start_effects": 1})

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

    def test_placement_rank_keeps_starting_tempo_separate_from_final_homecoming(self):
        players = [
            {"seed": seed, "bot": bot, "strategy": "line_birds_homecoming", "place": place}
            for seed in (1, 2)
            for bot, place in (("line_birds_tempo", 4), ("line_birds_homecoming", 1))
        ]
        ranked = {row["line"]: row for row in placement_ranking(players)}
        self.assertEqual(set(ranked), {"line_birds_tempo", "line_birds_homecoming"})
        self.assertEqual(ranked["line_birds_tempo"]["mean_place"], 4)
        self.assertEqual(ranked["line_birds_tempo"]["seats"], 2)
        self.assertEqual(ranked["line_birds_tempo"]["final_strategy_counts"], {"line_birds_homecoming": 2})
