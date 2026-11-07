"""The promotion margin must use swapped seed clusters, not independent seats."""

import unittest

from tools.sim.summarize_bench import paired_head_to_head, paired_margin


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
