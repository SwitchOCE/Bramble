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
