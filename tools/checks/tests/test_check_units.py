"""check_units' parameter check: thresholds can't go below 1; a data step's numbers can."""

import json
import unittest
from pathlib import Path

from tools.checks import check_units


class CheckParamTest(unittest.TestCase):
    def test_threshold_of_zero_is_refused(self) -> None:
        self.assertIsNotNone(check_units.check_param("threshold", 0))
        self.assertIsNone(check_units.check_param("threshold", 1))

    def test_script_number_of_zero_is_refused(self) -> None:
        self.assertIsNotNone(check_units.check_param("number", 0))

    def test_data_step_number_may_be_negative(self) -> None:
        step = {"effect": "rule", "query": "income", "op": "add", "value": -1}
        self.assertEqual(check_units.check_step(step, "recruit", "cast", False), [])

    def test_data_step_threshold_of_zero_is_refused(self) -> None:
        step = {"effect": "summon", "unit": "x", "count": 0}
        self.assertTrue(check_units.check_step(step, "recruit", "cast", False))


class PermanentCeilingTest(unittest.TestCase):
    def test_ceiling_accepts_positive_integers_and_rejects_bad_metadata(self) -> None:
        path = Path("content/units/alderman_dozey.json")
        unit = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(check_units.check_unit(path, unit), [])
        for bad in [0, -1, 1.5, True, "12"]:
            with self.subTest(value=bad):
                unit["permanent_buff_cap"] = bad
                self.assertTrue(check_units.check_unit(path, unit))


class MechanicTextTest(unittest.TestCase):
    def setUp(self) -> None:
        self.path = Path("content/units/mrs_posset.json")
        self.card = json.loads(self.path.read_text(encoding="utf-8"))

    def test_mixed_card_fragments_are_valid_display_metadata(self) -> None:
        self.assertEqual(check_units.check_unit(self.path, self.card), [])

    def test_missing_or_extra_fragments_fail_coverage(self) -> None:
        for fragments in ({}, {"0": self.card["mechanic_text"]["1"]}):
            with self.subTest(fragments=fragments):
                self.card["mechanic_text"] = fragments
                self.assertTrue(check_units.check_mechanic_text(self.card))

    def test_stale_mechanic_ids_or_triggers_fail(self) -> None:
        for key, value in (("id", "belly"), ("trigger", "on_sell")):
            with self.subTest(key=key):
                card = json.loads(self.path.read_text(encoding="utf-8"))
                card["mechanic_text"]["1"][key] = value
                self.assertTrue(check_units.check_mechanic_text(card))

    def test_missing_golden_rules_or_malformed_fragments_fail(self) -> None:
        for value in (None, "When sold: forbidden.", {}, {"id": "effect", "text": "Words."}):
            with self.subTest(value=value):
                self.card["mechanic_text"]["1"] = value
                self.assertTrue(check_units.check_mechanic_text(self.card))

    def test_changing_mechanic_order_requires_rebinding_fragments(self) -> None:
        self.card["mechanics"].reverse()
        self.assertTrue(check_units.check_mechanic_text(self.card))

    def test_changing_card_punctuation_does_not_change_fragment_selection(self) -> None:
        self.card["text"] = "Belly and death share one sentence; neither has standard punctuation"
        self.card["golden_text"] = self.card["text"]
        self.assertEqual(check_units.check_mechanic_text(self.card), [])


if __name__ == "__main__":
    unittest.main()


class ScaleMechanicsTest(unittest.TestCase):
    def test_proportional_variants_replace_flat_parameters(self) -> None:
        variants = [
            {"id": "bitter", "percent": 25, "once_per_enemy": True},
            {"id": "hex", "percent": 25},
            {"id": "jenny", "percent": 25},
            {"id": "jack_daw", "percent": 25},
            {"id": "damage_reduction", "percent": 0},
            {"id": "damage_reduction", "n": 2},
        ]
        for variant in variants:
            with self.subTest(variant=variant):
                self.assertEqual(check_units.check_mechanic(variant), [])
        self.assertTrue(check_units.check_mechanic({"id": "damage_reduction"}))
        self.assertTrue(check_units.check_mechanic({"id": "jenny"}))
        self.assertTrue(check_units.check_mechanic({"id": "jenny", "percent": -1}))

    def test_fraction_data_rejects_invalid_ratios_and_modes(self) -> None:
        step = {"effect": "stat_fraction", "numerator": 0, "denominator": 2}
        self.assertEqual(check_units.check_step(step, "combat", "start_of_combat", False), [])
        for key, value in [("numerator", -1), ("denominator", 0), ("stat", "gold"), ("operation", "halve")]:
            with self.subTest(key=key):
                bad = {**step, key: value}
                self.assertTrue(check_units.check_step(bad, "combat", "start_of_combat", False))

    def test_all_row_selectors_are_available_to_combat_effects(self) -> None:
        for selector in ["biggest_enemy", "highest_attack_enemy", "highest_health_enemy"]:
            step = {"effect": "damage", "amount": 1, "target": {"select": selector}}
            self.assertEqual(check_units.check_step(step, "combat", "start_of_combat", False), [])
            self.assertTrue(check_units.check_step(step, "recruit", "cast", False))
