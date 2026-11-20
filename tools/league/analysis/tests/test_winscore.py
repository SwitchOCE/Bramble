import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from winscore import score


def game(g, red_places, blue_places):
    return {"game": g, "seats": [{"colour": "red", "place": p} for p in red_places] +
            [{"colour": "blue", "place": p} for p in blue_places]}


class WinScore(unittest.TestCase):
    def test_first_gets_one_extra_point(self):
        # Red takes 1, 4, 6, 7: 9 + 5 + 3 + 2 = 19, average 4.75. Blue has the rest: 18, 4.5.
        s = score([game(0, [1, 4, 6, 7], [2, 3, 5, 8]), game(1, [2, 3, 5, 8], [1, 4, 6, 7])])
        self.assertAlmostEqual(s["red"], (19 + 18) / 8)
        self.assertAlmostEqual(s["blue"], (18 + 19) / 8)
        self.assertAlmostEqual(s["gap_red_minus_blue"], 0.0)
        self.assertEqual(s["seed_pairs"], 1)

    def test_scores_add_up_and_average_placement_can_disagree(self):
        # Red: 1, 6, 7, 8 (average place 5.5, worse) scores 9 + 3 + 2 + 1 = 15.
        # Blue: 2, 3, 4, 5 (average place 3.5, better) scores 7 + 6 + 5 + 4 = 22.
        s = score([game(0, [1, 6, 7, 8], [2, 3, 4, 5]), game(1, [1, 6, 7, 8], [2, 3, 4, 5]),
                   game(2, [1, 6, 7, 8], [2, 3, 4, 5]), game(3, [1, 6, 7, 8], [2, 3, 4, 5])])
        self.assertAlmostEqual(s["red"] + s["blue"], 9.25)
        self.assertAlmostEqual(s["gap_red_minus_blue"], 15 / 4 - 22 / 4)
        self.assertAlmostEqual(s["gap_ci95"], 0.0)


if __name__ == "__main__":
    unittest.main()
