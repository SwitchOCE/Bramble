"""Run with python3 -m unittest tools.play.test_render_check."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.play import render_check


class RenderCheckTest(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.root = Path(self.work.name)
        self.folders = [self.root / "first", self.root / "second"]
        self.manifest = {
            "files": ["fight-1.png", "fight-2.png"],
            "moments": [
                {
                    "kind": "fight",
                    "hash": "fight",
                    "fight": {"round": 1, "result": "win", "events": 2, "opponent": "Dame Farthing"},
                    "shown": {"events": 2, "opponent": "Farthing"},
                    "files": ["fight-1.png", "fight-2.png"],
                },
                {"kind": "start", "hash": "expected"},
            ],
        }
        for folder in self.folders:
            folder.mkdir()
            for name in self.manifest["files"]:
                (folder / name).touch()
            self.write_manifest(folder)
        (self.root / "log.txt").write_text("You:\n  R1 T1 win against Farthing\n")
        (self.root / "hash.txt").write_text("expected\n")

    def write_manifest(self, folder):
        (folder / "manifest_1688x780.json").write_text(json.dumps(self.manifest))

    def run_check(self):
        args = ["render_check", *map(str, self.folders), str(self.root / "log.txt"), str(self.root / "hash.txt")]
        with patch.object(sys, "argv", args), contextlib.redirect_stdout(io.StringIO()):
            return render_check.main()

    def test_matching_renders_match_the_save_hash(self):
        self.assertEqual(self.run_check(), 0)

    def test_agreeing_renders_with_the_wrong_final_hash_fail(self):
        self.manifest["moments"][-1]["hash"] = "same-but-wrong"
        for folder in self.folders:
            self.write_manifest(folder)
        self.assertEqual(self.run_check(), 1)

    def test_either_render_missing_its_final_moment_fails(self):
        self.manifest["moments"].pop()
        for folder in self.folders:
            self.write_manifest(folder)
            self.assertEqual(self.run_check(), 1)


if __name__ == "__main__":
    unittest.main()
