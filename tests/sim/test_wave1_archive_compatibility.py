"""Archived native games receive exactly the current measurement-line compatibility layer."""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from wave1_baseline import (  # noqa: E402
    COMPATIBILITY_MANIFEST,
    HARNESS_OVERLAYS,
    ROOT,
    adapt_archived_bot_pass3,
    file_sha,
    gd_function,
    target_tree,
)


class ArchiveCompatibilityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.output = Path(cls.temp.name)
        cls.target, _ = target_tree(ROOT, "d5b5b4f8", cls.output)
        cls.native = subprocess.check_output(
            ["git", "-C", str(ROOT), "show", "d5b5b4f8:src/core/bots/bot_pass3.gd"], text=True
        )
        cls.adapted = (cls.target / "src/core/bots/bot_pass3.gd").read_text()
        cls.manifest = json.loads((cls.output / COMPATIBILITY_MANIFEST).read_text())

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def test_complete_overlay_has_exact_source_and_destination_hashes(self):
        records = {row["path"]: row for row in self.manifest["files"]}
        expected = {*HARNESS_OVERLAYS, *(str(p.relative_to(ROOT)) for p in (ROOT / "tools/sim/lines").glob("*.json"))}
        self.assertEqual(set(records), expected | {"src/core/bots/bot_pass3.gd"})
        for relative in expected:
            row = records[relative]
            self.assertEqual(row["operation"], "copy")
            self.assertEqual(row["source_sha256"], file_sha(ROOT / relative))
            self.assertEqual(row["destination_sha256"], file_sha(self.target / relative))
            self.assertEqual(row["source_sha256"], row["destination_sha256"])
        adapter = records["src/core/bots/bot_pass3.gd"]
        self.assertEqual(adapter["destination_sha256"], file_sha(self.target / adapter["path"]))
        self.assertNotEqual(adapter["source_sha256"], adapter["destination_sha256"])

    def test_target_bog_and_all_unrelated_bot_functions_remain_exact(self):
        names = [
            line.split("(")[0].removeprefix("static func ")
            for line in self.native.splitlines()
            if line.startswith("static func ")
        ]
        for name in names:
            if name not in {"best_flight", "arrange", "play_slot"}:
                self.assertEqual(gd_function(self.native, name), gd_function(self.adapted, name), name)
        self.assertIn("BotBog.text_value(unit, player, value)", self.adapted)
        self.assertIn("BotBog.keep_engine(player, unit, value)", self.adapted)
        for relative in (
            "src/core/bots/bot_brain.gd",
            "src/core/pass3_fairies.gd",
            "src/core/combat/pass3_bog_growth.gd",
            "content/pass3/rates.json",
        ):
            native = subprocess.check_output(["git", "-C", str(ROOT), "show", "d5b5b4f8:" + relative])
            self.assertEqual((self.target / relative).read_bytes(), native, relative)

    def test_current_flight_court_and_four_profile_inputs_are_present(self):
        flight = gd_function(self.adapted, "best_flight")
        for field in ("line_fly_policy", "from_round", "keep_home_min", "max_away", "allowed"):
            self.assertIn('"' + field + '"', flight)
        for name in ("arrange", "play_slot"):
            self.assertIn('value.strategy.get("line_court", false)', gd_function(self.adapted, name))
        policies = (self.target / "tools/sim/line_policies.gd").read_text()
        self.assertIn('out["line_fly_policy"] = entry["fly_policy"].duplicate(true)', policies)
        self.assertIn('out["line_court"] = entry["source_line"] == "fairies_court"', policies)
        for name in ("birds_homecoming", "birds_tempo", "fairies_ring", "fairies_court"):
            path = self.target / "tools/sim/lines" / (name.split("_")[0] + ".json")
            self.assertIn(name, json.loads(path.read_text()))
            self.assertEqual(
                json.loads(path.read_text()), json.loads((ROOT / path.relative_to(self.target)).read_text())
            )

    def test_adapter_is_idempotent(self):
        self.assertEqual(
            adapt_archived_bot_pass3(self.adapted, (ROOT / "src/core/bots/bot_pass3.gd").read_text()), self.adapted
        )
