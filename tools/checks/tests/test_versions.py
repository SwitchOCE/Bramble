"""Tests for tools/checks/versions.py: each kind of drift is caught, and a clean tree passes."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from tools.checks import versions

ENV = "# pins\nGODOT_VERSION=4.7.2\nGUT_VERSION=9.7.1\nGODOT_LINUX_SHA512=abc123def456abc123def456\n"


def make_tree(
    root: Path, env: str = ENV, block: str | None = None, features: str = '"4.7"', gut: str = "9.7.1"
) -> None:
    files = {
        "tools/versions.env": env,
        "scripts/cloud-setup.sh": f"#!/bin/bash\n{versions.BEGIN_MARKER}\n{env if block is None else block}"
        f"{versions.END_MARKER}\necho done\n",
        "project.godot": f'[application]\nconfig/features=PackedStringArray({features}, "GL Compatibility")\n',
        "addons/gut/plugin.cfg": f'[plugin]\nversion="{gut}"\n',
        ".github/workflows/ci.yml": "env: read from tools/versions.env\n",
    }
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")


class VersionsCheckTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_clean_tree_passes(self) -> None:
        make_tree(self.root)
        self.assertEqual(versions.check(self.root), [])

    def test_stale_setup_block_fails(self) -> None:
        make_tree(self.root, block=ENV.replace("4.7.2", "4.7.1"))
        problems = versions.check(self.root)
        self.assertEqual(len(problems), 1)
        self.assertIn("differs from tools/versions.env", problems[0])

    def test_missing_setup_markers_fail(self) -> None:
        make_tree(self.root)
        (self.root / "scripts/cloud-setup.sh").write_text("#!/bin/bash\n", encoding="utf-8")
        self.assertIn("lacks the", versions.check(self.root)[0])

    def test_project_features_must_name_major_minor(self) -> None:
        make_tree(self.root, features='"4.6"')
        self.assertIn('does not name "4.7"', versions.check(self.root)[0])

    def test_gut_version_must_match(self) -> None:
        make_tree(self.root, gut="9.6.1")
        self.assertIn("addons/gut is GUT 9.6.1", versions.check(self.root)[0])

    def test_literal_pin_in_workflow_fails(self) -> None:
        make_tree(self.root)
        (self.root / ".github/workflows/ci.yml").write_text("GODOT: 4.7.2\n", encoding="utf-8")
        expected = ".github/workflows/ci.yml spells out GODOT_VERSION=4.7.2; read it from tools/versions.env"
        self.assertEqual(versions.check(self.root), [expected])

    def test_longer_version_is_not_a_literal_hit(self) -> None:
        make_tree(self.root)
        (self.root / ".github/workflows/ci.yml").write_text("other: 14.7.2.1\n", encoding="utf-8")
        self.assertEqual(versions.check(self.root), [])

    def test_parse_env_rejects_bad_lines(self) -> None:
        with self.assertRaises(ValueError):
            versions.parse_env("GODOT_VERSION\n")


if __name__ == "__main__":
    unittest.main()
