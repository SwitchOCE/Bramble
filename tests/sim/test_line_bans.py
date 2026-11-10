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
import test_wave1_baseline as baseline
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
            bans_path.write_text(json.dumps({"line_hunters_pack": ["old_isegrim"]}))
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
                with self.assertRaisesRegex(ValueError, "unseated starting line: line_hunters_pack"):
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

    def test_missing_or_mismatched_audits_remain_integrity_errors(self):
        for changed in (
            None,
            {"banned_cards": []},
        ):
            records, bans = self.records()
            if changed is None:
                del records[0]["sides"][1]["ban_audit"]
            else:
                records[0]["sides"][1]["ban_audit"].update(changed)
            with self.subTest(changed=changed), self.assertRaisesRegex(ValueError, "banned-card"):
                self.parse(records, bans)

    def test_audit_contamination_drops_whole_trial(self):
        for changed in (
            {"owned_banned": ["mr_redbreast"]},
            {"played_banned": ["mr_redbreast"]},
            {"acquired_banned": ["mr_redbreast"]},
            {"failure": "forced choice has no unbanned option"},
        ):
            records, bans = self.records()
            records[0]["sides"][1]["ban_audit"].update(changed)
            with self.subTest(changed=changed):
                self.assertEqual(self.parse(records, bans), ([], [], []))

    def test_native_bypass_violation_drops_even_earlier_rows_without_owned_card(self):
        records, bans = self.records()
        records.insert(
            0, {"type": "ban_violation", "seed": 42, "seat": 1, "audit": {"failure": "banned card played then sold"}}
        )
        self.assertEqual(self.parse(records, bans), ([], [], []))


class ContaminatedRunTest(unittest.TestCase):
    def test_late_violation_removes_earlier_boards_from_medians_and_growth(self):
        records, config = baseline.BaselineTests().records()
        contaminated = copy.deepcopy(records)
        for row in contaminated:
            row["seed"] = 2
            for snapshot in row.get("combat_start", []):
                snapshot["active_stats"] = 1e12
        records += [*contaminated, {"type": "ban_violation", "seed": 2, "audit": {"failure": "forced"}}]
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "capture.jsonl"
            path.write_text("".join(json.dumps(row) + "\n" for row in records))
            boards, players, dropped = w.parse_chunk(path, [1, 2], config, with_drops=True)
        self.assertEqual(dropped, [2])
        self.assertEqual(len(boards), 32)
        self.assertEqual(len(players), 8)
        plan = {"seeds": [1], "bootstrap_replicates": 8, "bootstrap_seed": 77}
        result = w.analyze(boards, players, plan)
        self.assertEqual(result["lines"][w.LINES[0]]["median"], 100)
        self.assertEqual(result["growth"]["all_seats"]["point"], 1)
        self.assertEqual(result["report_only"]["r14_alive_all_seats_share"], 1)

    def test_run_threshold_is_attempted_trials_across_chunks_and_reports_failures(self):
        # A 1/10 first chunk must not abort a run that ends at 1/100.
        for count in (1, 2, 3):
            with self.subTest(dropped=count), tempfile.TemporaryDirectory() as folder:
                out = Path(folder)
                records, bans = LineBansTest().records()
                plan = {
                    "output": folder,
                    "runtime_tree": str(w.ROOT),
                    "banned_cards": bans,
                    "seeds": list(range(100)),
                    "chunk": 10,
                    "overrides": {},
                    "config": {},
                    "source_sha256": {},
                    "driver_sha256": w.file_sha(Path(w.__file__)),
                    "bootstrap_replicates": 8,
                    "bootstrap_seed": 77,
                    "source_commit": "test",
                    "preset": "test",
                    "rates": {},
                    "population": "test",
                    "pairing": "test",
                    "excluded_seeds": [],
                }
                plan_path = out / "plan.json"
                w.atomic_json(plan_path, plan)

                def simulate(command, log, timeout, target, records=records, count=count):
                    invocation = w.read_json(Path(command[-2]))
                    rows = []
                    for seed in invocation["seeds"]:
                        trial = copy.deepcopy(records)
                        for row in trial:
                            row["seed"] = seed
                        if seed < count:
                            # Leave partial earlier observations, then emit the terminal violation.
                            trial = [
                                *trial[:1],
                                {"type": "ban_violation", "seed": seed, "audit": {"failure": "forced"}},
                            ]
                        rows.extend(trial)
                    Path(command[-1]).write_text("".join(json.dumps(row) + "\n" for row in rows))

                with (
                    patch.object(w, "source_manifest", return_value={}),
                    patch.object(
                        w, "godot_command", side_effect=lambda tree, mode, inv, raw, seconds: [str(inv), str(raw)]
                    ),
                    patch.object(w, "run_command", side_effect=simulate),
                ):
                    if count > 2:
                        with self.assertRaisesRegex(ValueError, "exceed 2%"):
                            w.run(plan_path)
                    else:
                        w.run(plan_path)
                progress = w.read_json(out / "progress.json")
                self.assertEqual(progress["completed_lobbies"], 100)
                self.assertEqual(progress["contamination"], w.contamination_summary(100, set(range(count))))
                self.assertEqual(progress["contamination"]["passed"], count <= 2)
                chunks = [w.read_json(Path(c["analysis"])) for c in progress["chunks"]]
                self.assertEqual(sum(len(c["players"]) for c in chunks), 8 * (100 - count))
                self.assertFalse(any(p["seed"] < count for c in chunks for p in c["players"]))
                self.assertTrue(Path(progress["chunks"][0]["capture"]).exists())
                result_path, md_path = out / "result.json", out / "result.md"
                # No R8 fights in this short fixture: aggregation is independently checked below.
                with patch.object(
                    w,
                    "analyze",
                    return_value={"growth": {}, "lines": {}, "report_only": {}, "survival": "", "starting_labels": ""},
                ) as analyze:
                    if count > 2:
                        with self.assertRaisesRegex(ValueError, "exceed 2%"):
                            w.report(plan_path, result_path, md_path)
                    else:
                        w.report(plan_path, result_path, md_path)
                self.assertEqual(analyze.call_args.args[2]["seeds"], list(range(count, 100)))
                result = w.read_json(result_path)
                self.assertEqual(result["lobbies"], 100 - count)
                self.assertEqual(result["contamination"]["dropped_trials"], count)
                self.assertIn('"attempted_trials": 100', md_path.read_text())
