from __future__ import annotations

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
import wave1_baseline as w


def source(def_id, side, uid, **values):
    row = {
        "uid": uid,
        "iid": uid,
        "def_id": def_id,
        "owner_side": side,
        "golden": False,
        "starting_board": True,
        "eligible": True,
        "factor": 1,
        "copied": False,
        "raises": 0,
        "raises_for_opponent": 0,
        "gold": 0,
    }
    row.update(values)
    return row


def fixture():
    roster = [*w.LINES, *(["hard_field:varied"] * 4)]
    records = []
    for number in (1, 2):
        for a in range(0, 8, 2):
            sides = []
            for _side, seat in enumerate((a, a + 1)):
                sides.append(
                    {
                        "seat": seat,
                        "line": roster[seat].split(":")[0],
                        "king_instances": [],
                        "cutter_instances": [],
                        "other_king_raises": 0,
                        "other_cutter_gold": 0,
                        "planned_all_gold": 0,
                        "gold_next_turn_before": 3,
                        "early_spoils_gold": 0,
                        "gold_next_turn_after": 3,
                        "credited_all_gold": 0,
                        "credited_cutter_gold": 0,
                    }
                )
            if a == 0:
                sides[0]["king_instances"] = [source("peat_king", 0, 10)]
                sides[1]["cutter_instances"] = [source("peat_cutter", 1, 20, golden=True, factor=2)]
                if number == 2:
                    sides[0]["king_instances"][0]["raises"] = 2
                    sides[0]["king_instances"].append(source("peat_king", 0, 11, golden=True, factor=2, raises=1))
                    sides[1].update(
                        planned_all_gold=7,
                        credited_all_gold=7,
                        credited_cutter_gold=2,
                        other_cutter_gold=1,
                        early_spoils_gold=1,
                        gold_next_turn_after=11,
                    )
                    sides[1]["cutter_instances"][0]["gold"] = 2
            records.append(
                {
                    "type": "peat_diagnostic",
                    "version": 1,
                    "seed": 42,
                    "round": number,
                    "player_ids": [a, a + 1],
                    "sides": sides,
                }
            )
    records.append(
        {
            "type": "lobby",
            "seed": 42,
            "tribes": ["Birds", "Fairies", "Bog folk", "Plants", "Hunters"],
            "starting_lines": roster,
            "final_lines": [n.split(":")[0] for n in roster],
            "players": [{"seat": i, "place": i + 1, "rounds": 2} for i in range(8)],
        }
    )
    return records


class PeatReaderTest(unittest.TestCase):
    def parse(self, records):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "capture.jsonl"
            path.write_text("\n".join(json.dumps(r) for r in records))
            return w.parse_chunk(path, [42], {}, with_diagnostics=True)

    def test_all_rounds_zero_positive_exact_denominators(self):
        boards, players, rows = self.parse(fixture())
        self.assertEqual((len(boards), len(players), len(rows)), (0, 8, 16))
        result = w.peat_measurements(rows)
        self.assertEqual(set(result["rounds"]), {"1", "2"})
        one = result["rounds"]["1"]
        self.assertEqual(one["peat_king"]["card_present_fights"], 1)
        self.assertEqual(one["peat_king"]["zero_output_card_present_fights"], 1)
        self.assertEqual(one["peat_king"]["output_per_card_present_fight"], 0)
        two = result["rounds"]["2"]
        self.assertEqual(two["peat_king"]["eligible_instances"], 2)
        self.assertEqual(two["peat_king"]["golden_instances"], 1)
        self.assertEqual(two["peat_king"]["output_total"], 3)
        self.assertEqual(two["peat_king"]["output_per_card_present_fight"], 3)
        self.assertEqual(two["peat_king"]["output_per_eligible_instance_fight"], 1.5)
        cutter = result["all_rounds"]["peat_cutter"]
        self.assertEqual(cutter["card_present_fights"], 2)
        self.assertEqual(cutter["zero_output_card_present_fights"], 1)
        self.assertEqual(cutter["output_total"], 2)
        self.assertEqual(cutter["output_per_card_present_fight"], 1)
        self.assertEqual(result["all_rounds"]["all_sources_credited_next_turn_gold"], 7)
        self.assertEqual(result["all_rounds"]["other_body_cutter_ability_gold"], 1)
        self.assertIsNone(one["peat_king"].get("unrequested_threshold"))

    def test_entered_only_card_present_scope(self):
        records = fixture()
        records[0]["sides"][0]["king_instances"][0]["starting_board"] = False
        _, _, rows = self.parse(records)
        result = w.peat_measurements(rows)["rounds"]["1"]["peat_king"]
        self.assertEqual(result["card_present_fights"], 1)
        self.assertEqual(result["starting_board_present_fights"], 0)
        self.assertEqual(result["entered_only_card_present_fights"], 1)
        self.assertEqual(result["entered_during_combat_instances"], 1)
        self.assertEqual(result["output_per_card_present_fight"], 0)

    def test_real_seat_ghost_opponent_only_once(self):
        records = fixture()
        record = copy.deepcopy(records[0])
        record["player_ids"][1] = -1
        record["sides"][1]["seat"] = -1
        rows = w.parse_peat_diagnostic(record)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["seat"], 0)
        self.assertTrue(rows[0]["ghost_opponent"])
        result = w.peat_measurements(rows)["all_rounds"]
        self.assertEqual(result["real_seat_fights"], 1)
        self.assertEqual(result["ghost_opponent_fights"], 1)
        self.assertEqual(result["peat_king"]["card_present_fights"], 1)

    def test_missing_early_round_rejected(self):
        records = fixture()
        records.pop(0)
        with self.assertRaisesRegex(ValueError, "all-round peat"):
            self.parse(records)

    def test_duplicate_rejected(self):
        records = fixture()
        records.insert(0, copy.deepcopy(records[0]))
        with self.assertRaisesRegex(ValueError, "duplicate peat"):
            self.parse(records)

    def test_planned_credit_mismatch_rejected(self):
        records = fixture()
        records[4]["sides"][1]["credited_all_gold"] = 6
        with self.assertRaisesRegex(ValueError, "gold did not reconcile"):
            self.parse(records)

    def test_wrong_native_source_rejected(self):
        records = fixture()
        records[0]["sides"][0]["king_instances"][0]["def_id"] = "peatling"
        with self.assertRaisesRegex(ValueError, "source attribution"):
            self.parse(records)

    def test_markdown_round_tables(self):
        _, _, rows = self.parse(fixture())
        result = {
            "preset": "B",
            "population": "fixture",
            "pairing": "fixture",
            "lobbies": 1,
            "source_commit": "d5b5b4f8",
            "chunk_wall_seconds": 0,
            "growth": {},
            "lines": {},
            "survival": "survival",
            "starting_labels": "labels",
            "report_only": {"peat": w.peat_measurements(rows)},
        }
        report = w.markdown(result)
        self.assertIn("Peat King by round (report only)", report)
        self.assertIn("Peat Cutter by round (report only)", report)
        self.assertIn("| 1 | 1 | 1 | 1 | 0 | 0 | 0.000 | 0.000 |", report)
        self.assertIn("| 2 | 1 | 0 | 2 | 1 | 3 | 3.000 | 1.500 |", report)
        self.assertIn("actual credited next-turn gold", report)


if __name__ == "__main__":
    unittest.main()
