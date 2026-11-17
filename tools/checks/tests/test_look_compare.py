"""Tests for tools/look/compare.py's scores: one wrong corner barely moves the whole-screen number,
and its region is named the worst with a large number of its own. Needs Pillow; skipped without it."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # CI has no Pillow today
    Image = None

COMPARE = Path(__file__).resolve().parents[2] / "look" / "compare.py"


def load_compare():
    spec = importlib.util.spec_from_file_location("look_compare", COMPARE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@unittest.skipIf(Image is None, "Pillow is not installed")
class RegionScoreTest(unittest.TestCase):
    def setUp(self) -> None:
        self.compare = load_compare()
        self.mock = Image.new("RGB", (1920, 1080), (30, 40, 56))
        ImageDraw.Draw(self.mock).rectangle((600, 300, 1300, 800), fill=(200, 160, 70))

    def test_same_pictures_score_zero_everywhere(self) -> None:
        result = self.compare.measure(self.mock, self.mock.copy(), (16, 9))
        self.assertEqual(result["whole"]["mean"], 0)
        self.assertEqual(len(result["regions"]), 16 * 9)
        self.assertEqual(max(r["mean"] for r in result["regions"]), 0)

    def test_a_wrong_corner_is_small_overall_and_large_in_its_region(self) -> None:
        game = self.mock.copy()
        # A 120 px element in the bottom left corner, wholly the wrong colour.
        ImageDraw.Draw(game).rectangle((0, 960, 119, 1079), fill=(230, 220, 190))
        result = self.compare.measure(self.mock, game, (16, 9))
        worst = result["regions"][0]
        self.assertLess(result["whole"]["mean"], 2)
        self.assertEqual(worst["region"], "A9")
        self.assertEqual(worst["where"], "bottom left")
        self.assertEqual(worst["box"], (0, 960, 120, 1080))
        self.assertGreater(worst["mean"], 100)
        self.assertEqual(result["regions"][1]["mean"], 0)

    def test_regions_cover_screens_that_do_not_divide_evenly(self) -> None:
        mock = Image.new("RGB", (1000, 700))
        result = self.compare.measure(mock, mock.copy(), (16, 9))
        area = sum((r["box"][2] - r["box"][0]) * (r["box"][3] - r["box"][1]) for r in result["regions"])
        self.assertEqual(area, 1000 * 700)

    def test_column_names_go_past_z(self) -> None:
        self.assertEqual([self.compare.column_name(i) for i in (0, 15, 25, 26)], ["A", "P", "Z", "AA"])

    def test_different_sizes_are_refused(self) -> None:
        with self.assertRaises(self.compare.CompareError):
            self.compare.measure(self.mock, Image.new("RGB", (1280, 720)), (16, 9))


if __name__ == "__main__":
    unittest.main()
