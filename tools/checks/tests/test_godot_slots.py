"""Exercise the memory-aware shared queue on private locks, without starting Godot."""

import csv
import os
import select
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SETUP = """source "$1"
for i in "${!GODOT_SLOT_LOCKS[@]}"; do GODOT_SLOT_LOCKS[$i]="$2/$i.lock"; done
GODOT_SLOT_LOG="$2/slots.csv"
# Only sourced test shells override the kernel reader and polling delay.
_slot_test_memory_file="$2/memory"
_slot_mem_available_kib() { cat "$_slot_test_memory_file"; }
sleep() { command sleep 0.02; }
godot_slot_acquire
printf '%s\\n' "$GODOT_SLOT_NAME"
"""


class GodotSlotsTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name)
        self.memory = self.path / "memory"
        self.memory.write_text("4194304\n")
        self.command = ["bash", "-c", SETUP, "slots-test", str(ROOT / "scripts/godot_slot.sh"), str(self.path)]
        self.holders = []
        self.addCleanup(self.release_holders)

    def release_holders(self):
        for child in self.holders:
            if child.poll() is None:
                child.communicate("release\n", timeout=2)
            for stream in (child.stdin, child.stdout, child.stderr):
                if stream is not None:
                    stream.close()

    def start_holder(self):
        command = self.command.copy()
        command[2] += "read -r release; godot_slot_release 0 fixture"
        child = subprocess.Popen(
            command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        self.holders.append(child)
        return child

    def acquired_slot(self, child):
        ready, _, _ = select.select([child.stdout], [], [], 2)
        self.assertTrue(ready, "eligible holder must acquire immediately")
        return child.stdout.readline().strip()

    def blocked_attempt(self):
        result = subprocess.run(["timeout", "0.2", *self.command], capture_output=True, text=True)
        self.assertEqual(result.returncode, 124, result.stderr)
        return result

    def test_three_holders_exclude_a_fourth_and_releasing_one_unblocks_it(self):
        slots = [self.acquired_slot(self.start_holder()) for _ in range(3)]
        self.assertEqual(len(set(slots)), 3)
        self.assertIn("all 3 Godot slots are busy", self.blocked_attempt().stderr)
        _, third_log = self.holders[2].communicate("release\n", timeout=2)
        self.assertIn("slot3 allowed: MemAvailable=4194304 KiB", third_log)
        self.assertIn("acquired 2", third_log)
        acquired = subprocess.run(self.command, capture_output=True, text=True, timeout=2)
        self.assertEqual(acquired.returncode, 0, acquired.stderr)
        self.assertEqual(acquired.stdout.strip(), slots[2])
        with (self.path / "slots.csv").open(newline="") as handle:
            rows = list(csv.reader(handle))
        self.assertEqual(rows[0], ["start_utc", "class", "slot", "wait_s", "hold_s", "exit", "command"])
        self.assertEqual(len(rows[1]), len(rows[0]))

    def test_low_memory_waits_for_first_two_even_with_third_free(self):
        slots = [self.acquired_slot(self.start_holder()) for _ in range(2)]
        self.memory.write_text("4194303\n")
        blocked = self.blocked_attempt()
        self.assertIn("slot3 withheld: MemAvailable=4194303 KiB", blocked.stderr)
        self.assertIn("waiting for slot1/2", blocked.stderr)
        self.assertNotIn("all 3 Godot slots are busy", blocked.stderr)
        self.holders[0].communicate("release\n", timeout=2)
        acquired = subprocess.run(self.command, capture_output=True, text=True, timeout=2)
        self.assertEqual(acquired.returncode, 0, acquired.stderr)
        self.assertEqual(acquired.stdout.strip(), slots[0])
        self.assertIn("acquired 0", acquired.stderr)

    def test_waiter_rechecks_memory_before_using_third_slot(self):
        for _ in range(2):
            self.acquired_slot(self.start_holder())
        self.memory.write_text("0\n")
        waiter = self.start_holder()
        ready, _, _ = select.select([waiter.stderr], [], [], 2)
        self.assertTrue(ready)
        first_log = waiter.stderr.readline()
        self.assertIn("slot3 withheld", first_log)
        self.memory.write_text("5000000\n")
        self.assertEqual(self.acquired_slot(waiter), "2")
        _, remaining_log = waiter.communicate("release\n", timeout=2)
        self.assertIn("slot3 allowed: MemAvailable=5000000 KiB", remaining_log)

    def test_unknown_memory_fails_closed_for_third_slot(self):
        for _ in range(2):
            self.acquired_slot(self.start_holder())
        for contents in ("", "invalid\n"):
            with self.subTest(contents=contents):
                self.memory.write_text(contents)
                self.assertIn("slot3 withheld", self.blocked_attempt().stderr)

    def test_command_refuses_to_run_without_memory_cap(self):
        stub = self.path / "systemd-run"
        stub.write_text("#!/bin/sh\nexit 1\n")
        stub.chmod(0o755)
        marker = self.path / "ran"
        result = subprocess.run(
            ["bash", str(ROOT / "scripts/godot_slot.sh"), "touch", str(marker)],
            env={**os.environ, "PATH": f"{self.path}:{os.environ['PATH']}"},
            capture_output=True,
            text=True,
            timeout=2,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn("refusing to run uncapped", result.stderr)
        self.assertFalse(marker.exists())
