import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from wave1_rebase_compare import CONTROL, SOURCE, combine, load_setting, markdown, tribe_drift
from lever_sweep import file_sha


class RebaseComparisonTests(unittest.TestCase):
    def settings(self):
        b = json.loads(CONTROL.read_text())
        b.update(source_commit=SOURCE + "0" * 32, selected_seeds=list(range(320)))
        b["config"]["pass3_preset"] = "B"
        card = dict(
            card_present_fights=4,
            zero_output_card_present_fights=1,
            eligible_instances=5,
            output_total=6,
            output_per_card_present_fight=1.5,
            output_per_eligible_instance_fight=1.2,
        )
        summary = {"peat_king": card, "peat_cutter": dict(card)}
        b["peat_rates"] = {
            "scope": "All rounds; report only.",
            "denominator": "Distinct native card bodies per fight.",
            "attribution": "Native-body output only.",
            "gold_stage": "Credited next turn.",
            "rounds": {"8": summary},
            "all_rounds": summary,
        }
        b["noncommitted_tribe_drift"] = tribe_drift(
            [
                dict(
                    seed=seed,
                    seat=seat,
                    line="hard_field",
                    assigned_build="fairies_rings",
                    assigned_tribes=["Fairies"],
                    final_tribe="Fairies",
                )
                for seed in range(320)
                for seat in range(4)
            ]
        )
        b["round_fight_outcomes"] = {str(r): dict(wins=2, draws=0, fights=4) for r in range(8, 15)}
        b["provenance"] = dict(
            config_sha256="config", rates_sha256="rates", result_sha256="result", overrides={"pass3_preset": "B"}
        )
        c = copy.deepcopy(b)
        c["config"]["pass3_preset"] = "C"
        c["provenance"]["overrides"] = {"pass3_preset": "C"}
        c["rates"]["birds_homecoming_multiplier"] = 4
        return b, c

    def test_different_seed_lists_and_wrong_caps_or_source_are_rejected(self):
        for change in (
            lambda c: c["selected_seeds"].__setitem__(0, 999),
            lambda c: c["config"].update(card_rate_limits=False),
            lambda c: c["config"].update(card_size_caps=False),
            lambda c: c.update(source_commit="wrong"),
        ):
            b, c = self.settings()
            change(c)
            with self.assertRaises(ValueError):
                combine(b, c, b["selected_seeds"])

    def test_config_differences_must_be_preset_or_resolved_rates(self):
        b, c = self.settings()
        c["config"]["income_by_turn"] = [99]
        with self.assertRaisesRegex(ValueError, "unrelated"):
            combine(b, c, b["selected_seeds"])
        del c["config"]["income_by_turn"]
        del b["config"]["income_by_turn"]
        b["config"]["birds_homecoming_multiplier"] = 2
        c["config"]["birds_homecoming_multiplier"] = 4
        self.assertTrue(combine(b, c, b["selected_seeds"])["no_other_bars"])

    def test_extra_rate_override_is_rejected(self):
        b, c = self.settings()
        c["provenance"]["overrides"]["birds_homecoming_multiplier"] = 2
        with self.assertRaisesRegex(ValueError, "only the authored"):
            combine(b, c, b["selected_seeds"])

    def test_report_contains_both_peat_rows_denominators_and_actual_rates(self):
        b, c = self.settings()
        report = markdown(combine(b, c, b["selected_seeds"]))
        self.assertIn("Peat King / raises | 4 | 25.0% | 5 | 6 | 1.500 | 1.200", report)
        self.assertIn("Peat Cutter / credited next-turn gold | 4 | 25.0%", report)
        self.assertIn("`birds_homecoming_multiplier` | 2.0 | 4", report)
        self.assertIn("not a matched-phase", report)
        self.assertEqual(len(combine(b, c, b["selected_seeds"])["deciding_measures"]), 2)

    def test_drift_separates_neutral_assignments_other_tribes_and_no_majority(self):
        rows = [
            dict(
                seed=1,
                seat=seat,
                line="hard_field",
                assigned_build="build",
                assigned_tribes=tribes,
                final_line="build",
                final_tribe=final,
                no_tribe_reason=reason,
            )
            for seat, (tribes, final, reason) in enumerate(
                [
                    (["Hedgerow folk"], "Fairies", ""),
                    (["Birds"], "no_tribe", "mixed"),
                    (["Fairies"], "Fairies", ""),
                    ([], "Bog folk", ""),
                ]
            )
        ]
        self.assertEqual(rows[0]["assigned_build"], rows[0]["final_line"])
        self.assertEqual(rows[0]["final_tribe"], "Fairies")
        result = tribe_drift(rows)
        self.assertEqual(result["assigned_tribal_seats"], 3)
        self.assertEqual(result["unassigned_neutral_seats"], 1)
        self.assertEqual(result["different_final_label"], 2)
        self.assertAlmostEqual(result["different_share_assigned"], 2 / 3)
        self.assertEqual(result["different_share_all_noncommitted"], 0.5)
        self.assertEqual(result["other_tribe_majority"], 1)
        self.assertAlmostEqual(result["other_tribe_majority_share_assigned"], 1 / 3)
        unknown = dict(rows[0], seat=9, assigned_build="", assigned_tribes=None)
        self.assertEqual(tribe_drift(rows + [unknown])["unknown_assignment_seats"], 1)
        self.assertEqual(result["no_tribe_reasons"], {"mixed": 1})
        self.assertEqual(result["unassigned_final_tribes"], {"Bog folk": 1})
        with self.assertRaisesRegex(ValueError, "duplicate"):
            tribe_drift(rows + rows[:1])

    def test_changed_analysis_archive_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / "archive.json"
            archive.write_text("{}")
            result = Path(directory) / "result.json"
            result.write_text(json.dumps({"analysis_archive": {"path": str(archive), "sha256": file_sha(archive)}}))
            archive.write_text('{"changed": true}')
            with self.assertRaisesRegex(ValueError, "changed sufficient analysis archive"):
                load_setting(result)


if __name__ == "__main__":
    unittest.main()
