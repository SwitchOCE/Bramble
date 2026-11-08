"""The logging proof must reject changes in combat carry or Last Stand, not only placement."""

import json
import tempfile
import unittest
from pathlib import Path

from tools.sim.compare_bots import compare


class TestFightTrace(unittest.TestCase):
    @staticmethod
    def fixtures(folder):
        paths = [str(folder / name) for name in ("logged", "quiet")]
        outcome = {"winner": 0, "damage": 4, "last_stand_sides": [1], "carry": [{"op": "buff", "attack": 1}]}
        for prefix in paths:
            Path(prefix + ".trace.jsonl").write_text('{"seed": 1, "board": []}\n')
            Path(prefix + ".fights.jsonl").write_text(json.dumps(outcome) + "\n")
            for part in ("players", "rounds", "cards"):
                Path(f"{prefix}.{part}.csv").write_text("seed\n1\n")
            Path(prefix + ".turns.csv").write_text("seed,leg,usec\n1,0,1000\n")
        return paths, outcome

    def test_matching_fight_results_are_counted(self):
        with tempfile.TemporaryDirectory() as temp:
            paths, _ = self.fixtures(Path(temp))
            result = compare(*paths)
            self.assertEqual(result["identical_fights"], 1)
            self.assertEqual(*result["fight_trace_sha256"])

    def test_carry_and_last_stand_differences_fail_even_with_identical_final_boards(self):
        with tempfile.TemporaryDirectory() as temp:
            for key, changed in (("carry", []), ("last_stand_sides", [])):
                with self.subTest(field=key):
                    paths, outcome = self.fixtures(Path(temp))
                    outcome[key] = changed
                    Path(paths[1] + ".fights.jsonl").write_text(json.dumps(outcome) + "\n")
                    with self.assertRaisesRegex(ValueError, "full fight outcomes"):
                        compare(*paths)

    def test_one_missing_fight_trace_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            paths, _ = self.fixtures(Path(temp))
            Path(paths[1] + ".fights.jsonl").unlink()
            with self.assertRaisesRegex(ValueError, "full fight outcomes"):
                compare(*paths)
