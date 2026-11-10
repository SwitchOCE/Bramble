"""Truncated seats must fail before reports or provenance seals can accept them."""

import csv
import gzip
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "tools/sim"))
import b9_a4
import b9_measure_report as report
from capture_validation import TrajectoryError, validate_compact, validate_rounds
from quilboar_h1 import A35_LINES


def lobbies():
    return [
        {
            "seed": seed,
            "players": [{"seat": seat, "rounds": 15, "line": A35_LINES[(seed * 8 + seat) % 12]} for seat in range(8)],
            "rounds": [
                {
                    "seat": seat,
                    "round": r,
                    "line": A35_LINES[(seed * 8 + seat) % 12],
                    "stats": 1800 * 1.5 ** (r - 12),
                    "units": [],
                }
                for seat in range(8)
                for r in range(1, 16)
            ],
        }
        for seed in range(2911001, 2911065)
    ]


class CaptureValidationTest(unittest.TestCase):
    def test_complete_64_lobby_report_passes_but_one_truncated_seat_is_rejected(self):
        games = lobbies()
        with tempfile.TemporaryDirectory() as directory:
            p = Path(directory)
            (p / "summary.json").write_text(json.dumps({"passes": True, "sim_job": {"dropped": {}}}))

            def save():
                with gzip.open(p / "C.lobbies.json.gz", "wt") as stream:
                    json.dump(games, stream)

            save()
            accepted = report.summarize(p, expected_seeds=list(range(2911001, 2911065)))
            self.assertTrue(accepted["decides"]["scale_passes"])
            self.assertTrue(accepted["decides"]["growth_passes"])
            games[0]["rounds"] = [r for r in games[0]["rounds"] if r["seat"] != 0 or r["round"] <= 8]
            save()
            with self.assertRaises(TrajectoryError) as error:
                report.summarize(p, expected_seeds=list(range(2911001, 2911065)))
            self.assertEqual(error.exception.rejected_seeds, [2911001])

    def test_native_truncation_cannot_leave_a_capture_seal(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shard = root / "lobbies/shards/shard-1"
            shard.mkdir(parents=True)
            rows = [{"seed": 1, "leg": 0, "seat": seat, "rounds": 15} for seat in range(8)]
            with (shard / "source.players.csv").open("w", newline="") as stream:
                writer = csv.DictWriter(stream, rows[0].keys())
                writer.writeheader()
                writer.writerows(rows)
            with gzip.open(shard / "source.fights.jsonl.gz", "wt") as stream:
                for r in range(1, 16):
                    for seat in range(8):
                        if seat == 0 and r > 8:
                            continue
                        stream.write(
                            json.dumps({"seed": 1, "leg": 0, "input": {"player_ids": [seat, -1], "round": r}}) + "\n"
                        )
            output = root / "captures"
            output.mkdir()
            (output / "source.json").write_text("stale seal")
            with patch.object(b9_a4, "revision", return_value="source"), self.assertRaises(TrajectoryError):
                b9_a4.collect_captures(root / "lobbies", output, "source")
            self.assertFalse((output / "source.json").exists())

    def test_missing_interior_and_duplicate_rounds_are_rejected(self):
        games = lobbies()[:1]
        games[0]["rounds"] = [r for r in games[0]["rounds"] if r["seat"] != 0 or r["round"] != 7]
        with self.assertRaisesRegex(TrajectoryError, "missing rounds \\[7\\]"):
            validate_compact(games)
        declared = [((1, 0, s), 1) for s in range(8)]
        frames = [(key, 1) for key, _ in declared]
        with self.assertRaisesRegex(TrajectoryError, "duplicate round"):
            validate_rounds(declared, [*frames, frames[0]])
