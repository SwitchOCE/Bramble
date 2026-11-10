"""Exercise the shared three-slot queue on private locks, without starting Godot."""

import select
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SETUP = """source "$1"
for i in "${!GODOT_SLOT_LOCKS[@]}"; do GODOT_SLOT_LOCKS[$i]="$2/$i.lock"; done
GODOT_SLOT_LOG="$2/slots.csv"
godot_slot_acquire
printf '%s\\n' "$GODOT_SLOT_NAME"
"""


class GodotSlotsTest(unittest.TestCase):
    def test_three_holders_exclude_a_fourth_and_releasing_one_unblocks_it(self):
        with tempfile.TemporaryDirectory() as directory:
            command = [
                "bash",
                "-c",
                SETUP + "read -r release; godot_slot_release 0 fixture",
                "slots-test",
                str(ROOT / "scripts/godot_slot.sh"),
                directory,
            ]
            holders = []
            try:
                slots = []
                for _ in range(3):
                    child = subprocess.Popen(
                        command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
                    )
                    holders.append(child)
                    ready, _, _ = select.select([child.stdout], [], [], 2)
                    self.assertTrue(ready, "all three holders must acquire immediately")
                    slots.append(child.stdout.readline().strip())
                self.assertEqual(len(set(slots)), 3)
                fourth = ["timeout", "0.2", "bash", "-c", SETUP, "slots-test", command[-2], directory]
                blocked = subprocess.run(fourth, capture_output=True, text=True)
                self.assertEqual(blocked.returncode, 124)
                self.assertIn("all 3 Godot slots are busy", blocked.stderr)
                holders[0].communicate("release\n", timeout=2)
                acquired = subprocess.run(fourth, capture_output=True, text=True)
                self.assertEqual(acquired.returncode, 0, acquired.stderr)
                self.assertEqual(acquired.stdout.strip(), slots[0])
            finally:
                for child in holders:
                    if child.poll() is None:
                        child.communicate("release\n", timeout=2)
                    for stream in (child.stdin, child.stdout, child.stderr):
                        if stream is not None:
                            stream.close()
