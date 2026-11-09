"""The same-seed check must reject hidden event changes and missing fights."""

import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.checks import compare_seed_traces


class SeedTraceTest(unittest.TestCase):
    def compare(self, before: list[dict], after: list[dict]) -> int:
        with tempfile.TemporaryDirectory() as directory:
            paths = [Path(directory) / name for name in ("before.log", "after.log")]
            for path, rows in zip(paths, (before, after), strict=True):
                path.write_text(
                    "Godot log noise\n" + "".join(f"seed_trace: {json.dumps(row)}\n" for row in rows),
                    encoding="utf-8",
                )
            with (
                patch.object(sys, "argv", ["compare_seed_traces", *map(str, paths)]),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                return compare_seed_traces.main()

    @staticmethod
    def fight(digest: str = "original") -> dict:
        return {
            "seed": 93001,
            "round": 1,
            "players": [0, 1],
            "outcome": {"winner": 0, "damage": 4},
            "result_sha256": digest,
        }

    def test_identical_fights_pass_despite_unrelated_log_noise(self) -> None:
        self.assertEqual(self.compare([self.fight()], [self.fight()]), 0)

    def test_changed_events_fail_even_when_winner_and_damage_match(self) -> None:
        self.assertEqual(self.compare([self.fight()], [self.fight("changed")]), 1)

    def test_empty_or_missing_fights_fail(self) -> None:
        self.assertEqual(self.compare([], []), 1)
        self.assertEqual(self.compare([self.fight()], []), 1)
