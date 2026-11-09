"""Real designed recipes pin assumptions while the engine supplies card semantics."""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from designed_setups import real_card_recipes, real_field

ROOT = Path(__file__).resolve().parents[2]


class RealDesignedTests(unittest.TestCase):
    def test_known_recipes_cover_committed_rounds_and_two_documented_payoffs(self):
        document = real_card_recipes()
        self.assertEqual(len(document["boards"]), 8)
        lines = {(board["line"], board["round"]) for board in document["boards"]}
        self.assertEqual(
            lines,
            {(line, number) for line in ("birds_homecoming", "fairies_ring") for number in (8, 10, 12)}
            | {("granny_pot_luck", 12), ("seven_whistlers_omen", 12)},
        )
        self.assertEqual(document, json.loads((ROOT / "tests/core/data/real_designed_recipes.json").read_text()))

    def test_committed_bodies_and_reserves_are_in_the_actual_line_priority(self):
        for recipe in real_card_recipes()["boards"]:
            if "profile_priority" not in recipe:
                continue
            with self.subTest(line=recipe["line"], number=recipe["round"]):
                for unit in recipe["units"] + recipe.get("away", []):
                    self.assertIn(unit["def_id"], recipe["profile_priority"])
                    definition = json.loads((ROOT / "content/units" / (unit["def_id"] + ".json")).read_text())
                    self.assertLessEqual(definition["tier"], recipe["tier"])
                self.assertIn("No", recipe["assumptions"])

    def test_typical_ring_counts_preserve_pre_start_state_instead_of_baking_in_fetch(self):
        fairies = [board for board in real_card_recipes()["boards"] if board["line"] == "fairies_ring"]
        self.assertEqual([sum(board["rings"]) for board in fairies], [23, 33, 43])
        self.assertEqual([board["ring_size"] for board in fairies], [1, 4, 6])
        for board in fairies:
            self.assertTrue(all("stats" not in body for body in board["units"]))
        self.assertEqual(fairies[-1]["units"][1]["def_id"], "cradle_fetch")
        self.assertEqual(fairies[-1]["units"][4]["def_id"], "belladonna")

    def test_granny_keeps_bellies_and_omen_has_seven_distinct_home_birds(self):
        boards = {board["line"]: board for board in real_card_recipes()["boards"]}
        granny = boards["granny_pot_luck"]
        self.assertEqual(granny["units"][1]["def_id"], "granny_stir_up")
        self.assertEqual(sum(len(unit.get("held", [])) for unit in granny["units"]), 3)
        omen = boards["seven_whistlers_omen"]
        self.assertEqual(len({body["def_id"] for body in omen["units"]}), 7)
        self.assertIn("seven_whistlers", {body["def_id"] for body in omen["units"]})
        self.assertFalse(omen.get("away"))

    def test_profiles_are_required_and_a_drifted_priority_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(ValueError, "missing committed line"):
                real_card_recipes(directory)
            for filename in ("birds.json", "fairies.json"):
                data = json.loads((ROOT / "tools/sim/lines" / filename).read_text())
                if filename == "birds.json":
                    data["birds_homecoming"]["buy_priority"].remove("mr_redbreast")
                Path(directory, filename).write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "absent from its priority"):
                real_card_recipes(directory)

    def test_smoke_field_is_exactly_eight_boards_eight_pairs_and_128_fights(self):
        document = real_card_recipes()
        original = copy.deepcopy(document)
        field = real_field(document)
        self.assertEqual(document, original)
        self.assertEqual([len(group["boards"]) for group in field["rounds"].values()], [2, 2, 4])
        pairs = sum(len(group["boards"]) * (len(group["boards"]) - 1) // 2 for group in field["rounds"].values())
        self.assertEqual(pairs, 8)
        self.assertEqual(pairs * 8 * 2, 128)
        for group in field["rounds"].values():
            self.assertAlmostEqual(sum(group["line_weights"].values()), 1)
