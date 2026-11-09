import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

STAGE = Path(__file__).resolve().parents[2]
SOURCE = STAGE / "tools/sim/skilled_birds.py"
spec = importlib.util.spec_from_file_location("skilled_birds", SOURCE)
skilled_birds = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = skilled_birds
spec.loader.exec_module(skilled_birds)


class SkilledBirdsTest(unittest.TestCase):
    def test_human_names_with_commas_and_other_player_exclusion(self):
        rows = skilled_birds.parse_human(
            "You: place 1\n  R12 T6 win spent 0: F1 Squire Lollop, Lord of the Manor 6/8, "
            "F2 *The Great Lump 113/151\nOther: place 2\n  R12 T6 win spent 0: F1 Bad 999/999\n"
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["stats"], 278)
        self.assertEqual(rows[0]["biggest"]["name"], "The Great Lump")
        self.assertTrue(rows[0]["biggest"]["golden"])

    def test_actual_human_refs_reproduce_totals_and_biggest_units(self):
        tree = Path("/home/alex/code/Bramble-ideation-sol")
        if not (tree / ".git").exists():
            self.skipTest("local source checkout unavailable")
        examples = skilled_birds.human_examples(tree)
        self.assertEqual([row["stats"] for row in examples[0]["rows"]], [329, 772, 2085, 2676])
        self.assertEqual([row["stats"] for row in examples[1]["rows"]], [272, 459, 883, 1617])
        self.assertEqual(examples[0]["rows"][3]["biggest"]["attack"], 272)
        self.assertEqual(examples[1]["rows"][3]["biggest"]["health"], 554)

    def test_only_flight_call_changes_in_native_turn_flow(self):
        tree = Path("/home/alex/code/Bramble-ideation-sol")
        if not (tree / "src/core/bots/bot_brain.gd").exists():
            self.skipTest("local source checkout unavailable")
        self.assertEqual(len(skilled_birds.verify_native_flow(tree, SOURCE.parent)), 64)

    def fixture(self):
        units = [
            {
                "def_id": "bird",
                "attack": 10,
                "health": 20,
                "active": True,
                "golden": False,
                "location": "board",
            },
            {
                "def_id": "nest_egg",
                "attack": 0,
                "health": 1,
                "active": True,
                "golden": False,
                "location": "egg",
            },
            {
                "def_id": "carry",
                "attack": 100,
                "health": 200,
                "active": False,
                "golden": True,
                "location": "away",
            },
        ]
        fight = {
            "type": "fight",
            "seed": 1,
            "arm": "aggressive",
            "input": {"round": 12, "player_ids": [0, -1]},
            "combat_start": [
                {
                    "units": units,
                    "active_stats": 31,
                    "largest_share": 30 / 31,
                    "starting_line": "line_birds_homecoming",
                    "health_before_fight": 5,
                    "hero": "hero",
                }
            ],
        }
        lobby = {
            "type": "lobby",
            "seed": 1,
            "arm": "aggressive",
            "tribes": ["Birds", "Fairies", "A", "B", "C"],
            "starting_lines": list(skilled_birds.LINES) + ["hard_field:varied"] * 4,
            "config": dict.fromkeys(
                (
                    "card_size_caps",
                    "card_rate_limits",
                    "pass3_content",
                    "pass3_loop_guards",
                ),
                True,
            ),
            "rates": {
                "birds_homecoming_multiplier": 2,
                "birds_golden_homecoming_multiplier": 2,
            },
            "summary": {"players": [{"player_id": seat, "rounds": []} for seat in range(8)]},
        }
        return fight, lobby

    def test_away_carry_excluded_from_active_but_reported_in_sky(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "raw.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in self.fixture()))
            rows, _, _ = skilled_birds.parse_capture(path, [1], "aggressive")
        self.assertEqual(rows[0]["stats"], 31)
        self.assertEqual(rows[0]["biggest"]["stats"], 30)
        self.assertEqual(rows[0]["largest_away"]["stats"], 300)
        summary = skilled_birds.summarize(rows, 16)
        self.assertEqual(summary["missing"], 15)
        self.assertEqual(summary["largest_away"]["median_attack"], 100)

    def test_incomplete_declared_lobbies_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "raw.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in self.fixture()))
            with self.assertRaisesRegex(ValueError, "complete declared"):
                skilled_birds.parse_capture(path, [1, 2], "aggressive")

    def test_growth_pairs_keep_the_same_surviving_seats(self):
        rows = [
            {
                "phase": "pre_start_initial_auras",
                "line": "line_birds_homecoming",
                "seed": 1,
                "seat": 0,
                "round": 10,
                "stats": 10,
            },
            {
                "phase": "pre_start_initial_auras",
                "line": "line_birds_homecoming",
                "seed": 1,
                "seat": 0,
                "round": 12,
                "stats": 20,
            },
            {
                "phase": "pre_start_initial_auras",
                "line": "line_birds_homecoming",
                "seed": 2,
                "seat": 0,
                "round": 10,
                "stats": 100,
            },
        ]
        group = skilled_birds.growth_summary(rows)["pre_start_initial_auras"]["line_birds_homecoming"][0]
        self.assertAlmostEqual(group["population_median_ratio"], 20 / 55)
        self.assertEqual(group["same_survivor_pairs"], 1)
        self.assertEqual(group["median_same_survivor_ratio"], 2)
        rendered = skilled_birds.markdown(
            {
                "plan": {"n_per_arm": 32, "source_commit": "test"},
                "human_examples": [],
                "groups": {},
                "flights": {},
                "growth": {"aggressive": skilled_birds.growth_summary(rows)},
            }
        )
        self.assertIn("same-survivor", rendered.lower())
        self.assertIn("missing", rendered)

    def test_flight_denials_count_first_opportunity_only(self):
        decision = {
            "biggest_legal_slot": 0,
            "native_chosen_slot": -1,
            "carry_chosen": True,
            "flew": True,
            "candidates": [{"slot": 0, "legacy_denials": ["hard_danger_largest"]}],
        }
        flights = [
            {
                "starting_line": "line_birds_homecoming",
                "round": 12,
                "homecomings": 1,
                "decisions": [decision, decision],
            }
        ]
        group = skilled_birds.flight_summary(flights)["line_birds_homecoming"]
        self.assertEqual(group["eligible_turns"], 1)
        self.assertEqual(group["flights"], 2)
        self.assertEqual(group["carry_legacy_denials_at_first_decision"]["hard_danger_largest"], 1)


if __name__ == "__main__":
    unittest.main()
