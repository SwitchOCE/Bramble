"""Synthetic boundary checks for H1's roster, runtime arms and compact captures."""

import csv
import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
SIM = ROOT / "tools/sim"
if str(SIM) not in sys.path:
    sys.path.insert(0, str(SIM))
SPEC = importlib.util.spec_from_file_location("quilboar_h1_driver_tested", SIM / "quilboar_h1.py")
DRIVER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DRIVER)


def synthetic_capture(prefix, arm="B", seed=31):
    players = [
        {
            "seed": seed,
            "seat": seat,
            "bot": line + ":assigned_build",
            "strategy": "different_final_build",
            "final_tribe": DRIVER.TRIBES[line],
            "place": seat + 1,
            "rounds": 1,
            "hero": "synthetic_hero",
        }
        for seat, line in enumerate(DRIVER.LINES)
    ]
    records = []
    for first_seat in range(0, 8, 2):
        snapshots = []
        for seat in (first_seat, first_seat + 1):
            snapshots.append(
                {
                    "assigned_line": DRIVER.LINES[seat],
                    "starting_line": "different_starting_build",
                    "current_line": "different_current_build",
                    "committed": seat == 0,
                    "recruit_units": [{"def_id": "qb_turbo_hogrider", "location": "hand"}] if seat == 0 else [],
                    "units": [
                        {"def_id": "synthetic_body", "attack": 5, "health": 7, "active": True, "slot": 0},
                        {"def_id": "reserve_body", "attack": 100, "health": 100, "active": False, "slot": -1},
                    ],
                    "active_stats": 12,
                    "largest_share": 1,
                    "gold_spent_game": 3,
                    "health": 40,
                    "gem_attack_halves": 2,
                    "gem_health_halves": 2,
                }
            )
        records.append(
            {
                "seed": seed,
                "input": {
                    "config": DRIVER.config_for(arm),
                    "player_ids": [first_seat, first_seat + 1],
                    "round": 1,
                    "tiers": [1, 1],
                },
                "combat_start": snapshots,
                "after_start_effects": [
                    {"active_stats": 30, "largest_share": 1},
                    {"active_stats": 30, "largest_share": 1},
                ],
            }
        )
    write_fixture(prefix, players, records)
    return players, records


def write_fixture(prefix, players, records):
    with prefix.with_suffix(".players.csv").open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(players[0]))
        writer.writeheader()
        writer.writerows(players)
    prefix.with_suffix(".fights.jsonl").write_text("".join(json.dumps(record) + "\n" for record in records))


