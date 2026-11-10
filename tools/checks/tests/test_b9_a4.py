"""Bounded A4 planning: source guards, field budget and same-seat diagnostics."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools/sim"))

import b9_a4  # noqa: E402
import b9_a4_report as report  # noqa: E402


class A4Test(unittest.TestCase):
    def test_full_run_requires_an_explicit_source_before_starting_anything(self):
        with (
            patch.object(sys, "argv", ["b9_a4", "--full", "--out", "/tmp/never-a4"]),
            patch.object(b9_a4, "revision", return_value="a" * 40),
            patch.object(b9_a4, "run") as execute,
            contextlib.redirect_stderr(io.StringIO()),
            self.assertRaises(SystemExit) as raised,
        ):
            b9_a4.main()
        self.assertEqual(raised.exception.code, 2)
        execute.assert_not_called()

    def test_early_and_late_growth_exclude_seats_without_the_window_end(self):
        seats = {(1, 0): {6: 100, 11: 3200, 15: 259200}, (2, 0): {6: 1_000_000}}
        result = report.windows(seats)
        self.assertEqual(result["r6_r11"], {"p10_median_p90": [2.0, 2.0, 2.0], "n": 1})
        self.assertEqual(result["r11_r15"], {"p10_median_p90": [3.0, 3.0, 3.0], "n": 1})

    def test_magnitude_uses_the_identical_r15_cohort_at_r14(self):
        seats = {
            "line_birds_engine": {(1, 0): {14: 100, 15: 100}, (2, 0): {14: 100_000}},
            "line_bog_engine": {(1, 1): {14: 20, 15: 20}},
            "line_oozes_engine": {(1, 2): {14: 20, 15: 20}},
        }
        result = report.magnitude(seats)
        self.assertEqual(result["14"]["ratio"], 5)
        self.assertEqual(result["15"]["ratio"], 5)
        self.assertFalse(result["14"]["fires_10x"])
        self.assertFalse(result["14"]["complete"])

    def test_equal_line_field_has_no_own_line_pair_and_at_most_22_fights(self):
        boards = [
            {"id": f"{r}:{line}:{sample}", "round": r, "line": f"line_{line}", "test_cards": []}
            for r in (10, 12, 14)
            for line in range(12)
            for sample in range(3)
        ]
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "field.json"
            with patch.object(b9_a4.field, "boards_from_capture", return_value=iter(boards)):
                missing = b9_a4.sample_field(Path("unused"), out)
            data = json.loads(out.read_text())
        self.assertTrue(all(not values for values in missing.values()))
        for group in data["rounds"].values():
            self.assertEqual(len(group["boards"]), 12)
            self.assertEqual(len({b["line"] for b in group["boards"]}), 12)
            self.assertEqual(2 * (len(group["boards"]) - 1), 22)
            self.assertAlmostEqual(sum(group["line_weights"].values()), 1)

    def test_field_dominance_needs_both_rounds_and_complete_line_coverage(self):
        points = {f"line_{i}": 0.5 for i in range(12)}
        field = {
            "rounds": {
                "12": {"line_point_rates": {**points, "line_0": 0.9}},
                "14": {"line_point_rates": {**points, "line_0": 0.8}},
            }
        }
        self.assertTrue(report.field_dominance(field)["flag"])
        field["rounds"]["14"]["line_point_rates"]["line_0"] = 0.79
        self.assertFalse(report.field_dominance(field)["flag"])
        del field["rounds"]["14"]["line_point_rates"]["line_1"]
        self.assertIsNone(report.field_dominance(field)["flag"])

    def test_incomplete_magnitude_cannot_silently_pass_and_low_outliers_fire(self):
        values = {"14": {"complete": False, "fires_10x": False, "tribe_ratios": {"birds": 1}}}
        self.assertIsNone(report.outside_magnitude(values))
        values["14"]["complete"] = True
        self.assertFalse(report.outside_magnitude(values))
        values["14"]["tribe_ratios"]["birds"] = 0.1
        self.assertTrue(report.outside_magnitude(values))

    def test_early_runaway_win_counts_toward_the_extreme_and_denominator(self):
        games, winners = [], {}
        for seed, final, leader, won in [(1, 9, 100, True), (2, 10, 100, True), (3, 18, 20, False)]:
            games.append(
                {
                    "seed": seed,
                    "players": [{"rounds": final}],
                    "rounds": [
                        {"round": min(14, final), "seat": seat, "stats": stats, "line": f"line_{seat}"}
                        for seat, stats in [(0, leader), (1, 10)]
                    ],
                }
            )
            winners[seed, 0] = won
            winners[seed, 1] = not won
        data = report.snowballs(games, winners)
        self.assertEqual(data["eligible_lobbies"], 3)
        self.assertEqual(data["early_finish_lobbies"], 2)
        self.assertEqual(data["runaway_proxy_share"], 2 / 3)
        self.assertTrue(data["most_lobbies_proxy"])
        self.assertEqual([r["round"] for r in data["runaway_proxy_lobbies"]], [9, 10])

    def test_zero_runner_up_is_included_and_exactly_half_is_not_most(self):
        games = [
            {
                "seed": seed,
                "players": [{"rounds": 8}],
                "rounds": [
                    {"round": 8, "seat": seat, "stats": stats, "line": f"line_{seat}"}
                    for seat, stats in [(0, lead), (1, 0)]
                ],
            }
            for seed, lead in [(1, 10), (2, 0)]
        ]
        winners = {(seed, seat): seat == 0 for seed in (1, 2) for seat in (0, 1)}
        result = report.snowballs(games, winners)
        self.assertEqual(result["runaway_proxy_share"], 0.5)
        self.assertFalse(result["most_lobbies_proxy"])
        self.assertTrue(result["runaway_proxy_lobbies"][0]["zero_runner_up"])
