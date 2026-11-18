"""Run directly: python3 tools/checks/test_leftovers.py (no Godot needed).

These process fixtures must run outside check.sh, which deliberately hides its descendants.
"""

import os
import re
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

SWEEP = Path(__file__).resolve().parents[2] / "scripts" / "leftovers.sh"


class LeftoversTests(unittest.TestCase):
    def sweep(self, **overrides):
        env = dict(os.environ, LEFTOVERS_MIN_TMP_BYTES="0")
        env.update(overrides)
        start = time.monotonic()
        result = subprocess.run([str(SWEEP)], env=env, capture_output=True, text=True, timeout=5)
        self.assertLess(time.monotonic() - start, 2, result.stdout)
        return result

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

    def test_old_godot_reported_but_current_check_descendants_excluded(self):
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
                check = root / "check.sh"
                check.write_text(
                    '"$1" > "$3.ready" &\nchild=$!\nprintf "%s" "$child" > "$3"\n'
                    'trap \'kill "$child"; wait "$child" 2>/dev/null || true\' EXIT\n'
                    'while [ ! -s "$3.ready" ]; do sleep 0.01; done\n'
                    '"$2"\n'
                )
                current_pid = root / "current.pid"
                result = subprocess.run(
                    ["bash", str(check), str(godot), str(SWEEP), str(current_pid)],
                    env=dict(os.environ, LEFTOVERS_AGE_SECONDS="0", LEFTOVERS_MIN_TMP_BYTES="0"),
                    capture_output=True,
                    text=True,
                    timeout=5,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"WARNING PID {earlier.pid},", result.stdout)
                self.assertNotIn(f"WARNING PID {current_pid.read_text()},", result.stdout)
                self.assertIsNone(earlier.poll())
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


if __name__ == "__main__":
    unittest.main()
