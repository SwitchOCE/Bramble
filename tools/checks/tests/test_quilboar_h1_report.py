"""Known answers for the reference's two usability criteria and seed intervals."""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location("quilboar_h1_report", ROOT / "tools/sim/quilboar_h1_report.py")
REPORT = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = REPORT
SPEC.loader.exec_module(REPORT)


def synthetic_lobbies(ratio=1, fidelity=5):
    paper = REPORT.paper_reference()
    games = []
    for arm in ("B", "C", "uncut", "uncut_frozen"):
        for seed in (11, 12):
            roster = [
                {"seat": seat, "line": line} for seat, line in enumerate((REPORT.QB, *REPORT.TRIBE_LINES, "hard"))
            ]
            rows = []
            for r in (8, 9, 12, 14, 15):
                qb = paper["arms"][arm]["rounds"][str(r)]["stats"] * ratio
                for seat, entry in enumerate(roster):
                    stats = qb if seat == 0 else qb / fidelity
                    rows.append(
                        {
                            "round": r,
                            "seat": seat,
                            "line": entry["line"],
                            "stats": stats,
                            "post_start_stats": stats * 2,
                            "largest_share": 0.25,
                            "post_start_largest_share": 0.3,
                            "commit_round": 6 if seat == 0 else 1,
                            "keystone_found_round": 11 if seat == 0 else None,
                        }
                    )
            games.append(
                {
                    "arm": arm,
                    "seed": seed,
                    "elapsed_seconds": 2,
                    "roster": roster,
                    "rounds": rows,
                    "players": [{**entry, "place": entry["seat"] + 1} for entry in roster],
                }
            )
    return games


