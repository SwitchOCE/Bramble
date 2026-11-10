"""CPU-only policy isolation, source drift and canonical seed assertions."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.sim.potluck_arms import SEED_FILE, arm_policy, command, exact_seeds, prepare, source_manifest, verify_pin


class PotluckArmsTest(unittest.TestCase):
    def test_four_arms_change_only_tempo_save_and_rank_without_mutating_source(self):
        priority = [f"unit_{n}" for n in range(12)] + ["little_dollop", "last"]
        source = {
            "line_oozes_tempo": {"priority": priority, "save_threshold": 0, "save_until": 0},
            "line_oozes_engine": {"fixed": True},
        }
        for arm in ("control", "A", "B", "AB"):
            changed = arm_policy(source, arm)
            self.assertEqual(changed["line_oozes_engine"], {"fixed": True})
            tempo = changed["line_oozes_tempo"]
            self.assertEqual(tempo["save_threshold"], 3 if arm in ("A", "AB") else 0)
            self.assertEqual(tempo["save_until"], 10 if arm in ("A", "AB") else 0)
            self.assertEqual(tempo["priority"].index("little_dollop"), 3 if arm in ("B", "AB") else 12)
            self.assertEqual(
                [unit for unit in tempo["priority"] if unit != "little_dollop"],
                [unit for unit in priority if unit != "little_dollop"],
            )
        self.assertEqual(source["line_oozes_tempo"]["priority"], priority)

    def test_manifest_ignores_output_artifacts_but_detects_source_change(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "src").mkdir()
            source = root / "src/example.gd"
            source.write_text("old")
            out = root / "tools/sim/artifacts"
            out.mkdir(parents=True)
            baseline = source_manifest(root, out)
            (out / "generated.py").write_text("artifact")
            self.assertEqual(source_manifest(root, out), baseline)
            source.write_text("new")
            self.assertNotEqual(source_manifest(root, out), baseline)

    def test_seed_list_must_match_exact_order_and_have_no_duplicates(self):
        exact_seeds([{"seed": 280001}, {"seed": 280002}], [280001, 280002])
        with self.assertRaisesRegex(ValueError, "seed list mismatch"):
            exact_seeds([{"seed": 280001}, {"seed": 280001}], [280001, 280002])

    def test_command_has_only_harness_lock_scope_and_full_policy_directory(self):
        argv = command(Path("/repo"), Path("/out"), "AB", 32, Path("/env.sh"), "godot")
        self.assertIn("/tmp/bramble-harness-godot.lock", argv)
        self.assertIn("MemoryMax=3G", argv)
        self.assertIn("lines=/out/AB/lines", argv)
        self.assertIn("games=32", argv)
        self.assertIn("first_seed=280001", argv)
        self.assertFalse(any("godot-slot" in arg for arg in argv))

    def test_prepare_copies_complete_directory_and_pin_rejects_changed_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            lines = root / "tools/sim/lines"
            lines.mkdir(parents=True)
            seed_file = root / SEED_FILE
            seed_file.parent.mkdir(parents=True)
            seed_file.write_text(json.dumps({"seeds": list(range(280001, 280033))}))
            original = {
                "line_oozes_tempo": {
                    "priority": [f"unit_{n}" for n in range(12)] + ["little_dollop"],
                    "save_threshold": 0,
                    "save_until": 0,
                },
                "line_oozes_engine": {"canonical": True},
            }
            (lines / "oozes.json").write_text(json.dumps(original))
            (lines / "other_tribe.json").write_text('{"other_line": {"canonical": true}}')
            out = root / "build/arms"
            with patch("tools.sim.potluck_arms.head", return_value="final-sha"):
                plan = prepare(root, out, "final-sha")
                for arm in ("control", "A", "B", "AB"):
                    self.assertEqual(
                        (out / arm / "lines/other_tribe.json").read_text(), (lines / "other_tribe.json").read_text()
                    )
                    self.assertEqual(
                        json.loads((out / arm / "lines/oozes.json").read_text())["line_oozes_engine"],
                        {"canonical": True},
                    )
                verify_pin(root, out, plan)
                (lines / "other_tribe.json").write_text("changed")
                with self.assertRaisesRegex(ValueError, "source files changed"):
                    verify_pin(root, out, plan)
