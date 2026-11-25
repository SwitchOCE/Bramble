"""stat_growth: a unit's permanent gain per turn held, and the gain above its board-mates."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import stat_growth


def unit(u):
    if u is None:
        return None
    uid, card, golden, attack, health = u
    return {"uid": uid, "def": card, "golden": golden,
            "stats": {"perm_attack": attack, "perm_health": health} if attack or health else {}}


def board(turn, units):
    return json.dumps({"op": "fight_boards", "turn": turn,
                       "players": [{"id": 0, "board": [unit(u) for u in units]}]}) + "\n"


class StatGrowth(unittest.TestCase):
    def rows(self, lines):
        with tempfile.TemporaryDirectory() as directory:
            record = Path(directory) / "game-00000.jsonl"
            record.write_text('{"op":"start"}\n' + "".join(lines))
            return list(stat_growth.observations(record, 0))

    def test_gain_between_two_turns_and_above_board_mates(self):
        rows = self.rows([board(4, [(1, "cub", False, 2, 3), (2, "plain", False, 0, 0), None]),
                          board(5, [(1, "cub", False, 4, 6), (2, "plain", False, 1, 1), (3, "new", False, 9, 9)])])
        by = {r["card"]: r for r in rows}
        self.assertEqual(sorted(by), ["cub", "plain"])  # the new unit has no turn before
        self.assertEqual((by["cub"]["attack"], by["cub"]["health"], by["cub"]["mates"], by["cub"]["stage"]), (2, 3, 2.0, "5-8"))
        self.assertEqual((by["plain"]["attack"], by["plain"]["health"], by["plain"]["mates"]), (1, 1, 5.0))

    def test_a_unit_that_turned_golden_or_skipped_a_turn_is_not_an_observation(self):
        self.assertEqual(self.rows([board(4, [(1, "cub", False, 2, 3)]), board(5, [(1, "cub", True, 9, 9)])]), [])
        self.assertEqual(self.rows([board(4, [(1, "cub", False, 2, 3)]), board(6, [(1, "cub", False, 9, 9)])]), [])

    def test_table_needs_enough_observations_and_leaves_golden_units_out(self):
        rows = [{"game": g, "stage": "5-8", "card": "cub", "golden": False, "attack": 2, "health": 3, "mates": 1.0, "held": 20}
                for g in range(250)]
        rows += [{"game": 0, "stage": "5-8", "card": "cub", "golden": True, "attack": 50, "health": 50, "mates": 0.0, "held": 99}]
        rows += [{"game": 0, "stage": "5-8", "card": "rare", "golden": False, "attack": 9, "health": 9, "mates": 0.0, "held": 9}]
        table = {r["card"]: r for r in stat_growth.table(rows, {"cub": 1})}
        self.assertEqual((table["cub"]["n"], table["cub"]["stats_per_turn"], table["cub"]["above_mates"],
                          table["cub"]["share_growing"], table["cub"]["tier"]), (250, 5.0, 4.0, 1.0, 1))
        self.assertEqual((table["rare"]["status"], table["rare"]["stats_per_turn"]), ("too few", ""))


if __name__ == "__main__":
    unittest.main()
