"""Tiny deterministic bootstrap samples, without gameplay or long measurements."""

import io
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from tools.sim.wave2b_growth_report import bootstrap_intervals, main, percentile


def record(seed, early=None, late=None, rounds=14):
    rows = []
    for round_id, value in ((8, early), (14, late)):
        if value is not None:
            rows.append(
                {
                    "seat": 1,
                    "round": round_id,
                    "assigned_line": "line_test",
                    "active_stats": value,
                    "including_bellies": value * 2,
                }
            )
    return {"seed": seed, "rounds": rounds, "pre_start": rows}


class GrowthIntervalsTest(unittest.TestCase):
    def test_constant_growth_has_a_degenerate_exact_interval(self):
        report = bootstrap_intervals([record(1, 1, 64), record(2, 2, 128)], draws=40)
        metrics = report["lines"]["line_test"]["metrics"]
        for metric in metrics.values():
            for estimate in metric.values():
                self.assertAlmostEqual(estimate["estimate"], 2)
                self.assertEqual(estimate["ci90"], [2, 2])
                self.assertEqual(estimate["valid_bootstrap_draws"], 40)
                self.assertEqual(estimate["r8_n"], 2)
                self.assertEqual(estimate["r14_n"], 2)

    def test_sampling_is_reproducible_and_individual_diagnostic_is_distinct(self):
        rows = [record(1, 1, 64), record(2, 100, 100)]
        first = bootstrap_intervals(rows, draws=100, seed=123)
        self.assertEqual(first, bootstrap_intervals(rows, draws=100, seed=123))
        metric = first["lines"]["line_test"]["metrics"]["active_stats"]
        self.assertAlmostEqual(metric["individual_median_diagnostic"]["estimate"], 1.5)
        self.assertAlmostEqual(metric["matched_medians_primary"]["estimate"], (82 / 50.5) ** (1 / 6))

    def test_missing_r14_is_absent_not_zero_and_early_lobbies_remain_clusters(self):
        report = bootstrap_intervals([record(1, 100, 6400), record(2, 1, rounds=10)], draws=100)
        line = report["lines"]["line_test"]
        self.assertEqual(line["endpoint_counts"], {"r8": 2, "r12": 0, "r14": 1})
        self.assertEqual(line["paired_cohort_n"], 1)
        self.assertEqual(report["lobbies_ending_before_r14"], 1)
        primary = line["metrics"]["active_stats"]["matched_medians_primary"]
        survivor = line["metrics"]["active_stats"]["changing_survivor_medians"]
        self.assertEqual(primary["ci90"], [2, 2])
        self.assertLess(survivor["valid_bootstrap_draws"], 100)
        self.assertEqual(survivor["lobby_seed_n"], 2)

    def test_all_missing_or_zero_starts_return_null_with_counts(self):
        for rows in ([record(1, 1, rounds=10)], [record(1, 0, 64)]):
            report = bootstrap_intervals(rows, draws=20)
            metric = report["lines"]["line_test"]["metrics"]["active_stats"]
            self.assertIsNone(metric["matched_medians_primary"]["estimate"])
            self.assertEqual(metric["matched_medians_primary"]["ci90"], [None, None])
            self.assertEqual(metric["matched_medians_primary"]["valid_bootstrap_draws"], 0)

    def test_duplicate_rows_dedupe_and_conflicts_fail(self):
        item = record(1, 1, 64)
        report = bootstrap_intervals([item, item], draws=10)
        self.assertEqual(report["lines"]["line_test"]["paired_cohort_n"], 1)
        with self.assertRaisesRegex(ValueError, "conflicting duplicate"):
            bootstrap_intervals([item, record(1, 2, 64)], draws=10)
        self.assertEqual(percentile([1, 3], 0.05), 1.1)

    def test_bootstrap_cli_help_accepts_percentile_description(self):
        with (
            patch("sys.argv", ["wave2b_growth_report", "--help"]),
            redirect_stdout(io.StringIO()) as output,
            self.assertRaises(SystemExit) as raised,
        ):
            main()
        self.assertEqual(raised.exception.code, 0)
        self.assertIn("--bootstrap-only", output.getvalue())
        self.assertIn("--dataset", output.getvalue())
