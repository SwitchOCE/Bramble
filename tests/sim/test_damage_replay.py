import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from replay_damage import damage, replay_game


def records():
    config = {
        "damage_mode": "v05",
        "base_damage_by_turn": [0, 0, 8],
        "starting_health": 10,
        "last_stand": True,
        "hero_damage_floor": 4,
        "survivor_damage_divisor": 2,
        "round_toll": False,
        "damage_cap_by_turn": [5],
        "damage_cap_off_at_alive": 4,
    }
    result = []
    for number, (pre, armor, used, post, post_armor, count) in enumerate(
        [(10, 2, False, 10, 0, 2), (10, 0, False, 7, 0, 3), (7, 0, False, 1, 0, 2), (1, 0, True, -9, 0, 2)], 1
    ):
        result.append(
            {
                "seed": 1,
                "leg": 0,
                "round": number,
                "players": [0, 1],
                "alive_before": 2,
                "input": {"config": config, "tiers": [4, 4]},
                "outcome": {"winner": 0, "damage": [2, 3, 10, 10][number - 1], "last_blow": False},
                "combat_start": [
                    {"health": 10, "armor": 2, "last_stand_used": False},
                    {"health": pre, "armor": armor, "last_stand_used": used},
                ],
                "health_after": [10, post],
                "armor_after": [2, post_armor],
                "survivor_units": [[{"own_starting_body": True, "health": 1, "tier": 6, "def_id": "body"}] * count, []],
            }
        )
    return result


class ReplayTests(unittest.TestCase):
    def test_original_health_armor_last_stand_and_elimination_match(self):
        result = replay_game(records(), {})
        self.assertEqual(result["end_round"], 4)
        self.assertEqual(result["winner"], 0)
        self.assertEqual(result["rounds"][2]["players"]["1"]["health"], 1)
        self.assertTrue(result["rounds"][2]["players"]["1"]["used"])
        self.assertEqual(result["live_post_state_checks"], 8)
        self.assertIsNone(result["first_elimination_divergence"])

    def test_health_variants_and_slower_tables_need_no_new_fights(self):
        early = replay_game(records(), {"starting_health": 3, "last_stand": False})
        self.assertEqual(early["end_round"], 2)
        self.assertEqual(early["first_elimination_divergence"], 2)
        slow = replay_game(records(), {"base_damage_by_turn": [0], "survivor_scale": 0})
        self.assertIsNone(slow["end_round"])
        self.assertEqual(slow["unresolved_survivors"], [0, 1])

    def test_legacy_survivor_tiers_caps_and_toll(self):
        row = copy.deepcopy(records()[0])
        row["input"]["config"].update(damage_mode="legacy", round_toll=True)
        row["survivor_units"][0] = [{"tier": 6, "def_id": "body"}, {"tier": 1, "def_id": "nest_egg"}]
        self.assertEqual(damage(row, {}, 5), 5)
        self.assertEqual(damage(row, {}, 4), 8)
        self.assertEqual(damage(row, {"tier_damage_by_tier": {"6": 2}}, 4), 6)

    def test_duplicate_or_corrupt_rounds_are_rejected(self):
        rows = records()
        with self.assertRaises(ValueError):
            replay_game([rows[0], *rows], {})
        rows[0]["health_after"][1] = 999
        with self.assertRaises(ValueError):
            replay_game(rows, {})
