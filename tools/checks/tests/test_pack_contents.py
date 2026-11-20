"""Tests for tools/checks/pack_contents.py: missing data, art and scenes are caught; a full pack passes."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.checks import pack_contents

IMPORT = '[deps]\nsource_file="res://assets/art/a.jpg"\ndest_files=["res://.godot/imported/a.jpg-1.ctex"]\n'
RUN = f"ghosts/field/runs/aa/{'a' * 64}.json"
FILES = {
    "project.godot": "",
    "src/main/main.tscn": "",
    "assets/card_data.json": "{}",
    "assets/art/a.jpg": "",
    "assets/art/a.jpg.import": IMPORT,
    "tests/test_x.gd": "",
    ".godot/imported/a.jpg-1.ctex": "",
    pack_contents.GHOST_INDEX: "",
    RUN: "{}",
}
FULL = {
    "src/main/main.tscn.remap",
    "assets/card_data.json",
    "assets/art/a.jpg.import",
    ".godot/imported/a.jpg-1.ctex",
    pack_contents.GHOST_INDEX,
    RUN,
}


class PackContentsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for rel, text in FILES.items():
            (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
            (self.root / rel).write_text(text, encoding="utf-8")

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def problems(self, listing: set[str]) -> list[str]:
        return pack_contents.missing_files(listing, self.root, pack_contents.project_files(self.root))

    def test_full_pack_passes(self) -> None:
        self.assertEqual(self.problems(FULL), [])

    def test_missing_json_is_caught(self) -> None:
        self.assertEqual(self.problems(FULL - {"assets/card_data.json"}), ["assets/card_data.json (data file)"])

    def test_missing_imported_art_is_caught(self) -> None:
        found = self.problems(FULL - {".godot/imported/a.jpg-1.ctex"})
        self.assertEqual(found, ["assets/art/a.jpg (imported copy .godot/imported/a.jpg-1.ctex)"])

    def test_missing_main_scene_and_shipped_test_files_are_caught(self) -> None:
        found = self.problems((FULL - {"src/main/main.tscn.remap"}) | {"tests/test_x.gd"})
        self.assertEqual(len(found), 2)

    def test_missing_ghost_index_and_runs_are_caught(self) -> None:
        found = self.problems(FULL - {pack_contents.GHOST_INDEX, RUN})
        self.assertIn(f"{pack_contents.GHOST_INDEX} (ghost field index)", found)
        self.assertIn("ghosts/field/runs/ (ghost field)", found)


if __name__ == "__main__":
    unittest.main()
