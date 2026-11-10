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