class QuilboarH1ReportTests(unittest.TestCase):
    def test_paper_reproduces_final_spec_without_tmp_dependencies(self):
        paper = REPORT.paper_reference()["arms"]
        expected = {"B": [167, 1144, 3363], "C": [203, 1942, 6123], "uncut": [222, 6195, 23945]}
        for arm, values in expected.items():
            self.assertEqual([paper[arm]["rounds"][str(r)]["stats"] for r in (9, 12, 15)], values)
        self.assertEqual(paper["uncut_frozen"]["rounds"]["12"]["stats"], 532)

    def test_cost_13_correction_is_fresh_and_preserves_declared_paper(self):
        declared = REPORT.paper_reference()
        corrected = REPORT.paper_reference(t6_upgrade_cost=13)
        self.assertEqual(corrected["t6_upgrade_cost"], 13)
        expected = {"B": [167, 1065, 3299], "C": [203, 1798, 6007], "uncut": [222, 5740, 23456]}
        for arm, values in expected.items():
            self.assertEqual([corrected["arms"][arm]["rounds"][str(r)]["stats"] for r in (9, 12, 15)], values)
        self.assertEqual(REPORT.paper_reference(), declared, "corrected model globals cannot leak into the criterion")

    def test_cost_correction_cannot_flip_a_declared_failure(self):
        games = synthetic_lobbies()
        for game in games:
            if game["arm"] == "B":
                for row in game["rounds"]:
                    if row["line"] == REPORT.QB and row["round"] == 12:
                        row["stats"] *= 0.49
        data = REPORT.summarize(games, replicates=10)
        row = data["criteria"]["accounting"]["arms"]["B"]["rounds"]["12"]
        self.assertEqual(row["paper"], 1144)
        self.assertEqual(row["paper_t6_13"], 1065)
        self.assertLess(row["real_div_paper"], 0.5)
        self.assertGreater(row["real_div_paper_t6_13"], 0.5)
        self.assertFalse(row["passes"])
        self.assertFalse(data["criteria"]["accounting"]["passes"])
        self.assertFalse(data["paper_t6_13_correction"]["deciding"])

    def test_round_median_tables_cover_all_four_versions_r6_through_r15(self):
        data = REPORT.summarize(synthetic_lobbies(), replicates=10)
        data["arm_versions"] = {"B": "post-fix", "C": "pre-fix", "uncut": "post-fix", "uncut_frozen": "pre-fix"}
        with tempfile.TemporaryDirectory() as directory:
            _, report = REPORT.write_report(data, Path(directory) / "report")
            text = report.read_text()
        section = text.split("## R6-R15 pre-start median boards", 1)[1].split("## Descriptive measurements", 1)[0]
        rows = [line for line in section.splitlines() if line.startswith("| ") and line.split(" | ")[0][2:].isdigit()]
        self.assertEqual(len(rows), 40)
        self.assertIn("### B (post-fix)", section)
        self.assertIn("### C (pre-fix)", section)
        self.assertIn("### uncut_frozen (pre-fix)", section)
        self.assertIn("| Round | Quilboar | Birds | Fairies | Bog | Hedgerow | Hunters | Oozes | Hard |", section)
        self.assertIn("Correction found after the original run", text)

    def test_failed_rerun_compares_the_shared_native_method_gap_without_new_criteria(self):
        data = REPORT.summarize(synthetic_lobbies(ratio=0.3), replicates=10)
        criteria = json.loads(json.dumps(data["criteria"]))
        data["cycle_fix_rerun"] = True
        data["arm_versions"] = {"B": "post-fix", "C": "pre-fix", "uncut": "post-fix", "uncut_frozen": "pre-fix"}
        with tempfile.TemporaryDirectory() as directory:
            _, report = REPORT.write_report(data, Path(directory) / "report")
            text = report.read_text()
        self.assertEqual(data["criteria"], criteria)
        self.assertTrue(data["paper_method_gap"]["uncut_point_in_native_range"])
        self.assertIn("No further tuning was performed", text)
        self.assertIn("consistent with a shared paper-method/bot realization gap", text)
        self.assertIn("does not isolate or prove causality", text)

    def test_native_range_includes_tempo_up_to_072(self):
        data = REPORT.summarize(synthetic_lobbies(ratio=0.3), replicates=10)
        data["cycle_fix_rerun"] = True
        for point, inside in [(0.6, True), (0.72, True), (0.721, False)]:
            with self.subTest(point=point):
                data["arms"]["uncut"]["paper_comparison"]["12"].update(
                    real_div_paper=point, ratio_ci95=[point, point]
                )
                lines = REPORT._method_gap_interpretation(data)
                self.assertEqual(data["paper_method_gap"]["native_wave1_r12_range"], [0.17, 0.72])
                self.assertEqual(data["paper_method_gap"]["uncut_point_in_native_range"], inside)
                self.assertIn("Birds Tempo: 0.72x", "\n".join(lines))

    def test_uncut_gap_is_primary_and_interval_overlap_is_not_a_point_match(self):
        data = REPORT.summarize(synthetic_lobbies(ratio=0.3), replicates=10)
        data["cycle_fix_rerun"] = True
        data["arms"]["uncut"]["paper_comparison"]["12"].update(real_div_paper=0.1, ratio_ci95=[0.08, 0.25])
        data["arms"]["C"]["paper_comparison"]["12"]["real_div_paper"] = 0.3
        lines = REPORT._method_gap_interpretation(data)
        result = data["paper_method_gap"]
        self.assertEqual(result["primary_arm"], "uncut")
        self.assertFalse(result["uncut_point_in_native_range"])
        self.assertTrue(result["uncut_interval_overlaps_native_range"])
        self.assertEqual(result["classification"], "point_outside_native_range_interval_overlaps")
        self.assertEqual(set(result["r12_real_div_declared_paper"]), {"B", "uncut"})
        self.assertIn("The point estimates do not match", "\n".join(lines))
        self.assertIn("Retained pre-fix C/frozen results do not enter this inference", "\n".join(lines))

    def test_synthetic_exact_paper_and_fivefold_reference_pass_both_criteria(self):
        data = REPORT.summarize(synthetic_lobbies(), replicates=30)
        self.assertTrue(data["criteria"]["accounting"]["passes"])
        self.assertTrue(data["criteria"]["fidelity"]["passes"])
        self.assertEqual(data["arms"]["B"]["lines"][REPORT.QB]["rounds"]["12"]["pre_start"]["point"], 1144)
        self.assertEqual(data["arms"]["B"]["lines"][REPORT.QB]["rounds"]["12"]["post_start"]["point"], 2288)
        self.assertIsNone(data["arms"]["B"]["lines"][REPORT.TRIBE_LINES[0]]["keystone_found_by_r12"]["point"])

    def test_accounting_fails_if_either_b_or_c_or_any_declared_round_misses(self):
        games = synthetic_lobbies()
        for game in games:
            if game["arm"] == "C":
                for row in game["rounds"]:
                    if row["line"] == REPORT.QB and row["round"] == 9:
                        row["stats"] *= 0.49
        result = REPORT.summarize(games, replicates=20)["criteria"]
        self.assertTrue(result["accounting"]["arms"]["B"]["passes"])
        self.assertFalse(result["accounting"]["passes"])
        self.assertTrue(result["fidelity"]["passes"])

    def test_fidelity_requires_fourfold_against_every_line(self):
        games = synthetic_lobbies()
        for game in games:
            if game["arm"] == "uncut":
                for row in game["rounds"]:
                    if row["line"] == REPORT.TRIBE_LINES[-1] and row["round"] == 12:
                        row["stats"] *= 2
        result = REPORT.summarize(games, replicates=20)["criteria"]
        self.assertTrue(result["accounting"]["passes"])
        self.assertFalse(result["fidelity"]["passes"])

    def test_bounds_are_inclusive(self):
        for ratio in (0.5, 2):
            self.assertTrue(
                REPORT.summarize(synthetic_lobbies(ratio), replicates=10)["criteria"]["accounting"]["passes"]
            )
        for ratio in (0.49, 2.01):
            self.assertFalse(
                REPORT.summarize(synthetic_lobbies(ratio), replicates=10)["criteria"]["accounting"]["passes"]
            )

    def test_seed_bootstrap_retains_eliminated_empty_clusters(self):
        measured = REPORT.bootstrap({11: [10, 20], 12: []}, replicates=200, seed=1)
        self.assertEqual(measured["point"], 15)
        self.assertEqual(measured["seed_clusters"], 2)
        self.assertEqual(measured["seed_clusters_with_observations"], 1)
        self.assertLess(measured["valid_draws"], 200)
        self.assertEqual(measured["ci95"], [15, 15])

    def test_smoke_withholds_usability_verdicts_and_writes_both_formats(self):
        data = REPORT.summarize(synthetic_lobbies(), smoke=True, replicates=10)
        self.assertIsNone(data["criteria"]["accounting"]["passes"])
        self.assertIsNone(data["criteria"]["fidelity"]["passes"])
        with tempfile.TemporaryDirectory() as directory:
            paths = REPORT.write_report(data, Path(directory) / "report")
            self.assertEqual(json.loads(paths[0].read_text())["version"], 1)
            self.assertIn("Exploratory smoke", paths[1].read_text())

    def test_missing_arm_is_not_a_passing_criterion_and_duplicate_seeds_reject(self):
        games = synthetic_lobbies()
        data = REPORT.summarize([g for g in games if g["arm"] != "C"], replicates=10)
        self.assertIsNone(data["criteria"]["accounting"]["passes"])
        with self.assertRaises(ValueError):
            REPORT.summarize([games[0], games[0]], replicates=10)


if __name__ == "__main__":
    unittest.main()
