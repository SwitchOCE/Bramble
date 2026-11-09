"""Tests for tools/checks/docs_only_paths.py: check.sh --docs-only refuses every change that
needs the Godot steps, and allows plain docs edits."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.checks import docs_only_paths

FILES = {
    "src/game.gd": "extends Node\n",
    "src/fixture_port.gd": 'const DIR := "res://docs/prototype/fixtures/"\n',
    "tests/core/test_engine_docs.gd": 'const DOC := "res://docs/ideation/engine.md"\n',
    "tests/ui/shots/shot.gd": 'const OUT := "res://docs/ideation/evidence/shots"\n',
    "tools/sim/boards.gd": 'const PATH := "res://docs/ideation/evidence/boards.json"\n',
    "docs/ideation/evidence/boards.json": "{}\n",
    "docs/.gdignore": "",
    "docs/STATUS.md": "status\n",
    "docs/ideation/engine.md": "engine\n",
    "docs/ideation/evidence/shots/a.md": "shot\n",
    "docs/prototype/fixtures/combat.json": "{}\n",
}


def git(root: Path, *args: str) -> None:
    subprocess.run(["git", *args], cwd=root, check=True, capture_output=True)


class DocsOnlyPathsTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        git(self.root, "init", "-q", "-b", "main")
        git(self.root, "config", "user.email", "t@example.com")
        git(self.root, "config", "user.name", "t")
        for rel, text in FILES.items():
            path = self.root / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
        git(self.root, "add", "-A")
        git(self.root, "commit", "-q", "-m", "base")
        self.base = subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=self.root, capture_output=True, text=True, check=True
        ).stdout.strip()

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def flagged(self) -> list[str]:
        read_by_code = docs_only_paths.docs_read_by_code(self.root)
        changed = docs_only_paths.changed_paths(self.root, self.base)
        return sorted(p for p in changed if docs_only_paths.needs_godot(p, read_by_code))

    def edit(self, rel: str, text: str = "changed\n") -> None:
        (self.root / rel).write_text(text, encoding="utf-8")

    def commit(self) -> None:
        git(self.root, "add", "-A")
        git(self.root, "commit", "-q", "-m", "change")

    def test_plain_docs_edits_pass_committed_or_not(self) -> None:
        self.edit("docs/STATUS.md")
        self.commit()
        self.edit("docs/STATUS.md", "again\n")
        (self.root / "docs/new.md").write_text("new\n", encoding="utf-8")
        self.assertEqual(self.flagged(), [])

    def test_tool_output_paths_do_not_count_as_read(self) -> None:
        self.edit("docs/ideation/evidence/shots/a.md")
        self.assertEqual(self.flagged(), [])

    def test_code_changes_are_refused_however_they_are_held(self) -> None:
        cases = {
            "committed": lambda: (self.edit("src/game.gd"), self.commit()),
            "staged": lambda: (self.edit("src/game.gd"), git(self.root, "add", "src/game.gd")),
            "unstaged": lambda: self.edit("src/game.gd"),
            "untracked": lambda: (self.root / "src/new.gd").write_text("x\n", encoding="utf-8"),
            "deleted": lambda: (self.root / "src/game.gd").unlink(),
        }
        for name, make in cases.items():
            with self.subTest(name):
                make()
                self.assertTrue(any(p.startswith("src/") for p in self.flagged()), name)
                git(self.root, "reset", "-q", "--hard", self.base)
                git(self.root, "clean", "-qfd")

    def test_staged_change_with_worktree_restored_is_refused(self) -> None:
        self.edit("src/game.gd")
        git(self.root, "add", "src/game.gd")
        self.edit("src/game.gd", FILES["src/game.gd"])
        self.assertEqual(self.flagged(), ["src/game.gd"])

    def test_move_from_src_into_docs_is_refused(self) -> None:
        for committed in (False, True):
            with self.subTest(committed=committed):
                git(self.root, "mv", "src/game.gd", "docs/game.gd")
                if committed:
                    self.commit()
                self.assertIn("src/game.gd", self.flagged())
                git(self.root, "reset", "-q", "--hard", self.base)

    def test_docs_read_by_code_are_refused(self) -> None:
        self.edit("docs/ideation/engine.md")
        self.edit("docs/prototype/fixtures/combat.json")
        (self.root / "docs/.gdignore").unlink()
        self.assertEqual(
            self.flagged(),
            ["docs/.gdignore", "docs/ideation/engine.md", "docs/prototype/fixtures/combat.json"],
        )

    def test_docs_read_through_tools_scripts_are_refused(self) -> None:
        self.edit("docs/ideation/evidence/boards.json")
        self.assertEqual(self.flagged(), ["docs/ideation/evidence/boards.json"])

    def test_change_committed_then_reverted_passes(self) -> None:
        self.edit("src/game.gd")
        self.commit()
        self.edit("src/game.gd", FILES["src/game.gd"])
        self.commit()
        self.assertEqual(self.flagged(), [])


if __name__ == "__main__":
    unittest.main()
