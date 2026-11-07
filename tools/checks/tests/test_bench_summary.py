"""The promotion margin must use swapped seed clusters, not independent seats."""

import unittest

from tools.sim.summarize_bench import (
    comparison_verdict,
    paired_head_to_head,
    paired_margin,
    projected_margin,
)


def pair(seed, gain):
    rows = []
    for leg in range(2):
        for seat in range(8):
            side = "candidate" if (seat < 4) != bool(leg) else "incumbent"
            rows.append(
                {
                    "seed": str(seed),
                    "leg": str(leg),
                    "seat": str(seat),
                    "candidate": "new",
                    "incumbent": "hard",
                    "side": side,
                    "place": str(4.5 - gain / 2 if side == "candidate" else 4.5 + gain / 2),
                    "strategy": f"strategy_{seat}",
                }
            )
    return rows


class TestPairedHeadToHead(unittest.TestCase):
    def test_counts_seed_clusters_and_gain_sign(self):
        gains, _ = paired_head_to_head(pair(1, 1) + pair(2, -1))
        self.assertEqual(gains, [1, -1])
        mean, margin = paired_margin(gains)
        self.assertEqual(mean, 0)
        self.assertAlmostEqual(margin, 12.7062)

    def test_identical_policy_cancels_even_with_unequal_seats(self):
        rows = pair(1, 0)
        for row in rows:
            row["place"] = str(int(row["seat"]) + 1)
        gains, strategies = paired_head_to_head(rows)
        self.assertEqual(gains, [0])
        self.assertTrue(all(values == [0] for values in strategies.values()))

    def test_rejects_missing_duplicate_and_unswapped_games(self):
        rows = pair(1, 1)
        for bad in [rows[:-1], rows + rows[:1], [dict(r, side="candidate") for r in rows]]:
            with self.assertRaises(ValueError):
                paired_head_to_head(bad)

    def test_rejects_strategy_redeal_between_legs(self):
        rows = pair(1, 1)
        rows[-1]["strategy"] = "different"
        with self.assertRaises(ValueError):
            paired_head_to_head(rows)

    def test_t_margin_for_200_seeds(self):
        values = [-1, 1] * 100
        _, margin = paired_margin(values)
        self.assertAlmostEqual(margin, 1.97196 / 199**0.5, places=5)


class TestNullCalibration(unittest.TestCase):
    def test_rejects_zero_width_null(self):
        self.assertEqual(comparison_verdict("rng_aa", [0, 0]), "FAIL A/A")
        self.assertEqual(comparison_verdict("bookkeeping", [0, 0]), "PASS BOOKKEEPING")

    def test_bookkeeping_requires_every_pair_to_cancel(self):
        self.assertEqual(comparison_verdict("bookkeeping", [-1, 1]), "FAIL BOOKKEEPING")

    def test_noisy_null_and_outside_margin(self):
        self.assertEqual(comparison_verdict("rng_aa", [-1, 1] * 100), "PASS A/A")
        self.assertEqual(comparison_verdict("rng_aa", [2, 2.1, 2.2]), "FAIL A/A")

    def test_500_projection_uses_seed_variance_and_student_t(self):
        values = [-1, 1] * 100
        self.assertAlmostEqual(projected_margin(values, 200), paired_margin(values)[1])
        self.assertAlmostEqual(projected_margin(values, 500), 1.9647294 * (200 / 199 / 500) ** 0.5)
