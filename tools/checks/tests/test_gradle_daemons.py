"""Tests for scripts/gradle_daemons.sh: it stops the daemons a run marked, and leaves the rest.

Fake daemons are `sleep` processes whose command line reads GradleDaemon, so no Gradle is needed.
"""

from __future__ import annotations

import os
import subprocess
import time
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parents[3] / "scripts" / "gradle_daemons.sh"


def fake_daemon(env: dict[str, str]) -> subprocess.Popen[bytes]:
    proc = subprocess.Popen(["bash", "-c", "exec -a GradleDaemon sleep 120"], env=env)
    deadline = time.monotonic() + 5
    while time.monotonic() < deadline:
        cmdline = Path(f"/proc/{proc.pid}/cmdline").read_bytes()
        if cmdline.startswith(b"GradleDaemon\0"):
            return proc
        time.sleep(0.05)
    proc.kill()
    raise AssertionError("fake daemon never exec'd")


def run_helper(script: str, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["bash", "-c", f'. "{HELPER}"; {script}'], env=env, capture_output=True, text=True, timeout=30
    )


@unittest.skipUnless(Path("/proc/self/environ").exists(), "needs /proc")
class GradleDaemonsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.procs: list[subprocess.Popen[bytes]] = []

    def tearDown(self) -> None:
        for proc in self.procs:
            if proc.poll() is None:
                proc.kill()
            proc.wait()

    def spawn(self, **extra: str) -> subprocess.Popen[bytes]:
        env = {k: v for k, v in os.environ.items() if k != "BRAMBLE_GRADLE_RUN"} | extra
        proc = fake_daemon(env)
        self.procs.append(proc)
        return proc

    def test_stops_only_this_runs_daemons(self) -> None:
        mine = self.spawn(BRAMBLE_GRADLE_RUN="run-a")
        other_run = self.spawn(BRAMBLE_GRADLE_RUN="run-b")
        unmarked = self.spawn()
        env = dict(os.environ, BRAMBLE_GRADLE_RUN="run-a")
        result = run_helper("gradle_daemons_stop_marked", env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"pid {mine.pid}", result.stdout)
        self.assertIsNotNone(mine.wait(timeout=5))
        self.assertIsNone(other_run.poll())
        self.assertIsNone(unmarked.poll())
        self.assertIn("did not start", result.stdout)

    def test_without_a_mark_stops_nothing(self) -> None:
        unmarked = self.spawn()
        env = {k: v for k, v in os.environ.items() if k != "BRAMBLE_GRADLE_RUN"}
        result = run_helper("gradle_daemons_stop_marked", env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertIsNone(unmarked.poll())

    def test_mark_is_exported_and_unique(self) -> None:
        env = {k: v for k, v in os.environ.items() if k != "BRAMBLE_GRADLE_RUN"}
        script = "gradle_daemons_mark_run; bash -c 'echo $BRAMBLE_GRADLE_RUN'"
        first = run_helper(script, env).stdout.strip()
        second = run_helper(script, env).stdout.strip()
        self.assertTrue(first)
        self.assertNotEqual(first, second)


if __name__ == "__main__":
    unittest.main()