class QuilboarH1DriverTests(unittest.TestCase):
    def test_legacy_capture_without_post_fight_health_still_compacts(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "legacy"
            _, records = synthetic_capture(prefix)
            self.assertTrue(all("health_after" not in record for record in records))
            [game] = DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)
        self.assertEqual(len(game["rounds"]), 8)
        self.assertTrue(all(row["health_after"] is None for row in game["rounds"]))
        self.assertTrue(all(row["stats"] == 12 for row in game["rounds"]))

    def test_capture_preserves_available_post_fight_health(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "current"
            players, records = synthetic_capture(prefix)
            for record in records:
                record["health_after"] = [37, 39]
            write_fixture(prefix, players, records)
            [game] = DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)
        self.assertEqual([row["health_after"] for row in game["rounds"]], [37, 39] * 4)

    def test_compact_capture_uses_assigned_line_and_excludes_reserves(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "chunk"
            synthetic_capture(prefix)
            [game] = DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)
        self.assertEqual(game["seed"], 31)
        self.assertEqual(game["elapsed_seconds"], 2.5)
        self.assertEqual(len(game["roster"]), 8)
        self.assertEqual(len(game["rounds"]), 8)
        self.assertEqual({row["line"] for row in game["rounds"]}, set(DRIVER.LINES))
        qb = next(row for row in game["rounds"] if row["line"] == "line_quilboar_engine")
        self.assertEqual(qb["starting_line"], "different_starting_build")
        self.assertEqual(qb["current_line"], "different_current_build")
        self.assertEqual(qb["stats"], 12)
        self.assertEqual(qb["post_start_stats"], 30)
        self.assertEqual([row["id"] for row in qb["units"]], ["synthetic_body"])
        self.assertEqual(qb["commit_round"], 1)
        self.assertEqual(qb["keystone_found_round"], 1, "a keystone in hand counts as found")
        self.assertEqual(game["players"][0]["final_line"], "different_final_build")

    def test_rejects_bad_player_roster(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "chunk"
            players, records = synthetic_capture(prefix)
            players[1]["bot"] = players[0]["bot"]
            write_fixture(prefix, players, records)
            with self.assertRaisesRegex(ValueError, "roster"):
                DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)

    def test_rejects_wrong_runtime_config(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "chunk"
            players, records = synthetic_capture(prefix)
            records[0]["input"]["config"]["card_size_caps"] = True
            write_fixture(prefix, players, records)
            with self.assertRaisesRegex(ValueError, "runtime configuration: card_size_caps"):
                DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)

    def test_rejects_duplicate_real_board_capture(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "chunk"
            players, records = synthetic_capture(prefix)
            records.append(records[0])
            write_fixture(prefix, players, records)
            with self.assertRaisesRegex(ValueError, "duplicate real board"):
                DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)

    def test_rejects_missing_starting_round_and_seed_coverage(self):
        with tempfile.TemporaryDirectory() as directory:
            prefix = Path(directory) / "chunk"
            players, records = synthetic_capture(prefix)
            records.pop()
            write_fixture(prefix, players, records)
            with self.assertRaisesRegex(ValueError, "starting board"):
                DRIVER.compact_chunk(prefix, "B", 31, 1, 2.5)
            with self.assertRaisesRegex(ValueError, "seed coverage"):
                DRIVER.compact_chunk(prefix, "B", 31, 2, 2.5)

    def test_only_frozen_arm_freezes_and_uses_uncut_preset(self):
        for arm in DRIVER.ARMS:
            config = DRIVER.config_for(arm)
            self.assertEqual(config["reference_quilboar_freeze_size"], arm == "uncut_frozen")
            self.assertEqual(config["quilboar_ref_preset"], "uncut" if arm == "uncut_frozen" else arm)
            for name, value in DRIVER.BASE_CONFIG.items():
                self.assertEqual(config[name], value)
        with self.assertRaises(ValueError):
            DRIVER.config_for("unknown")

    def test_frozen_plan_declares_exact_arm_budgets_and_separate_smoke_seeds(self):
        self.assertEqual(DRIVER.ARMS, {"B": 150, "C": 150, "uncut": 100, "uncut_frozen": 100})
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "plan.json"
            with (
                patch.object(DRIVER, "seal_sources", return_value={"source": "hash"}),
                patch.object(DRIVER, "run_git", return_value="fixed_commit"),
            ):
                plan = DRIVER.plan(path, first_seed=2911001, chunk=5)
                with self.assertRaisesRegex(ValueError, "overwrite"):
                    DRIVER.plan(path)
            self.assertEqual(json.loads(path.read_text())["source_commit"], "fixed_commit")
        self.assertEqual({arm: value["lobbies"] for arm, value in plan["arms"].items()}, DRIVER.ARMS)
        self.assertEqual(sum(value["lobbies"] for value in plan["arms"].values()), 500)
        self.assertEqual(len(set(plan["smoke"].values())), 4)
        self.assertFalse(set(plan["smoke"].values()) & set(range(2911001, 2911151)))

    def test_cycle_fix_plan_selects_only_fresh_b_and_uncut_budgets(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "rerun.json"
            with (
                patch.object(DRIVER, "seal_sources", return_value={"source": "hash"}),
                patch.object(DRIVER, "run_git", return_value="cycle_fix_commit"),
            ):
                plan = DRIVER.plan(path, first_seed=2921001, arms=["B", "uncut"], revision="shop_cycles_only")
        self.assertEqual({arm: row["lobbies"] for arm, row in plan["arms"].items()}, {"B": 150, "uncut": 100})
        self.assertEqual(plan["first_seed"], 2921001)
        self.assertEqual(plan["revision"], "shop_cycles_only")
        self.assertFalse(set(range(2921001, 2921151)) & set(range(2911001, 2911151)))


if __name__ == "__main__":
    unittest.main()
