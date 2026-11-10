"""Exercise docs size limits against real Git ranges, staging and working trees."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.checks import docs_size


class DocsSizeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "test@example.com")
        self.git("config", "user.name", "test")
        self.write("docs/existing.bin", 2_100_000)
        self.commit()
        self.base = self.git("rev-parse", "HEAD").decode().strip()

    def git(self, *args: str) -> bytes:
        return subprocess.run(["git", *args], cwd=self.root, capture_output=True, check=True).stdout

    def write(self, path: str, size: int) -> None:
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b"x" * size)

    def commit(self) -> None:
        self.git("add", "-A")
        self.git("commit", "-qm", "snapshot")

    def errors(self, head: str | None = None, allowed: set[str] | None = None) -> list[str]:
        sizes, added = docs_size.candidates(self.root, self.base, head)
        return docs_size.violations(sizes, added, allowed or set())

    def test_existing_oversized_files_are_not_retroactively_flagged(self) -> None:
        self.assertEqual(self.errors(), [])
        self.assertEqual(docs_size.default_base(self.root), "HEAD")

    def test_no_upstream_checks_last_committed_change(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        base = docs_size.default_base(self.root)
        self.assertEqual(base, "HEAD^")
        sizes, added = docs_size.candidates(self.root, base, None)
        self.assertTrue(docs_size.violations(sizes, added, set()))

    def test_range_checks_new_files_at_tip(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        self.assertIn("docs/new.bin", self.errors("HEAD")[0])
        self.write("docs/new.bin", 20)
        self.commit()
        self.assertEqual(self.errors("HEAD"), [])

    def test_untracked_staged_and_worktree_sizes_are_checked(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.assertTrue(self.errors())
        self.git("add", "docs/new.bin")
        self.write("docs/new.bin", 1)
        self.assertTrue(self.errors())
        self.git("add", "docs/new.bin")
        self.assertEqual(self.errors(), [])
        self.write("docs/new.bin", 2_000_001)
        self.assertTrue(self.errors())

    def test_shrinking_old_file_and_deletions_pass(self) -> None:
        self.write("docs/existing.bin", 100)
        self.assertEqual(self.errors(), [])
        (self.root / "docs/existing.bin").unlink()
        self.assertEqual(self.errors(), [])

    def test_modified_large_file_is_checked(self) -> None:
        self.write("docs/existing.bin", 2_200_000)
        self.assertTrue(self.errors())

    def test_total_boundary_and_exact_allowlist(self) -> None:
        sizes = {f"docs/{i}.jpg": 2_000_000 for i in range(15)}
        self.assertEqual(docs_size.violations(sizes, set(sizes), set()), [])
        sizes["docs/extra.jpg"] = 1
        self.assertIn("total", docs_size.violations(sizes, set(sizes), set())[0])
        self.assertEqual(docs_size.violations(sizes, set(sizes), {"docs/extra.jpg"}), [])
        sizes = {"docs/master.png": 31_000_000}
        self.assertEqual(docs_size.violations(sizes, set(sizes), {"docs/master.png"}), [])
        self.assertTrue(docs_size.violations(sizes, set(sizes), {"docs/*.png"}))

    def test_only_new_files_count_toward_total(self) -> None:
        sizes = {"docs/existing.bin": 1_500_000, "docs/new.bin": 1_500_000}
        self.assertEqual(docs_size.violations(sizes, {"docs/new.bin"}, set()), [])
        sizes, added = docs_size.candidates(self.root, self.base, None)
        self.assertEqual(sizes, {})
        self.assertEqual(added, set())

    def test_non_docs_and_ignored_files_do_not_count(self) -> None:
        self.write("build/ignored.bin", 3_000_000)
        self.write("outside.bin", 3_000_000)
        (self.root / ".gitignore").write_text("docs/ignored.bin\n")
        self.write("docs/ignored.bin", 3_000_000)
        self.assertEqual(self.errors(), [])

    def test_cli_range_and_allowlist(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        command = [
            "python3",
            str(Path(docs_size.__file__)),
            "--root",
            str(self.root),
            "--base",
            self.base,
            "--head",
            "HEAD",
        ]
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        allowfile = self.root / docs_size.ALLOWLIST
        allowfile.parent.mkdir(parents=True)
        allowfile.write_text("# Needed master\ndocs/new.bin\n")
        self.assertEqual(subprocess.run(command, capture_output=True).returncode, 0)
        allowfile.write_text("docs/*.bin\n")
        self.assertEqual(subprocess.run(command, capture_output=True).returncode, 2)


if __name__ == "__main__":
    unittest.main()
