"""Shared frozen-plan and evidence-analysis checks; these never launch Godot."""

import copy
import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from lever_sweep import (
    ROUNDS,
    SweepError,
    adoption_report,
    damage_report,
    digest,
    file_sha,
    run_command,
    source_manifest,
    stage_plan,
    validate_capture,
    validate_plan,
    validate_players,
)


class RuntimeLogTests(unittest.TestCase):
    def test_script_errors_with_success_exit_reject_the_run(self):
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "godot.log"
            with self.assertRaisesRegex(SweepError, "despite exit zero"):
                run_command([sys.executable, "-c", "print('SCRIPT ERROR: missing cap')"], log, 5)
            run_command([sys.executable, "-c", "print('clean run')"], log, 5)


def configuration(name="caps"):
    return {
        "id": name,
        "overrides": {"card_size_caps": False},
        "first_seed": 1001,
        "lobbies": 150,
        "field_size": 32,
        "rounds": ROUNDS,
        "reps": 8,
    }


def player_rows(first_seed=1001, count=2, head=False):
    result = []
    for seed in range(first_seed, first_seed + count):
        for leg in range(2 if head else 1):
            for seat in range(8):
                result.append(
                    {
                        "seed": seed,
                        "leg": leg,
                        "seat": seat,
                        "place": seat + 1,
                        "rounds": 2,
                        "side": "candidate" if (seat < 4) == (leg == 0) else "incumbent",
                        "candidate": "line_hedgerow_tempo",
                        "incumbent": "hard_field",
                    }
                )
    return result


def write_csv(path, rows):
    with path.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def capture_rows(seed=1001):
    result = []
    for pair in ([0, 1], [2, 3], [4, 5], [6, 7]):
        result.append(
            {
                "seed": seed,
                "leg": 0,
                "round": 1,
                "players": pair,
                "alive_before": 8,
                "health_after": [10, 10] if pair == [0, 1] else [0, 0],
                "test_cards": [],
            }
        )
    result.append(
        {
            "seed": seed,
            "leg": 0,
            "round": 2,
            "players": [0, 1],
            "alive_before": 2,
            "health_after": [10, 0],
            "test_cards": [],
        }
    )
    return result


class LeverSweepTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for directory in ("src", "content/units", "tools/sim"):
            (self.root / directory).mkdir(parents=True)
        (self.root / "src/mechanic.gd").write_text("original\n")
        (self.root / "tools/sim/bench.gd").write_text("original bench\n")
        (self.root / "content/units/card.json").write_text('{"id":"card"}\n')
        (self.root / "profiles.json").write_text('{"line_hedgerow_tempo":{"tribe":"Hedgerow folk"}}\n')
        self.plan = {
            "version": 1,
            "output_root": "build/sweep",
            "report": "docs/evidence.md",
            "configs": [configuration()],
            "source_commit": "a" * 40,
            "source_paths": ["src", "content", "tools/sim/*.gd", "profiles.json"],
            "source_fingerprint": digest(
                source_manifest(self.root, ["src", "content", "tools/sim/*.gd", "profiles.json"])
            ),
            "profiles": "profiles.json",
            "profiles_sha256": file_sha(self.root / "profiles.json"),
        }

    def capture(self, rows):
        path = self.root / "capture.jsonl"
        path.write_text("".join(json.dumps(row) + "\n" for row in rows))
        return path

    def test_fixed_lobby_field_and_swapped_head_budgets(self):
        head = {
            "candidate": "line_hedgerow_tempo",
            "incumbent": "hard_field",
            "independent_seeds": 80,
            "first_seed": 9001,
            "chunk_seeds": 20,
        }
        self.plan["configs"][0]["head_to_head"] = head
        stages = stage_plan(validate_plan(self.plan))
        lobby = [stage for stage in stages if stage["kind"] == "lobbies"]
        self.assertEqual(
            [(stage["first_seed"], stage["count"]) for stage in lobby], [(1001, 50), (1051, 50), (1101, 50)]
        )
        fields = [stage for stage in stages if stage["kind"] == "field"]
        self.assertEqual([stage["round"] for stage in fields], ROUNDS)
        comparisons = [stage for stage in stages if stage["kind"] == "head"]
        self.assertEqual(sum(stage["count"] for stage in comparisons), 80)
        for key, value in (("independent_seeds", 81), ("chunk_seeds", 40), ("incumbent", "hard")):
            altered = copy.deepcopy(self.plan)
            altered["configs"][0]["head_to_head"][key] = value
            with self.assertRaises(SweepError):
                validate_plan(altered)
        for key, value in (("lobbies", 151), ("reps", 16), ("rounds", [8]), ("field_size", 16)):
            altered = copy.deepcopy(self.plan)
            altered["configs"][0][key] = value
            with self.assertRaises(SweepError):
                validate_plan(altered)

    def test_duplicate_and_missing_seeded_players_are_rejected(self):
        rows = player_rows()
        path = self.root / "players.csv"
        write_csv(path, rows)
        self.assertEqual(len(validate_players(path, 1001, 2)), 16)
        for broken in (rows[:-1], [*rows, rows[0]], rows[8:]):
            write_csv(path, broken)
            with self.assertRaises(SweepError):
                validate_players(path, 1001, 2)

    def test_null_head_result_is_a_completed_scientific_finding(self):
        path = self.root / "players.csv"
        rows = player_rows(head=True)
        write_csv(path, rows)
        result = validate_players(path, 1001, 2, True, "line_hedgerow_tempo", "hard_field")
        self.assertFalse(result["passes"])
        self.assertEqual(result["independent_seeds"], 2)
        self.assertEqual(result["mean_place_gain"], 0)
        write_csv(path, rows[:-1])
        with self.assertRaises(SweepError):
            validate_players(path, 1001, 2, True, "line_hedgerow_tempo", "hard_field")

    def test_incomplete_or_duplicate_captures_never_count_as_finished(self):
        rows = [*capture_rows(), *capture_rows(1002)]
        validate_capture(self.capture(rows), 1001, 2)
        for broken in (rows[:-1], [*rows, rows[0]], rows[5:], rows[:3] + rows[4:]):
            with self.assertRaises(SweepError):
                validate_capture(self.capture(broken), 1001, 2)
        # A complete round at the end is still partial if two living seats remain.
        with self.assertRaises(SweepError):
            validate_capture(self.capture(capture_rows()[:-1]), 1001, 1)

    def test_planted_cards_require_exact_explicit_test_allowlist(self):
        definition = {"id": "bench_engine_4", "attack": 1, "health": 1, "pool": True}
        rows = [*capture_rows(), *capture_rows(1002)]
        for row in rows:
            row["test_cards"] = [copy.deepcopy(definition)]
        path = self.capture(rows)
        with self.assertRaises(SweepError):
            validate_capture(path, 1001, 2)
        validate_capture(path, 1001, 2, expected_test_cards=[definition])
        rows[-1]["test_cards"][0]["attack"] = 2
        with self.assertRaises(SweepError):
            validate_capture(self.capture(rows), 1001, 2, expected_test_cards=[definition])

    def test_offline_unresolved_games_do_not_receive_lengths(self):
        config = {"damage_mode": "v05", "starting_health": 10, "base_damage_by_turn": [0, 8], "last_stand": False}
        rows = []
        for number, health, after in ((1, 10, 8), (2, 8, -2)):
            rows.append(
                {
                    "seed": 1,
                    "leg": 0,
                    "round": number,
                    "players": [0, 1],
                    "alive_before": 2,
                    "input": {"config": config, "tiers": [1, 1]},
                    "outcome": {"winner": 0, "damage": 2 if number == 1 else 10, "last_blow": False},
                    "combat_start": [
                        {"health": 10, "armor": 0, "last_stand_used": False},
                        {"health": health, "armor": 0, "last_stand_used": False},
                    ],
                    "health_after": [10, after],
                    "armor_after": [0, 0],
                    "survivor_units": [[{"own_starting_body": True, "health": 1}] * 2, []],
                }
            )
        captures = [self.capture(rows)]
        players = [{"seed": 1, "leg": 0, "seat": 0, "place": 1, "rounds": 2}]
        report = damage_report(
            captures, players, {"slower": {"starting_health": 20}, "earlier": {"starting_health": 1}}
        )
        original = report["variants"]["original"]["summary"]
        self.assertTrue(original["original_validated"])
        self.assertEqual(original["live_post_state_checks"], 4)
        self.assertEqual(original["covered_resolved_end_round"]["p50"], 2)
        unresolved = report["variants"]["slower"]["summary"]
        self.assertEqual(unresolved["unresolved_games"], 1)
        self.assertEqual(unresolved["covered_resolved_end_round"]["n"], 0)
        conditional = report["variants"]["earlier"]["summary"]
        self.assertEqual(conditional["elimination_divergence_games"], 1)
        self.assertEqual(conditional["unchanged_elimination_end_round"]["n"], 0)
        self.assertEqual(conditional["covered_resolved_end_round"]["p50"], 1)

    def test_adoption_distinguishes_real_active_reserves_and_unused_ids(self):
        snapshot = {
            "layout": "blind",
            "policy": "hard",
            "units": [
                {"def_id": "scale_engine", "active": True},
                {"def_id": "scale_economy", "active": False, "location": "hand"},
            ],
        }
        record = {
            "seed": 1,
            "leg": 0,
            "combat_start": [snapshot, snapshot],
            "input": {
                "player_ids": [0, -1],
                "round": 8,
                "boards": [[], []],
                "slots": [[], []],
                "fight_rules": [{}, {}],
                "hero_effects": [[], []],
                "tiers": [4, 4],
                "config": {},
            },
        }
        cards = self.root / "cards.csv"
        write_csv(cards, [{"card": "scale_engine"}])
        result = adoption_report([self.capture([record])], [cards], ["scale_engine", "scale_economy", "scale_doubler"])
        self.assertEqual(result["board_rounds"], 1)
        self.assertEqual(result["levers"]["scale_engine"]["active_board_rounds"], 1)
        self.assertEqual(result["levers"]["scale_engine"]["final_card_rows"], 1)
        self.assertEqual(result["levers"]["scale_economy"]["active_board_rounds"], 0)
        self.assertEqual(result["levers"]["scale_economy"]["owned_seats"], 1)
        self.assertTrue(result["levers"]["scale_doubler"]["observed_unused"])
        self.assertIsNone(result["levers"]["scale_engine"]["bought_unique"])
        self.assertIsNone(result["levers"]["scale_engine"]["created_unique"])
        self.assertEqual(result["legacy_unknown_origin_board_rounds"], 1)

    def test_inventory_deduplicates_acquisitions_and_measures_next_round_iid_retention(self):
        rows = []
        inventories = [
            [
                {"iid": 1, "def_id": "scale_engine", "origin": "bought", "location": "board"},
                {"iid": 1, "def_id": "scale_engine", "origin": "bought", "location": "board"},
                {"iid": 2, "def_id": "scale_engine", "origin": "created", "location": "hand"},
            ],
            [
                {"iid": 1, "def_id": "scale_engine", "origin": "bought", "location": "hand"},
                {"iid": 3, "def_id": "scale_engine", "origin": "bought", "location": "board"},
            ],
            [
                {"iid": 1, "def_id": "scale_engine", "origin": "bought", "location": "hand"},
                {"iid": 3, "def_id": "scale_engine", "origin": "bought", "location": "board"},
            ],
        ]
        for number, inventory in enumerate(inventories, 8):
            # Repeated presentation views and IID entries are not extra acquisitions.
            view = {"def_id": "scale_engine", "active": True, "slot": 0}
            snapshot = {"layout": "blind", "policy": "hard", "units": [view, view], "recruit_units": inventory}
            rows.append(
                {
                    "seed": 1,
                    "leg": 0,
                    "combat_start": [snapshot, snapshot],
                    "input": {
                        "player_ids": [0, -1],
                        "round": number,
                        "boards": [[], []],
                        "slots": [[], []],
                        "fight_rules": [{}, {}],
                        "hero_effects": [[], []],
                        "tiers": [4, 4],
                        "config": {},
                    },
                }
            )
        report = adoption_report([self.capture(rows)], [], ["scale_engine"])
        value = report["levers"]["scale_engine"]
        self.assertEqual(report["inventory_board_rounds"], 3)
        self.assertEqual(value["acquired_unique_iids"], 3)
        self.assertEqual(value["bought_unique"], 2)
        self.assertEqual(value["created_unique"], 1)
        self.assertEqual(value["unknown_origin_unique"], 0)
        self.assertEqual(value["active_copies"], 3)
        self.assertEqual(value["owned_copies"], 6)
        self.assertEqual(
            value["retention_same_iid_next_own_round"],
            {
                "eligible": 4,
                "retained": 3,
                "censored": 2,
                "rate": 0.75,
            },
        )


if __name__ == "__main__":
    unittest.main()
