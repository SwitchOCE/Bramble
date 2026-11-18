"""Exercise the leftovers sweep with real processes and temporary folders; no Godot needed."""

import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SWEEP = Path(__file__).resolve().parents[3] / "scripts" / "leftovers.sh"


class LeftoversTests(unittest.TestCase):
    def sweep(self, **overrides):
        env = dict(os.environ, LEFTOVERS_MIN_TMP_BYTES="0")
        env.update(overrides)
        return subprocess.run([str(SWEEP)], env=env, capture_output=True, text=True, timeout=10)

    def test_deleted_cwd_reports_non_godot_without_stopping_it(self):
        with tempfile.TemporaryDirectory(prefix="leftovers-test-") as folder:
            child = subprocess.Popen(["sleep", "60"], cwd=folder)
            try:
                Path(folder).rmdir()
                result = self.sweep()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"WARNING PID {child.pid}, age", result.stdout)
                self.assertIn("CPU", result.stdout)
                self.assertIn("deleted cwd:", result.stdout)
                self.assertIn(f"parents: sleep({child.pid}) <-", result.stdout)
                self.assertIn(f"kill {child.pid}", result.stdout)
                self.assertIsNone(child.poll())
            finally:
                child.terminate()
                child.wait()

    def test_godot_reported_only_above_age_threshold(self):
        with tempfile.TemporaryDirectory(prefix="leftovers-test-") as folder:
            root = Path(folder)
            godot = root / "godot"
            godot.write_text(
                f"#!{sys.executable}\n"
                "import ctypes, time\n"
                'ctypes.CDLL(None).prctl(15, b"godot", 0, 0, 0)\n'
                'print("ready", flush=True)\n'
                "time.sleep(60)\n"
            )
            godot.chmod(0o755)
            earlier = subprocess.Popen([str(godot)], stdout=subprocess.PIPE, text=True)
            try:
                self.assertEqual(earlier.stdout.readline(), "ready\n")
                fresh = self.sweep(LEFTOVERS_AGE_SECONDS="999999")
                self.assertNotIn(f"WARNING PID {earlier.pid},", fresh.stdout)
                result = self.sweep(LEFTOVERS_AGE_SECONDS="0")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"WARNING PID {earlier.pid},", result.stdout)
                self.assertIsNone(earlier.poll())
                # A kept systemd unit's old process (the standing display) is not a leftover.
                cgroup = Path(f"/proc/{earlier.pid}/cgroup").read_text().strip()
                unit = cgroup.rsplit("/", 1)[-1]
                if unit:
                    kept = self.sweep(LEFTOVERS_AGE_SECONDS="0", LEFTOVERS_KEEP_UNITS=unit)
                    self.assertNotIn(f"WARNING PID {earlier.pid},", kept.stdout)
            finally:
                earlier.terminate()
                earlier.wait()
                earlier.stdout.close()

    def test_low_tmp_space_fails_with_summary(self):
        result = self.sweep(LEFTOVERS_MIN_TMP_BYTES=str(2**63))
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("leftovers: LOW /tmp SPACE", result.stdout.splitlines()[-1])

    def test_repo_copy_and_claude_folder_sizes_and_ages(self):
        claude = Path(f"/tmp/claude-{os.getuid()}")
        claude.mkdir(exist_ok=True)
        with (
            tempfile.TemporaryDirectory(prefix="leftovers-copy-", dir="/tmp") as copy,
            tempfile.TemporaryDirectory(prefix="leftovers-session-", dir=claude) as session,
        ):
            Path(copy, "project.godot").touch()
            Path(copy, "nested").mkdir()
            Path(copy, "nested", "data").write_bytes(b"x" * (2 * 1024**2))
            Path(session, "nested").mkdir()
            Path(session, "nested", "log").write_bytes(b"x" * (17 * 1024))
            result = self.sweep()
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertRegex(result.stdout, rf"{copy}: 2\.0 MiB; last modified")
            self.assertRegex(result.stdout, rf"{session}: [1-9][0-9.]* KiB; last modified")

    def test_user_tmp_usage_is_recursive_and_quota_warning_does_not_fail(self):
        with tempfile.TemporaryDirectory(prefix="leftovers-usage-", dir="/tmp") as folder:
            nested = Path(folder, "nested")
            nested.mkdir()
            payload = nested / "payload"
            payload.write_bytes(b"x" * (2 * 1024**2))
            usage = payload.stat().st_blocks * 512
            # A high free-space requirement is tested separately; quota warnings stay exit 0.
            result = self.sweep(LEFTOVERS_MAX_USER_TMP_BYTES="0")
            self.assertEqual(result.returncode, 0, result.stderr)
            total = re.search(rf"uid {os.getuid()} files: .* \((\d+) bytes allocated\)", result.stdout)
            self.assertIsNotNone(total, result.stdout)
            self.assertGreaterEqual(int(total[1]), usage)
            self.assertIn("WARNING: /tmp has a per-user quota", result.stdout)
            self.assertIn("(quota warning)", result.stdout.splitlines()[-1])
            quiet = self.sweep(LEFTOVERS_MAX_USER_TMP_BYTES=str(2**63))
            self.assertEqual(quiet.returncode, 0, quiet.stderr)
            self.assertNotIn("WARNING: /tmp has a per-user quota", quiet.stdout)

    @unittest.skipIf(os.geteuid() == 0, "root can read mode-000 folders")
    def test_unreadable_tmp_folders_do_not_crash(self):
        claude = Path(f"/tmp/claude-{os.getuid()}")
        claude.mkdir(exist_ok=True)
        with (
            tempfile.TemporaryDirectory(prefix="leftovers-unreadable-", dir="/tmp") as folder,
            tempfile.TemporaryDirectory(prefix="leftovers-unreadable-", dir=claude) as session,
        ):
            blocked = (Path(folder), Path(session))
            for path in blocked:
                (path / "project.godot").touch()
                path.chmod(0)
            try:
                result = self.sweep()
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn("Traceback", result.stderr)
                self.assertIn("leftovers: ok", result.stdout.splitlines()[-1])
            finally:
                for path in blocked:
                    path.chmod(0o700)


if __name__ == "__main__":
    unittest.main()
