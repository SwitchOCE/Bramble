"""The opt-in content is validated without expanding the release card namespace."""

import copy
import json
import unittest
from pathlib import Path

from tools.checks import check_units

ROOT = Path("content/reference/quilboar")


def read(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


class QuilboarContentTest(unittest.TestCase):
    def test_reference_content_is_checked_by_the_default_gate(self) -> None:
        self.assertEqual(check_units.check_reference(), [])

    def test_reference_tribe_and_modes_do_not_become_release_unit_fields(self) -> None:
        card = read("units/qb_crater_miner.json")
        self.assertEqual(check_units.check_unit(ROOT / "units/qb_crater_miner.json", card), [])
        problems = check_units.check_unit(Path("content/units/qb_crater_miner.json"), card)
        self.assertTrue(any("unknown field 'modes'" in problem for problem in problems))
        ordinary = json.loads(Path("content/units/cricket_busker.json").read_text(encoding="utf-8"))
        ordinary["tribes"] = ["quilboar"]
        self.assertTrue(check_units.check_unit(Path("content/units/cricket_busker.json"), ordinary))

    def test_reference_namespace_cannot_be_copied_into_release_pools(self) -> None:
        card = read("units/qb_gem_rat.json")
        card["tribes"] = []
        self.assertTrue(check_units.check_unit(Path("content/units/qb_gem_rat.json"), card))
        spell = read("spells/qb_blood_gem.json")
        self.assertTrue(check_units.check_card(Path("content/spells/qb_blood_gem.json"), spell))

    def test_choose_one_needs_valid_modes_not_an_empty_cast(self) -> None:
        card = read("spells/qb_gem_day.json")
        path = ROOT / "spells/qb_gem_day.json"
        self.assertEqual(check_units.check_card(path, card), [])
        for modes in ([], [card["modes"][0]], [{"name": "Oops"}, {}]):
            invalid = copy.deepcopy(card)
            invalid["modes"] = modes
            self.assertTrue(check_units.check_card(path, invalid))
        del card["modes"]
        self.assertTrue(check_units.check_card(path, card))

    def test_bad_mode_steps_and_unknown_nested_fields_fail(self) -> None:
        card = read("units/qb_fearless_foodie.json")
        for key, value in (("effects", [{"effect": "not_a_real_effect"}]), ("efffects", [])):
            invalid = copy.deepcopy(card)
            invalid["modes"][0][key] = value
            self.assertTrue(check_units.check_modes(invalid))
        card["modes"][0]["effects"][0]["attack"] = 0.5
        self.assertTrue(check_units.check_modes(card), "half-unit storage must remain integer")

    def test_random_creation_filter_is_checked(self) -> None:
        good = {"effect": "add_card", "random": {"tag": "choose_one", "tier_at_most": "tier"}, "count": 1}
        self.assertEqual(check_units.check_step(good, "recruit", "cast", False), [])
        for random in ({}, {"tags": "choose_one"}, {"tag": "choose_one", "tier_at_most": True}, {"tribe": "Quilboars"}):
            bad = {**good, "random": random}
            self.assertTrue(check_units.check_step(bad, "recruit", "cast", False))

    def test_spell_exemption_and_reference_native_kind_are_required(self) -> None:
        card = read("spells/qb_blood_gem.json")
        card["scaling_exempt"] = False
        self.assertTrue(check_units.check_card(ROOT / "spells/qb_blood_gem.json", card))
        unit = read("units/qb_gem_rat.json")
        unit["mechanics"][0]["kind"] = "turbo_hogrider"
        self.assertTrue(check_units.check_unit(ROOT / "units/qb_gem_rat.json", unit))
