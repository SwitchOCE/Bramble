"""Delayed evidence must never modify another branch or report a partial experiment."""

import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from tools.sim.record_bot_campaign import report, source_is_unchanged


class TestCampaignGuard(unittest.TestCase):
    def test_other_branch_is_rejected_before_any_other_git_call(self):
        with patch("tools.sim.record_bot_campaign.git", return_value="main") as git_call:
            self.assertFalse(source_is_unchanged(Path(), "a" * 40))
            self.assertEqual(git_call.call_count, 1)

    def test_changed_source_or_dirty_checkout_is_rejected(self):
        for values in (["ideation/bots", "src/core/bots/bot_brain.gd"], ["ideation/bots", "", " M notes.md"]):
            with (
                patch("tools.sim.record_bot_campaign.git", side_effect=values),
                patch("tools.sim.record_bot_campaign.subprocess.run", return_value=Mock(returncode=0)),
            ):
                self.assertFalse(source_is_unchanged(Path(), "a" * 40))

    def test_clean_same_source_accepts_documentation_only_followup(self):
        with (
            patch("tools.sim.record_bot_campaign.git", side_effect=["ideation/bots", "", ""]),
            patch("tools.sim.record_bot_campaign.subprocess.run", return_value=Mock(returncode=0)),
        ):
            self.assertTrue(source_is_unchanged(Path(), "a" * 40))

    def test_partial_experiment_and_zero_width_aa_are_rejected(self):
        with self.assertRaises(ValueError):
            report({"paired_seeds": 199}, {"paired_seeds": 500}, {})
        with self.assertRaises(ValueError):
            report({"paired_seeds": 200, "margin_95": 0}, {"paired_seeds": 500, "margin_95": 0.1}, {})
