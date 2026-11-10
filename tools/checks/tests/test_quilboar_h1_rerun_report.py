"""The retained pre-fix C arm must never override a new B accounting result."""

import copy
import sys
import unittest
from pathlib import Path

SIM = Path(__file__).resolve().parents[3] / "tools/sim"
if str(SIM) not in sys.path:
    sys.path.insert(0, str(SIM))
from quilboar_h1_rerun_report import combine  # noqa: E402


class RerunReportTests(unittest.TestCase):
    def test_selects_versions_without_pooling_and_keeps_c_nondeciding(self):
        original = {
            "arms": {
                arm: {"lobbies": count, "marker": "old"}
                for arm, count in {"B": 150, "C": 150, "uncut": 100, "uncut_frozen": 100}.items()
            },
            "criteria": {
                "accounting": {"arms": {"B": {"passes": False}, "C": {"passes": False}}, "passes": False},
                "fidelity": {"passes": False},
            },
        }
        untouched = copy.deepcopy(original)
        rerun = {
            "arms": {"B": {"lobbies": 150, "marker": "new"}, "uncut": {"lobbies": 100, "marker": "new"}},
            "criteria": {"accounting": {"arms": {"B": {"passes": True}}}, "fidelity": {"passes": True}},
        }
        result = combine(original, rerun)
        self.assertEqual(original, untouched)
        self.assertEqual(result["arms"]["B"]["marker"], "new")
        self.assertEqual(result["arms"]["C"]["marker"], "old")
        self.assertEqual(result["arms"]["uncut_frozen"]["marker"], "old")
        self.assertTrue(result["criteria"]["accounting"]["passes"])
        self.assertFalse(result["criteria"]["accounting"]["arms"]["C"]["deciding"])
        self.assertTrue(result["criteria"]["fidelity"]["passes"])
        self.assertEqual(result["measurement_selection"]["selected_lobbies"], 500)
        rerun["arms"]["B"]["lobbies"] = 149
        with self.assertRaisesRegex(ValueError, "incomplete"):
            combine(original, rerun)
