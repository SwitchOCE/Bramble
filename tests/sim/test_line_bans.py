"""Per-line bans are source-validated and cannot admit a contaminated capture."""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
import wave1_baseline as w


class LineBansTest(unittest.TestCase):
    def test_source_schema_rejects_alias_unknown_line_unknown_card_wrong_type_and_duplicates(self):
        valid = {"line_birds_tempo": ["mr_redbreast"]}
        self.assertEqual(w.validate_banned_cards(valid), valid)
        self.assertEqual(w.validate_banned_cards({}), {})
        self.assertEqual(w.validate_banned_cards({"line_birds_tempo": []}), {"line_birds_tempo": []})
        for invalid in (
            [],
            {"birds_tempo": ["mr_redbreast"]},
            {"line_absent": ["mr_redbreast"]},
            {"line_birds_tempo": ["absent"]},
            {"line_birds_tempo": "mr_redbreast"},
            {"line_birds_tempo": ["mr_redbreast", "mr_redbreast"]},
            {"line_birds_tempo": [False]},
        ):
            with self.subTest(invalid=invalid), self.assertRaisesRegex(ValueError, "banned_cards"):
                w.validate_banned_cards(invalid)

    def test_newly_merged_lines_are_discovered_without_named_driver_cases(self):
        with tempfile.TemporaryDirectory() as folder:
            tree = Path(folder)
            (tree / "tools/sim/lines").mkdir(parents=True)
            (tree / "content/units").mkdir(parents=True)
            (tree / "tools/sim/line_profiles.committed.json").write_text("{}")
            (tree / "tools/sim/lines/new.json").write_text(json.dumps({"new_line": {"tribe": "New tribe"}}))
            (tree / "content/units/card.json").write_text(json.dumps({"id": "new_card"}))
            bans = {"line_new_line": ["new_card"]}
            self.assertEqual(w.validate_banned_cards(bans, tree), bans)

    def test_nonempty_ban_must_target_a_seated_line(self):
        w.validate_banned_roster({"line_birds_tempo": ["mr_redbreast"]})
        w.validate_banned_roster({"line_future": []})
        with self.assertRaisesRegex(ValueError, "unseated starting line: line_future"):
            w.validate_banned_roster({"line_future": ["new_card"]})
        # Future measurement rosters can use the same check after explicitly seating the line.
        w.validate_banned_roster({"line_future": ["new_card"]}, ["line_future"])

    def test_prepare_rejects_a_known_unseated_line_before_godot(self):
        with tempfile.TemporaryDirectory() as folder:
            bans_path = Path(folder) / "bans.json"
            bans_path.write_text(json.dumps({"line_hunters_engine": ["old_isegrim"]}))
            args = SimpleNamespace(
                output=Path(folder) / "output",
                source_tree=w.ROOT,
                commit=None,
                overrides=None,
                preset="shipped",
                banned_cards=bans_path,
            )
            with (
                patch.object(w, "target_tree", return_value=(w.ROOT, "f" * 40)),
                patch.object(w, "run_command") as invoke,
            ):
                with self.assertRaisesRegex(ValueError, "unseated starting line: line_hunters_engine"):
                    w.prepare(args)
                invoke.assert_not_called()

    def test_capture_reader_rejects_a_silent_unseated_ban(self):
        records, bans = self.records()
        bans["line_future"] = ["new_card"]
        with self.assertRaisesRegex(ValueError, "unseated starting line"):
            self.parse(records, bans)

    def records(self):
        bans = {"line_birds_tempo": ["mr_redbreast"]}
        audit = {
            "starting_line": "line_birds_tempo",
            "banned_cards": ["mr_redbreast"],
            "owned_banned": [],
            "played_banned": [],
            "acquired_banned": [],
            "failure": "",
        }
        names = [*w.LINES, *(["hard_field:varied"] * 4)]
        records = []
        for seat in range(0, 8, 2):
            sides = []
            for index in (seat, seat + 1):
                row = {
                    "seat": index,
                    "line": names[index].split(":")[0],
                    "king_instances": [],
                    "cutter_instances": [],
                    "other_king_raises": 0,
                    "other_cutter_gold": 0,
                    "planned_all_gold": 0,
                    "gold_next_turn_before": 0,
                    "early_spoils_gold": 0,
                    "gold_next_turn_after": 0,
                    "credited_all_gold": 0,
                    "credited_cutter_gold": 0,
                }
                if row["line"] in bans:
                    row["ban_audit"] = copy.deepcopy(audit)
                sides.append(row)
            records.append(
                {
                    "type": "peat_diagnostic",
                    "version": 1,
                    "seed": 42,
                    "round": 1,
                    "player_ids": [seat, seat + 1],
                    "sides": sides,
                }
            )
        records.append(
            {
                "type": "lobby",
                "seed": 42,
                "tribes": ["Birds", "Fairies", "Hunters", "Oozes", "Bog folk"],
                "starting_lines": names,
                "final_lines": [n.split(":")[0] for n in names],
                "banned_cards": bans,
                "players": [{"seat": seat, "place": seat + 1, "rounds": 1} for seat in range(8)],
            }
        )
        return records, bans

    def parse(self, records, bans):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "capture.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in records))
            return w.parse_chunk(path, [42], {}, with_diagnostics=True, banned_cards=bans)

    def test_all_round_audit_accepts_clean_original_starting_line(self):
        records, bans = self.records()
        boards, players, diagnostics = self.parse(records, bans)
        self.assertEqual((len(boards), len(players), len(diagnostics)), (0, 8, 8))
        self.assertEqual(diagnostics[1]["ban_audit"]["starting_line"], "line_birds_tempo")

    def test_missing_owned_played_and_forced_choice_failures_reject_whole_trial(self):
        for changed in (
            None,
            {"owned_banned": ["mr_redbreast"]},
            {"played_banned": ["mr_redbreast"]},
            {"acquired_banned": ["mr_redbreast"]},
            {"failure": "forced choice has no unbanned option"},
            {"banned_cards": []},
        ):
            records, bans = self.records()
            if changed is None:
                del records[0]["sides"][1]["ban_audit"]
            else:
                records[0]["sides"][1]["ban_audit"].update(changed)
            with self.subTest(changed=changed), self.assertRaisesRegex(ValueError, "banned-card"):
                self.parse(records, bans)

    def test_native_bypass_violation_is_rejected_even_without_owned_card(self):
        records, bans = self.records()
        records.insert(
            0, {"type": "ban_violation", "seed": 42, "seat": 1, "audit": {"failure": "banned card played then sold"}}
        )
        with self.assertRaisesRegex(ValueError, "policy violation"):
            self.parse(records, bans)
