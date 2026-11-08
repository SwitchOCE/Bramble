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


class TestLaterTrial(unittest.TestCase):
    @staticmethod
    def fixtures():
        result = {
            "paired_seeds": 500,
            "games": 1000,
            "gain": 0.05,
            "margin_95": 0.09,
            "turns": {
                "carrier_upgrade": {"n": 100, "mean_ms": 71.58, "p95_ms": 154.22},
                "hard": {"n": 100, "mean_ms": 70.94, "p95_ms": 153.36},
            },
            "players_sha256": "example",
        }
        ready = {
            "candidate": "carrier_upgrade",
            "description": "Test candidate.",
            "artifact_dir": "build/sim/test",
            "source_revision": "frozen",
            "base_revision": "88ed352",
            "previous_failures": 1,
            "first_seed": 131001,
            "runtime": {"godot-release.pck": "packed"},
            "calibration": {"paired_seeds": 200, "gain": -0.04875, "margin_95": 0.16263},
        }
        return result, ready

    def test_second_failed_promotion_requires_stopping(self):
        from tools.sim.record_bot_campaign import trial_report

        result, ready = self.fixtures()
        text = trial_report(result, ready)
        self.assertIn("NO PROMOTION", text)
        self.assertIn("Stop rule reached: two consecutive failures", text)

    def test_success_resets_failure_counter_but_does_not_auto_promote(self):
        from tools.sim.record_bot_campaign import trial_report

        result, ready = self.fixtures()
        result["gain"] = 0.0465
        result["margin_95"] = 0.0415
        text = trial_report(result, ready)
        self.assertIn("REVIEW PENDING", text)
        self.assertIn("failed promotions: **0**", text)
        self.assertNotIn("Stop rule reached", text)

    def test_partial_result_is_never_a_second_failure(self):
        from tools.sim.record_bot_campaign import trial_report

        result, ready = self.fixtures()
        result["paired_seeds"] = 499
        with self.assertRaises(ValueError):
            trial_report(result, ready)

    def test_meaningful_time_cost_blocks_a_positive_gain(self):
        from tools.sim.record_bot_campaign import trial_report

        result, ready = self.fixtures()
        result["gain"] = 0.3
        result["turns"]["carrier_upgrade"]["p95_ms"] = 200.0
        self.assertIn("NO PROMOTION", trial_report(result, ready))
