"""Constructed fields preserve stat budgets, isolated mechanics and full fight inputs."""

import copy
import json
import sys
import tempfile
import unittest
from collections import Counter
from itertools import product
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from designed_setups import generate_screen, make_board, make_document
from field import load_designed

ROOT = Path(__file__).resolve().parents[2]


def units(board):
    return [unit for unit in board["board"] if unit is not None]


def total(board):
    return sum(unit["attack"] + unit["health"] for unit in units(board))


def mechanics(unit):
    for folder in ("content/units", "content/levers"):
        path = ROOT / folder / f"{unit['def_id']}.json"
        if path.exists():
            definition = json.loads(path.read_text())
            break
    else:
        raise AssertionError(f"unknown body definition {unit['def_id']}")
    entries = definition["mechanics"] + [grant.get("entry", grant) for grant in unit.get("grants", [])]
    return {entry["id"] for entry in entries}


class DesignedSetupsTests(unittest.TestCase):
    def test_every_supported_round_and_body_count_preserves_the_explicit_total(self):
        for number, target in [(6, 52), (9, 150), (12, 500), (15, 1700)]:
            for bodies in range(1, 8):
                for distribution in ("carry", "even"):
                    with self.subTest(number=number, bodies=bodies, distribution=distribution):
                        board = make_board(number, target, bodies=bodies, distribution=distribution)
                        self.assertEqual(total(board), target)
                        self.assertEqual(len(units(board)), bodies)
                        self.assertEqual(len(board["board"]), 7)
                        self.assertEqual(board["design"]["target_total"], target)
                        self.assertEqual(board["design"]["realized_total"], target)
                        self.assertTrue(all(unit["health"] >= 1 and unit["attack"] >= 0 for unit in units(board)))

    def test_concentration_changes_distribution_at_equal_budget(self):
        carry = make_board(9, 150, distribution="carry")
        even = make_board(9, 150, distribution="even")
        carry_stats = sorted(unit["attack"] + unit["health"] for unit in units(carry))
        even_stats = sorted(unit["attack"] + unit["health"] for unit in units(even))
        self.assertEqual(carry_stats, [2, 2, 2, 2, 2, 2, 138])
        self.assertLessEqual(max(even_stats) - min(even_stats), 1)
        self.assertEqual(total(carry), total(even))
        self.assertTrue(all(unit["def_id"] == "mouse" for unit in units(carry)))

    def test_answer_uses_a_body_slot_and_its_printed_six_stat_budget(self):
        plain = make_board(9, 150, distribution="carry")
        for answer, definition in [("biggest", "scale_biggest_answer"), ("percent", "scale_answer")]:
            board = make_board(9, 150, distribution="carry", answer=answer, answer_percent=35)
            answers = [unit for unit in units(board) if unit["def_id"] == definition]
            self.assertEqual(len(answers), 1)
            self.assertEqual((answers[0]["attack"], answers[0]["health"]), (3, 3))
            self.assertEqual(len(units(board)), len(units(plain)))
            self.assertEqual(total(board), total(plain))
            self.assertEqual(max(unit["attack"] + unit["health"] for unit in units(board)), 134)
            if answer == "percent":
                self.assertEqual(board["config"]["scale_answer_percent"], 35)

    def test_each_keyword_adds_only_its_actual_native_mechanic(self):
        for keyword in ("shield", "damage_reduction", "cleave"):
            for distribution, recipients in [("carry", 1), ("even", 7)]:
                with self.subTest(keyword=keyword, distribution=distribution):
                    board = make_board(12, 500, distribution=distribution, keywords=(keyword,))
                    ids = set().union(*(mechanics(unit) for unit in units(board)))
                    self.assertIn(keyword, ids)
                    self.assertFalse(({"shield", "damage_reduction", "cleave"} - {keyword}) & ids)
                    self.assertEqual(sum(keyword in mechanics(unit) for unit in units(board)), recipients)
                    self.assertEqual(total(board), 500)
        plain = make_board(12, 500)
        self.assertEqual(set().union(*(mechanics(unit) for unit in units(plain))), set())

    def test_invalid_parameters_are_rejected_before_writing_a_field(self):
        for options in [
            {"bodies": 0},
            {"bodies": 8},
            {"bodies": -1},
            {"distribution": "unknown"},
            {"keywords": ("unknown",)},
            {"answer": "unknown"},
        ]:
            with self.subTest(options=options), self.assertRaises(ValueError):
                make_board(9, 150, **options)
        for number in (0, 8, 16):
            with self.subTest(round=number), self.assertRaises(ValueError):
                make_board(number, 150)
        for budget in (-1, 0, 13):
            with self.subTest(total=budget), self.assertRaises(ValueError):
                make_board(9, budget, bodies=7)
        with self.assertRaises(ValueError):
            make_board(9, 150, bodies=1, answer="biggest")

    def test_billion_stat_limits_require_explicit_clamp_and_report_the_realized_budget(self):
        with self.assertRaises(ValueError):
            make_board(15, 2_100_000_000, bodies=1)
        board = make_board(15, 2_100_000_000, bodies=1, allow_clamp=True)
        self.assertEqual(board["design"]["target_total"], 2_100_000_000)
        self.assertEqual(board["design"]["realized_total"], 2_000_000_000)
        self.assertEqual(total(board), 2_000_000_000)
        self.assertTrue(board["design"]["clamped"])
        self.assertTrue(all(unit[key] <= 1_000_000_000 for unit in units(board) for key in ("attack", "health")))

    def test_generated_documents_are_accepted_by_the_existing_complete_input_reader(self):
        boards = [make_board(9, 150, identifier="carry"), make_board(9, 150, distribution="even", identifier="even")]
        document = make_document(boards)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "setups.json"
            path.write_text(json.dumps(document))
            loaded, weights = load_designed(path)
        self.assertEqual(len(loaded), 2)
        self.assertEqual(set(weights), {"9"})
        self.assertAlmostEqual(sum(weights["9"].values()), 1)
        self.assertTrue(all(value == 0.5 for value in weights["9"].values()))
        for board in loaded:
            self.assertEqual(board["slots"], [[] for _ in range(7)])
            self.assertEqual(board["hero_effects"], [])
            self.assertEqual(board["layout"], "blind")

    def test_explicit_config_and_inputs_are_detached(self):
        config = json.loads((ROOT / "tools/sim/evidence/designed-config.json").read_text())
        before = copy.deepcopy(config)
        first = make_board(9, 150, config=config)
        first["config"]["scale_levers"].append("sentinel")
        second = make_board(9, 150, config=config)
        self.assertEqual(config, before)
        self.assertNotIn("sentinel", second["config"]["scale_levers"])

    def test_screen_contains_every_predeclared_factor_once_and_correct_scale_totals(self):
        screen = generate_screen()
        boards = screen["boards"] if isinstance(screen, dict) else screen
        self.assertEqual(Counter(board["round"] for board in boards), {9: 32, 12: 32, 15: 32})
        self.assertEqual(len({board["id"] for board in boards}), 96)
        target_totals = {"typical": {9: 150, 12: 500, 15: 1700}, "strong": {9: 210, 12: 700, 15: 2380}}
        cells = Counter()
        for board in boards:
            design = board["design"]
            cells[
                board["round"], design["scale"], design["distribution"], tuple(design["keywords"]), design["answer"]
            ] += 1
            self.assertEqual(total(board), target_totals[design["scale"]][board["round"]])
        self.assertEqual(len(cells), 96)
        self.assertTrue(all(count == 1 for count in cells.values()))
        self.assertEqual(
            set(cells),
            set(
                product(
                    [9, 12, 15],
                    ["typical", "strong"],
                    ["carry", "even"],
                    [(), ("shield",), ("damage_reduction",), ("cleave",)],
                    ["none", "biggest"],
                )
            ),
        )
