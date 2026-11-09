"""Five-tribe baselines preserve the measured phase and immutable seat population."""

import json
import sys
import tarfile
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from wave1_accounting import LINES
from wave1_baseline import analyze, godot_command, parse_chunk, preset_overrides, target_tree


class BaselineTests(unittest.TestCase):
    def test_shipped_does_not_change_defaults_and_checkpoint_only_changes_caps(self):
        self.assertEqual(preset_overrides("shipped"), {})
        self.assertEqual(preset_overrides("checkpoint"), {"card_size_caps": False, "card_rate_limits": False})
        with self.assertRaisesRegex(ValueError, "never invented"):
            preset_overrides("B")
        self.assertEqual(preset_overrides("B", {"fairies_initial_ring_size": 4}), {"fairies_initial_ring_size": 4})
        with self.assertRaisesRegex(ValueError, "roster"):
            preset_overrides("B", {"tribes_per_lobby": 0})

    def test_simulation_and_other_godot_commands_use_their_approved_locks(self):
        command = godot_command(Path("/tmp/tree"), "run", Path("/tmp/plan"), Path("/tmp/result"), 123)
        self.assertIn("/tmp/bramble-harness-godot.lock", command)
        self.assertIn("MemoryMax=3G", command)
        self.assertIn("timeout", command)
        self.assertIn("123", command)
        self.assertIn("/opt/bramble/env.sh", command[-1])
        self.assertNotIn("/tmp/bramble-godot.lock", command)
        probe = godot_command(Path("/tmp/tree"), "probe", Path("/tmp/plan"), Path("/tmp/result"), do_import=True)
        self.assertIn("/tmp/bramble-godot.lock", probe)
        self.assertNotIn("/tmp/bramble-harness-godot.lock", probe)
        with self.assertRaisesRegex(ValueError, "imports must be separate"):
            godot_command(Path("/tmp/tree"), "run", Path("/tmp/plan"), Path("/tmp/result"), do_import=True)

    def records(self):
        names = [*LINES, *(["hard_field:varied"] * 4)]
        config = {
            "tribes_per_lobby": 5,
            "card_size_caps": True,
            "card_rate_limits": True,
            "pass3_content": True,
            "pass3_loop_guards": True,
        }
        result = []
        for number in (8, 10, 12, 14):
            for seat in range(0, 8, 2):
                snapshots = []
                for index in (seat, seat + 1):
                    starting = names[index].split(":")[0]
                    current = "line_birds_homecoming" if starting == "line_birds_tempo" else starting
                    snapshots.append(
                        {
                            "starting_line": starting,
                            "current_line": current,
                            "active_stats": 100 + index,
                            "largest_share": 0.25,
                        }
                    )
                result.append(
                    {
                        "type": "fight",
                        "seed": 1,
                        "input": {"round": number, "player_ids": [seat, seat + 1], "config": config, "tiers": [6, 6]},
                        "result": {"winner": 0},
                        "combat_start": snapshots,
                        "after_start_effects": [{"active_stats": 999}, {"active_stats": 999}],
                    }
                )
        result.append(
            {
                "type": "lobby",
                "seed": 1,
                "tribes": ["Birds", "Fairies", "Hunters", "Oozes", "Bog folk"],
                "starting_lines": names,
                "final_lines": ["line_birds_homecoming" if name == "line_birds_tempo" else name for name in names],
                "players": [{"seat": i, "place": i + 1, "rounds": 14} for i in range(8)],
            }
        )
        return result, config

    def parse(self, records, config):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder, "records.jsonl")
            path.write_text("".join(json.dumps(r) + "\n" for r in records))
            return parse_chunk(path, [1], config)

    def test_capture_uses_pre_start_and_keeps_switched_tempo_separate(self):
        records, config = self.records()
        boards, players = self.parse(records, config)
        self.assertEqual(len(boards), 32)
        tempo = next(row for row in boards if row["line"] == "line_birds_tempo")
        self.assertEqual(tempo["stats"], 101)
        self.assertEqual(tempo["post_start_stats"], 999)
        self.assertEqual(tempo["current_line"], "line_birds_homecoming")
        self.assertEqual(len(players), 8)
        self.assertEqual(players[1]["line"], "line_birds_tempo")
        self.assertEqual(players[1]["final_line"], "line_birds_homecoming")

    def test_wrong_rotation_fallback_and_duplicate_capture_are_rejected(self):
        records, config = self.records()
        records[-1]["tribes"].remove("Birds")
        with self.assertRaisesRegex(ValueError, "rotation"):
            self.parse(records, config)
        records, config = self.records()
        records[0]["combat_start"][0]["current_line"] = "line_fast"
        with self.assertRaisesRegex(ValueError, "fell back"):
            self.parse(records, config)
        records, config = self.records()
        records.insert(0, records[0])
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.parse(records, config)

    def test_known_growth_r12_median_and_survival_measures(self):
        records, config = self.records()
        boards, players = self.parse(records, config)
        for row in boards:
            row["stats"] = 10 * 1.3 ** (row["round"] - 8)
        plan = {"seeds": [1], "bootstrap_replicates": 32, "bootstrap_seed": 77}
        result = analyze(boards, players, plan)
        self.assertAlmostEqual(result["growth"]["all_seats"]["point"], 1.3)
        self.assertAlmostEqual(result["lines"]["line_birds_tempo"]["median"], 10 * 1.3**4)
        self.assertEqual(result["lines"]["line_birds_tempo"]["r14_alive"], 1)
        self.assertEqual(result["lines"]["line_birds_homecoming"]["lobby_win_rate"], 1)
        self.assertEqual(result["report_only"]["r14_alive_all_seats_share"], 1)

    def test_other_source_commit_is_archived_and_measurement_overlay_is_explicit(self):
        def archive_command(_command, stdout, check):
            self.assertTrue(check)
            with tarfile.open(fileobj=stdout, mode="w") as archive:
                archive.add(source_file, arcname="source.txt")

        with tempfile.TemporaryDirectory() as folder:
            parent = Path(folder)
            source = parent / "source"
            output = parent / "output"
            source.mkdir()
            output.mkdir()
            source_file = source / "source.txt"
            source_file.write_text("original tree stays untouched")

            def version(_tree, *_args):
                return "b" * 40

            with (
                patch("wave1_baseline.git", side_effect=version),
                patch("wave1_baseline.subprocess.run", side_effect=archive_command),
            ):
                target, commit = target_tree(source, "HEAD", output)
            self.assertEqual(commit, "b" * 40)
            self.assertEqual((target / "source.txt").read_text(), source_file.read_text())
            self.assertTrue((target / "tools/sim/wave1_baseline.gd").is_file())
            self.assertFalse((source / "tools").exists())
