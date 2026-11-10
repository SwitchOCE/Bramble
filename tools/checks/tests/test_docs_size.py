"""Exercise docs size limits against real Git histories, indexes and working trees."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.checks import docs_size

REPO = Path(__file__).resolve().parents[3]


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

    def write(self, path: str, size: int, fill: bytes = b"x") -> None:
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(fill * size)

    def commit(self) -> None:
        self.git("add", "-A")
        self.git("commit", "-qm", "snapshot")

    def errors(self, head: str | None = None, allowed: set[str] | None = None) -> list[str]:
        return docs_size.violations(docs_size.candidates(self.root, self.base, head), allowed or set())

    def cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(Path(docs_size.__file__)), "--root", str(self.root), *args],
            capture_output=True,
            text=True,
        )

    def test_existing_oversized_files_are_not_retroactively_flagged(self) -> None:
        self.assertEqual(self.errors(), [])

    def test_range_checks_oversized_versions_before_shrink_and_delete(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        self.write("docs/new.bin", 20)
        self.commit()
        self.assertIn("docs/new.bin", self.errors("HEAD")[0])
        (self.root / "docs/new.bin").unlink()
        self.commit()
        self.assertIn("docs/new.bin", self.errors("HEAD")[0])

    def test_oversized_committed_version_cannot_hide_behind_local_shrink(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        self.write("docs/new.bin", 1)
        self.git("add", "docs/new.bin")
        self.assertTrue(self.errors())
        (self.root / "docs/new.bin").unlink()
        self.assertTrue(self.errors())

    def test_untracked_staged_and_worktree_sizes_are_checked(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.assertTrue(self.errors())
        self.git("add", "docs/new.bin")
        self.write("docs/new.bin", 1)
        self.assertTrue(self.errors())
        (self.root / "docs/new.bin").unlink()
        self.assertTrue(self.errors())
        self.write("docs/new.bin", 1)
        self.git("add", "docs/new.bin")
        self.assertEqual(self.errors(), [])
        self.write("docs/new.bin", 2_000_001)
        self.assertTrue(self.errors())

    def test_explicit_head_excludes_staged_and_worktree_changes(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.git("add", "docs/new.bin")
        self.assertEqual(self.errors("HEAD"), [])

    def test_shrinking_old_file_and_deletions_pass(self) -> None:
        self.write("docs/existing.bin", 100)
        self.assertEqual(self.errors(), [])
        (self.root / "docs/existing.bin").unlink()
        self.assertEqual(self.errors(), [])

    def test_modified_large_file_is_checked(self) -> None:
        self.write("docs/existing.bin", 2_200_000)
        self.assertTrue(self.errors())

    def test_total_boundary_blob_deduplication_and_exact_allowlist(self) -> None:
        blobs = [docs_size.Blob(f"docs/{i}.jpg", str(i), 2_000_000) for i in range(15)]
        blobs.append(docs_size.Blob("docs/copy.jpg", "0", 2_000_000))
        self.assertEqual(docs_size.violations(blobs, set()), [])
        blobs.append(docs_size.Blob("docs/extra.jpg", "extra", 1))
        self.assertIn("total", docs_size.violations(blobs, set())[0])
        self.assertEqual(docs_size.violations(blobs, {"docs/extra.jpg"}), [])
        blobs = [docs_size.Blob("docs/master.png", "master", 31_000_000)]
        self.assertEqual(docs_size.violations(blobs, {"docs/master.png"}), [])
        self.assertTrue(docs_size.violations(blobs, {"docs/*.png"}))
        blobs.append(docs_size.Blob("docs/copy.png", "master", 31_000_000))
        self.assertTrue(docs_size.violations(blobs, {"docs/master.png"}))

    def test_total_counts_all_introduced_versions_including_modified_paths(self) -> None:
        self.write("docs/existing.bin", 6, b"a")
        self.commit()
        self.write("docs/existing.bin", 6, b"b")
        self.commit()
        self.write("docs/existing.bin", 6, b"a")
        self.commit()
        with patch.object(docs_size, "TOTAL_LIMIT", 11):
            self.assertIn("12 bytes", self.errors("HEAD")[0])

    def test_same_blob_across_history_index_and_worktree_counts_once(self) -> None:
        self.write("docs/new.bin", 6)
        self.commit()
        self.write("docs/copy.bin", 6)
        self.git("add", "docs/copy.bin")
        self.write("docs/untracked.bin", 6)
        with patch.object(docs_size, "TOTAL_LIMIT", 6):
            self.assertEqual(self.errors(), [])

    def test_blob_already_in_base_history_does_not_add_bytes(self) -> None:
        self.write("docs/existing.bin", 100)
        self.commit()
        self.base = self.git("rev-parse", "HEAD").decode().strip()
        self.write("docs/reused.bin", 2_100_000)
        self.assertEqual(self.errors(), [])

    def test_merged_side_branch_history_is_checked(self) -> None:
        self.git("checkout", "-qb", "side")
        self.write("docs/side.bin", 2_000_001)
        self.commit()
        self.write("docs/side.bin", 1)
        self.commit()
        self.git("checkout", "-q", "main")
        self.write("docs/main.bin", 1, b"m")
        self.commit()
        self.git("merge", "-qm", "merge", "side")
        self.assertIn("docs/side.bin", self.errors("HEAD")[0])

    def test_non_docs_ignored_files_and_symlinks_do_not_count(self) -> None:
        self.write("outside.bin", 3_000_000)
        (self.root / ".gitignore").write_text("docs/ignored.bin\n")
        self.write("docs/ignored.bin", 3_000_000)
        (self.root / "docs/link.bin").symlink_to(self.root / "outside.bin")
        self.assertEqual(self.errors(), [])
        self.git("add", "docs/link.bin")
        self.assertEqual(self.errors(), [])

    def test_paths_with_spaces_and_newlines(self) -> None:
        self.write("docs/a space\nand newline.bin", 2_000_001)
        self.commit()
        self.assertIn("docs/a space\nand newline.bin", self.errors("HEAD")[0])

    def test_base_is_required_even_with_synced_upstream_or_detached_head(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        self.write("docs/new.bin", 1)
        self.commit()
        self.git("branch", "upstream")
        self.git("branch", "--set-upstream-to=upstream", "main")
        for detached in (False, True):
            with self.subTest(detached=detached):
                if detached:
                    self.git("checkout", "-q", "--detach")
                missing = self.cli()
                self.assertEqual(missing.returncode, 2)
                self.assertIn("--base", missing.stderr)
                self.assertEqual(self.cli("--base", self.base).returncode, 1)

    def test_cli_range_and_allowlist(self) -> None:
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        args = ("--base", self.base, "--head", "HEAD")
        self.assertEqual(self.cli(*args).returncode, 1)
        allowfile = self.root / docs_size.ALLOWLIST
        allowfile.parent.mkdir(parents=True)
        allowfile.write_text("# Needed master\ndocs/new.bin\n")
        self.assertEqual(self.cli(*args).returncode, 0)
        allowfile.write_text("docs/*.bin\n")
        self.assertEqual(self.cli(*args).returncode, 2)
        self.assertEqual(self.cli("--base", "missing").returncode, 2)

    def test_gate_modes_require_explicit_base_and_check_detached_history(self) -> None:
        for path in (
            "scripts/check.sh",
            "scripts/godot_log.sh",
            "scripts/godot_slot.sh",
            "tools/versions.env",
            "tools/checks/docs_size.py",
            "tools/checks/docs_only_paths.py",
        ):
            target = self.root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / path, target)
        (self.root / ".gitignore").write_text("build/\n")
        self.commit()
        self.base = self.git("rev-parse", "HEAD").decode().strip()
        self.write("docs/new.bin", 2_000_001)
        self.commit()
        self.write("docs/new.bin", 1)
        self.commit()
        self.git("checkout", "-q", "--detach")
        for mode in ([], ["--docs-only"], ["--keep-going", "--no-tests"], ["--shard", "1/4"]):
            with self.subTest(mode=mode):
                command = ["bash", str(self.root / "scripts/check.sh"), *mode]
                missing = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(missing.returncode, 2, missing.stdout + missing.stderr)
                self.assertIn("--base", missing.stdout)
                # Stop at the size violation before any tools or Godot step.
                stopping_command = [arg for arg in command if arg != "--keep-going"]
                explicit = subprocess.run([*stopping_command, "--base", self.base], capture_output=True, text=True)
                self.assertIn("FAIL docs-size", explicit.stdout)
                self.assertNotIn("==> tools", explicit.stdout)


if __name__ == "__main__":
    unittest.main()
