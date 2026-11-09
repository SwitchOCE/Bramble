"""Accounting keeps seat assignment fixed and seed uncertainty clustered."""

import json
import random
import statistics
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from metrics import percentile
from wave1_accounting import CONFIG, LINES, ROUNDS, compact_capture, measurements


class AccountingTests(unittest.TestCase):
    def test_known_preliminary_growth_and_medians(self):
        rows = [{"seed": seed, "round": r, "stats": 10 * 1.3 ** (r - 8)} for seed in (1, 2, 3) for r in ROUNDS]
        result = measurements(rows, [1, 2, 3], 64, 81)
        self.assertAlmostEqual(result["preliminary_growth"]["point"], 1.3)
        self.assertEqual(result["preliminary_growth"]["ci95"], [1.3, 1.3])
        self.assertAlmostEqual(result["rounds"]["12"]["median"], 10 * 1.3**4)

    def test_seed_bootstrap_matches_independent_survivor_reconstruction(self):
        seeds = [1, 2, 3, 4]
        rows = [
            {"seed": seed, "round": r, "stats": seed * 10 + r + seat}
            for seed in seeds
            for r in ROUNDS
            if not (seed == 4 or (seed == 3 and r == 14))
            for seat in range(seed)
        ]
        result = measurements(rows, seeds, 128, 71)
        rng = random.Random(71)
        draws = []
        for _ in range(128):
            selected = rng.choices(seeds, k=len(seeds))
            values = [row["stats"] for seed in selected for row in rows if row["seed"] == seed and row["round"] == 14]
            if values:
                draws.append(statistics.median(values))
        self.assertEqual(result["rounds"]["14"]["ci95"], [percentile(draws, 0.025), percentile(draws, 0.975)])
        self.assertEqual(result["bootstrap"]["seed_clusters"], 4)
        self.assertEqual(result["rounds"]["14"]["seed_clusters_with_observations"], 2)
        self.assertEqual(result["rounds"]["14"]["valid_bootstrap_draws"], len(draws))

    def test_missing_endpoint_is_unknown(self):
        result = measurements([{"seed": 1, "round": 8, "stats": 50}], [1, 2], 32)
        self.assertIsNone(result["rounds"]["14"]["median"])
        self.assertIsNone(result["preliminary_growth"]["point"])
        self.assertIsNone(result["preliminary_growth"]["ci95"])

    def capture(self):
        records = []
        names = [*LINES, "hard_field", "hard_field", "hard_field", "hard_field"]
        for number in (1, 12):
            for left in range(0, 8, 2):
                snapshots = []
                for seat in (left, left + 1):
                    actual = (
                        "line_birds_homecoming" if names[seat] == "line_birds_tempo" and number == 12 else names[seat]
                    )
                    snapshots.append(
                        {
                            "assigned_line": names[seat],
                            "line": actual,
                            "policy": actual,
                            "active_stats": 100 + seat,
                            "largest_share": 0.25,
                            "gold_spent_game": 30,
                            "units": [],
                        }
                    )
                records.append(
                    {
                        "seed": 1,
                        "input": {
                            "config": CONFIG.copy(),
                            "round": number,
                            "player_ids": [left, left + 1],
                            "tiers": [6, 6],
                            "slots": [[[]] * 7, [[]] * 7],
                            "fight_rules": [{"ring_size": 1, "homecomings": 2}] * 2,
                        },
                        "combat_start": snapshots,
                    }
                )
        return records

    def read_records(self, records):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory, "capture.jsonl")
            path.write_text("".join(json.dumps(record) + "\n" for record in records))
            return compact_capture(path, 1, 1)

    def test_tempo_switch_keeps_its_original_committed_seat_label(self):
        rows = self.read_records(self.capture())
        tempo = next(row for row in rows if row["line"] == "line_birds_tempo")
        self.assertEqual(tempo["actual_policy"], "line_birds_homecoming")
        self.assertEqual(len([r for r in rows if r["line"] in LINES]), 4)
        self.assertEqual(len(rows), 8)

    def test_capture_rejects_fallback_and_wrong_caps(self):
        records = self.capture()
        records[-4]["combat_start"][0]["line"] = "line_fast"
        with self.assertRaisesRegex(ValueError, "fell back"):
            self.read_records(records)
        records = self.capture()
        records[0]["input"]["config"]["card_size_caps"] = True
        with self.assertRaisesRegex(ValueError, "wrong runtime"):
            self.read_records(records)
