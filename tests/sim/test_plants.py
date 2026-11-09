"""Real null/reference artifact checks; these tests do not launch Godot."""

import copy
import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from check_plants import check, compare_null


def card(card_id):
    return {
        "id": card_id,
        "name": "Planted test engine",
        "set": "slice",
        "tier": 1,
        "attack": 1,
        "health": 1,
        "text": "",
        "golden_text": "",
        "mechanics": [],
        "keywords": [],
        "tribes": [],
        "pool": False,
    }


def capture(card_id, policy, digest):
    return {
        "seed": 11,
        "round": 1,
        "leg": 0,
        "test_cards": [card(card_id)],
        "input": {
            "rng_state": "1234567890123456789",
            "effect_rng_state": "9123456789012345678",
            "boards": [
                [{"def_id": card_id, "iid": 101, "attack": 1, "health": 1}],
                [{"def_id": "field_vole", "iid": 201, "attack": 1, "health": 1}],
            ],
        },
        "combat_start": [{"policy": policy, "active_stats": 2}, {"policy": "hard", "active_stats": 2}],
        "after_start_effects": [{"active_stats": 2}, {"active_stats": 2}],
        "result": {"winner": -1, "damage": 0, "carry": []},
        "outcome": {"winner": -1, "damage": 0, "carry": []},
        "events_sha256": digest,
    }


class PlantChecksTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.reference = self.root / "reference"
        self.null = self.root / "null"
        self.ref_record = capture("bench_reference", "plant_reference", "a" * 64)
        self.null_record = capture("bench_null", "plant_null", "b" * 64)
        for prefix, card_id, policy in (
            (self.reference, "bench_reference", "plant_reference"),
            (self.null, "bench_null", "plant_null"),
        ):
            self.write_csv(prefix, "players", [["seed", "seat", "place", "strategy"], [11, 0, 1, policy]])
            self.write_csv(prefix, "rounds", [["seed", "round", "attack", "health"], [11, 1, 1, 1]])
            self.write_csv(prefix, "cards", [["seed", "card"], [11, card_id]])
        self.write_capture(self.reference, [self.ref_record])
        self.write_capture(self.null, [self.null_record])

    @staticmethod
    def write_csv(prefix, part, rows):
        with Path(f"{prefix}.{part}.csv").open("w", newline="") as stream:
            csv.writer(stream).writerows(rows)

    @staticmethod
    def write_capture(prefix, rows):
        Path(f"{prefix}.fights.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows))

    def comparison(self):
        return compare_null(self.reference, self.null)

    def test_real_bodies_allow_only_expected_definition_policy_and_event_hash_differences(self):
        result = self.comparison()
        self.assertTrue(result["passes"])
        self.assertTrue(all(result["null_exact"].values()))
        self.assertTrue(result["null_validation"]["null"]["present_in_fight_input"])
        # The two distinct hashes stay in their original capture files for exact refight.
        self.assertEqual(json.loads(Path(f"{self.null}.fights.jsonl").read_text())["events_sha256"], "b" * 64)

    def test_actual_outcome_start_effect_rng_or_other_hash_changes_fail(self):
        mutations = [
            lambda row: row["result"].update(winner=0),
            lambda row: row["outcome"].update(damage=1),
            lambda row: row["after_start_effects"][0].update(active_stats=4),
            lambda row: row["input"].update(rng_state="1234567890123456790"),
            lambda row: row["input"].update(effect_rng_state="9123456789012345679"),
            lambda row: row.update(other_sha256="tampered"),
            lambda row: row["result"].update(events_sha256="nested hashes are not omitted"),
        ]
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                changed = copy.deepcopy(self.null_record)
                mutate(changed)
                self.write_capture(self.null, [changed])
                self.assertFalse(self.comparison()["passes"])

    def test_csv_result_changes_are_rejected(self):
        self.write_csv(self.null, "players", [["seed", "seat", "place", "strategy"], [11, 0, 2, "plant_null"]])
        result = self.comparison()
        self.assertFalse(result["passes"])
        self.assertFalse(result["null_exact"]["players.csv"])

    def test_unrelated_identifiers_and_labels_are_not_normalized(self):
        self.null_record["combat_start"][0]["policy"] = "plant_null_changed"
        self.write_capture(self.null, [self.null_record])
        self.assertFalse(self.comparison()["passes"])

    def test_matching_empty_interventions_fail_even_if_all_outputs_agree(self):
        for record in (self.ref_record, self.null_record):
            record["test_cards"] = []
            record["input"]["boards"][0] = []
        self.write_capture(self.reference, [self.ref_record])
        self.write_capture(self.null, [self.null_record])
        result = self.comparison()
        self.assertTrue(all(result["null_exact"].values()))
        self.assertFalse(result["passes"])
        self.assertFalse(result["null_validation"]["null"]["inert_definition_in_every_record"])
        self.assertFalse(result["null_validation"]["null"]["present_in_fight_input"])

    def test_archived_definition_without_presence_in_a_real_fight_input_fails(self):
        for record in (self.ref_record, self.null_record):
            record["input"]["boards"][0] = []
        self.write_capture(self.reference, [self.ref_record])
        self.write_capture(self.null, [self.null_record])
        result = self.comparison()
        self.assertTrue(all(result["null_exact"].values()))
        self.assertFalse(result["passes"])

    def test_missing_definition_in_one_record_fails(self):
        changed = copy.deepcopy(self.null_record)
        changed["test_cards"] = []
        self.write_capture(self.null, [changed])
        self.assertFalse(self.comparison()["passes"])

    def test_matching_non_inert_or_incomplete_definitions_are_rejected(self):
        changes = (
            {"mechanics": [{"trigger": "end_of_turn", "do": {"effect": "buff", "attack": 1}}]},
            {"text": "End of Turn: grow"},
            {"attack": 2},
            {"health": 2},
            {"set": ""},
            {"tier": 2},
            {"golden_text": "grow"},
            {"keywords": ["taunt"]},
            {"tribes": ["Bird"]},
        )
        for change in changes:
            with self.subTest(change=change):
                reference = copy.deepcopy(self.ref_record)
                null = copy.deepcopy(self.null_record)
                reference["test_cards"][0].update(change)
                null["test_cards"][0].update(change)
                self.write_capture(self.reference, [reference])
                self.write_capture(self.null, [null])
                result = self.comparison()
                self.assertTrue(all(result["null_exact"].values()))
                self.assertFalse(result["passes"])

    def test_empty_truncated_or_extra_captures_fail(self):
        for rows in ([], [self.null_record, self.null_record]):
            self.write_capture(self.null, rows)
            self.assertFalse(self.comparison()["passes"])
        self.write_capture(self.reference, [])
        self.write_capture(self.null, [])
        self.assertFalse(self.comparison()["passes"])

    def test_missing_or_invalid_raw_event_hash_is_rejected(self):
        for value in (None, "", "not-an-event-hash"):
            changed = copy.deepcopy(self.null_record)
            changed["events_sha256"] = value
            self.write_capture(self.null, [changed])
            self.assertFalse(self.comparison()["passes"])

    def test_null_presence_can_be_in_an_early_input_before_card_is_sold(self):
        later_reference = copy.deepcopy(self.ref_record)
        later_null = copy.deepcopy(self.null_record)
        later_reference["input"]["boards"][0] = []
        later_null["input"]["boards"][0] = []
        self.write_capture(self.reference, [self.ref_record, later_reference])
        self.write_capture(self.null, [self.null_record, later_null])
        self.assertTrue(self.comparison()["passes"])

    def test_known_answer_gate_requires_valid_real_null_even_when_engine_dominates(self):
        broken = self.root / "broken"
        self.write_csv(broken, "players", [["seed", "seat", "place"], *[[seed, 0, 1] for seed in range(8)]])
        boards = [
            {
                "seed": seed,
                "round": 6,
                "line": "plant_engine" if seat == 0 else "hard",
                "combat_start": {"active_stats": 100 if seat == 0 else 10},
            }
            for seed in range(8)
            for seat in range(8)
        ]
        field = {"rounds": {"6": {"line_point_rates": {"plant_engine": 0.9}}}}
        with patch("check_plants.boards_from_capture", return_value=boards):
            self.assertTrue(check(self.reference, self.null, broken, field)["passes"])
            self.null_record["input"]["boards"][0] = []
            self.write_capture(self.null, [self.null_record])
            self.assertFalse(check(self.reference, self.null, broken, field)["passes"])


if __name__ == "__main__":
    unittest.main()
