"""Fixed paper denominators must never absorb Hard seats or missing runs."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from wave1_accounting import LINES, ROUNDS
from wave1_accounting_report import compare, load_paper_reference, project_rows, summarize


class AccountingReportTests(unittest.TestCase):
    def test_published_denominator_stays_paired_with_the_historical_run(self):
        paper = load_paper_reference()
        self.assertEqual(paper["rates"]["fairies_fetch_share"], 0.5)
        self.assertEqual(paper["authored_paper_pre_start"]["birds_homecoming"]["12"]["pre_start"], 615)
        self.assertEqual(paper["authored_paper_pre_start"]["fairies_ring"]["12"]["pre_start"], 530)

    def test_ratio_interval_is_real_seed_interval_over_fixed_paper(self):
        real = {"rounds": {str(r): {"median": 100, "ci95": [80, 120]} for r in ROUNDS}}
        paper = {str(r): {"pre_start": 200} for r in ROUNDS}
        timing = {str(r): {"pre_start": 100} for r in ROUNDS}
        result = compare(real, paper, timing)
        self.assertEqual(result["12"]["ratio_ci95"], [0.4, 0.6])
        self.assertTrue(result["r12_inside_0_5_to_2"])
        self.assertNotIn("r12_built_timing_inside_same_band", result)
        self.assertEqual(result["12"]["real_div_built_timing_paper"], 1)
        real["rounds"]["12"]["median"] = 99
        self.assertFalse(compare(real, paper, timing)["r12_inside_0_5_to_2"])

    def test_line_figures_exclude_hard_and_count_missing_survivors_separately(self):
        rows = []
        for seed in (1, 2, 3):
            for r in ROUNDS:
                for index, line in enumerate((*LINES, "hard_field")):
                    if seed == 3 and r == 14 and line != "hard_field":
                        continue
                    rows.append(
                        {
                            "seed": seed,
                            "round": r,
                            "line": line,
                            "stats": 100000 if line == "hard_field" else 100 + index,
                            "post_start_stats": 999999,
                            "tier": 6,
                            "ring_size": 1,
                            "slots": [],
                            "homecomings": 0,
                            "largest_share": 0.25,
                            "units": [],
                        }
                    )
        result = summarize(rows, [1, 2, 3], load_paper_reference(), 64, 81)
        for index, line in enumerate(LINES):
            self.assertEqual(result["lines"][line]["rounds"]["12"]["median"], 100 + index)
            self.assertEqual(result["lines"][line]["rounds"]["14"]["boards"], 2)
            self.assertEqual(result["lines"][line]["post_start_medians_for_context"]["12"], 999999)
        self.assertEqual(len(result["lines"]), 4)
        self.assertIn("Preliminary", result["growth_qualification"])

    def test_sufficient_archive_preserves_all_statistics_and_engine_windows(self):
        rows = [
            {
                "seed": seed,
                "seat": seat,
                "round": r,
                "line": line,
                "stats": seed * 100 + r,
                "post_start_stats": seed * 200 + r,
                "tier": 6,
                "ring_size": 2,
                "slots": [[{"count": 3, "attack": 6}, {"count": 2, "health": 4}]],
                "homecomings": 1,
                "largest_share": 0.25,
                "units": [
                    {"active": True, "def_id": "old_moth_annis", "attack": 8},
                    {"active": True, "def_id": "old_moth_annis", "attack": 9},
                    {"active": False, "def_id": "silky", "attack": 1000},
                ],
            }
            for seed in (1, 2)
            for r in ROUNDS
            for seat, line in enumerate(LINES)
        ]
        paper = load_paper_reference()
        self.assertEqual(summarize(rows, [1, 2], paper, 32), summarize(project_rows(rows), [1, 2], paper, 32))
