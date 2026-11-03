"""Tests for tools/checks/check_scenarios.py: the shipped scenarios pass and bad entries are caught."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.checks import check_scenarios

UNITS = {"elder_ooze", "belladonna_sprite"}


def scenario(**changes: object) -> dict:
    data = {
        "id": "demo",
        "title": "Demo",
        "entry": 75,
        "units": ["belladonna_sprite"],
        "watch": "Something happens.",
        "boards": {"mine": {"B1": {"def_id": "belladonna_sprite"}}, "theirs": {"F1": {"def_id": "elder_ooze"}}},
    }
    data.update(changes)
    return data


class CheckScenariosTest(unittest.TestCase):
    def test_shipped_scenarios_pass(self) -> None:
        self.assertEqual(check_scenarios.main(["check_scenarios"]), 0)

    def test_valid_scenario_has_no_problems(self) -> None:
        self.assertEqual(check_scenarios.check_scenario(Path("demo.json"), scenario(), UNITS), [])

    def test_bad_entries_are_caught(self) -> None:
        bad_board = {"mine": {"F9": {"def_id": "nope", "health": 0, "colour": "red"}}, "theirs": {}}
        problems = check_scenarios.check_scenario(Path("demo.json"), scenario(boards=bad_board), UNITS)
        text = "\n".join(problems)
        for fragment in ("unknown slot F9", "unknown unit nope", "health must be", "unknown key colour", "theirs"):
            self.assertIn(fragment, text)

    def test_id_must_match_file(self) -> None:
        problems = check_scenarios.check_scenario(Path("other.json"), scenario(), UNITS)
        self.assertIn("id doesn't match", "\n".join(problems))


if __name__ == "__main__":
    unittest.main()
