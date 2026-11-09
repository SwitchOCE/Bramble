import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPORT_PATH = Path(__file__).resolve().parents[2] / "tools/sim/upset_report.py"
SPEC = importlib.util.spec_from_file_location("upset_report", REPORT_PATH)
REPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(REPORT)


def trial(*, seed="1", orientation=0, winner=0, masked=None, a_alt=None, b_alt=None, coin=None):
    masked = winner if masked is None else masked
    a_alt = winner if a_alt is None else a_alt
    b_alt = winner if b_alt is None else b_alt
    coin = winner if coin is None else coin
    row = {
        "version": 1,
        "fights": 8,
        "a": "board-a",
        "b": "board-b",
        "seed": seed,
        "orientation": orientation,
        "side_board_ids": ["board-a", "board-b"] if orientation == 0 else ["board-b", "board-a"],
        "field_sha256": "1" * 64,
        "plan_sha256": "2" * 64,
        "baseline_input_sha256": "3" * 64,
        "mask_supported": True,
        "mask_unsupported": [],
        "mask_manifest": [{"path": "library.units.scale_answer.mechanics[0]", "kind": "native"}],
        "layouts": {
            name: {"old_to_new": list(range(7)), "pinned_slots": [2], "changed": False}
            for name in ("board-a", "board-b")
        },
        "outcomes": {},
    }
    winners = {
        "intact.original": winner,
        "masked.original": masked,
        "intact.a_alternate": a_alt,
        "intact.b_alternate": b_alt,
        "intact.coin_flipped": coin,
        "masked.a_alternate": masked,
        "masked.b_alternate": masked,
        "masked.coin_flipped": masked,
    }
    for key, outcome in winners.items():
        row["outcomes"][key] = {
            "winner": outcome,
            "result": {"winner": outcome if outcome < 0 or orientation == 0 else 1 - outcome},
            "first_side_original": 0,
            "first_side_used": int(key.endswith("coin_flipped")),
            "first_coin_eligible": True,
        }
    return row


class UpsetReportTests(unittest.TestCase):
    def test_answer_placement_and_coin_causes_overlap(self):
        report = REPORT.upset_report([trial(masked=1, a_alt=1, coin=1)], bootstrap_replicates=40)
        for flag in ("answer_necessary", "placement_necessary", "first_attack_coin_necessary"):
            self.assertEqual(report["attribution"][flag]["count"], 1)
            self.assertEqual(report["attribution"][flag]["denominator_baseline_wins"], 1)
        self.assertEqual(report["attribution"]["unexplained"]["count"], 0)
        self.assertFalse(report["complete_frozen_design"])
        self.assertIn("no population", report["scope"])

    def test_draw_transitions_are_separate_from_winner_reversals(self):
        report = REPORT.upset_report([trial(masked=-1, a_alt=-1, coin=-1)], bootstrap_replicates=0)
        for prefix in ("answer", "placement", "first_attack_coin"):
            self.assertEqual(report["attribution"][f"{prefix}_necessary"]["count"], 0)
            self.assertEqual(report["attribution"][f"{prefix}_draw_transition"]["count"], 1)

    def test_baseline_draws_have_no_winner_to_attribute(self):
        report = REPORT.upset_report([trial(winner=-1)], bootstrap_replicates=0)
        self.assertEqual(report["baseline_draws"], 1)
        self.assertEqual(report["baseline_wins"], 0)
        self.assertTrue(all(item["rate"] is None for item in report["attribution"].values()))

    def test_event_presence_and_large_or_small_stats_do_not_imply_necessity(self):
        row = trial()
        row["lower_stat_winner"] = True
        row["triggered_answer_events"] = 5
        report = REPORT.upset_report([row], bootstrap_replicates=0)
        self.assertEqual(report["attribution"]["answer_necessary"]["count"], 0)
        self.assertEqual(report["attribution"]["unexplained"]["count"], 1)
        self.assertEqual(report["attribution"]["invariant"]["count"], 1)

    def test_unknown_or_inseparable_masks_are_unclassified(self):
        row = trial(masked=1)
        row["mask_supported"] = False
        row["mask_unsupported"] = [{"reason": "shared limit"}]
        report = REPORT.upset_report([row], bootstrap_replicates=0)
        self.assertEqual(report["unsupported_mask_trials"], 1)
        self.assertEqual(report["attribution"]["answer_necessary"]["denominator_baseline_wins"], 0)
        self.assertIsNone(report["per_trial"][0]["flags"]["answer_necessary"])
        self.assertEqual(report["attribution"]["placement_necessary"]["denominator_baseline_wins"], 1)

    def test_original_board_orientation_survives_swapped_sides(self):
        rows = [trial(orientation=orientation, winner=1, masked=0) for orientation in (0, 1)]
        report = REPORT.upset_report(rows, bootstrap_replicates=0)
        self.assertEqual(report["attribution"]["answer_necessary"]["count"], 2)
        self.assertEqual([item["baseline_winner"] for item in report["per_trial"]], [1, 1])

    def test_other_rng_sensitivity_holds_initial_attack_side_fixed(self):
        rows = [trial(seed="1", winner=0), trial(seed="2", winner=1)]
        report = REPORT.upset_report(rows, bootstrap_replicates=0)
        self.assertEqual(report["attribution"]["other_rng_sensitive"]["count"], 2)
        self.assertEqual(report["attribution"]["first_attack_coin_necessary"]["count"], 0)
        for key, outcome in rows[1]["outcomes"].items():
            outcome["first_side_original"] = 1
            outcome["first_side_used"] = 0 if key.endswith("coin_flipped") else 1
        report = REPORT.upset_report(rows, bootstrap_replicates=0)
        self.assertEqual(report["attribution"]["other_rng_sensitive"]["count"], 0)

    def test_shared_board_bootstrap_is_deterministic_and_does_not_resample_fights(self):
        rows = [trial(seed="1", masked=1), trial(seed="2")]
        first = REPORT.upset_report(rows, bootstrap_replicates=100)
        self.assertEqual(first, REPORT.upset_report(copy.deepcopy(rows), bootstrap_replicates=100))
        more_seeds = [
            {**copy.deepcopy(row), "seed": str(int(row["seed"]) + offset)}
            for offset in range(0, 100, 2)
            for row in rows
        ]
        repeated = REPORT.upset_report(more_seeds, bootstrap_replicates=100)
        self.assertEqual(
            first["attribution"]["answer_necessary"]["selected_board_ci95"],
            repeated["attribution"]["answer_necessary"]["selected_board_ci95"],
        )
        self.assertFalse(first["uncertainty"]["fight_trials_resampled"])
        self.assertTrue(first["uncertainty"]["very_low_n"])

    def test_missing_duplicate_or_mixed_evidence_rejected(self):
        with self.assertRaises(ValueError):
            REPORT.upset_report([])
        row = trial()
        with self.assertRaisesRegex(ValueError, "duplicate"):
            REPORT.upset_report([row, row])
        bad = trial(seed="2")
        bad["field_sha256"] = "4" * 64
        with self.assertRaisesRegex(ValueError, "mixed"):
            REPORT.upset_report([row, bad])
        bad = trial()
        del bad["outcomes"]["masked.original"]
        with self.assertRaisesRegex(ValueError, "interventions"):
            REPORT.upset_report([bad])

    def test_moved_pins_or_uncontrolled_coin_changes_rejected(self):
        row = trial()
        row["layouts"]["board-a"]["old_to_new"] = [0, 2, 1, 3, 4, 5, 6]
        with self.assertRaisesRegex(ValueError, "Egg/Nest"):
            REPORT.upset_report([row])
        row = trial()
        row["outcomes"]["intact.coin_flipped"]["first_side_original"] = 1
        with self.assertRaisesRegex(ValueError, "original RNG"):
            REPORT.upset_report([row])

    def test_make_plan_freezes_hash_selected_strata_without_outcomes(self):
        field = {
            "rounds": {
                str(round_number): {
                    "boards": [
                        {"id": f"{round_number}:{index}", "line": line, "unread_result": "ignored"}
                        for index, line in enumerate(("hard", "hard", "a", "a", "b", "b"))
                    ]
                }
                for round_number in (10, 12, 14)
            }
        }
        before = copy.deepcopy(field)
        seeds = [str(index) for index in range(8)]
        plan = REPORT.make_plan(field, "1" * 64, seeds)
        self.assertEqual(
            [(pair["round"], pair["selection_stratum"], pair["a"], pair["b"]) for pair in plan["pairs"]],
            [
                (10, "hard-cross", "10:1", "10:5"),
                (10, "nonhard-cross", "10:2", "10:5"),
                (10, "any-cross", "10:2", "10:4"),
                (12, "hard-cross", "12:0", "12:3"),
                (12, "nonhard-cross", "12:3", "12:5"),
                (12, "any-cross", "12:0", "12:4"),
                (14, "hard-cross", "14:0", "14:2"),
                (14, "nonhard-cross", "14:2", "14:4"),
            ],
        )
        self.assertEqual(field, before)
        self.assertEqual(plan["field_sha256"], "1" * 64)
        self.assertEqual(plan["seeds"], seeds)
        self.assertEqual((plan["orientations"], plan["expected_trials"], plan["expected_fights"]), (2, 128, 1024))
        for round_data in field["rounds"].values():
            round_data["boards"].reverse()
            for board in round_data["boards"]:
                board["unread_result"] = {"winner": "changed; never used"}
        reordered = REPORT.make_plan(field, "1" * 64, seeds)
        self.assertEqual(
            [(pair["round"], sorted((pair["a"], pair["b"]))) for pair in plan["pairs"]],
            [(pair["round"], sorted((pair["a"], pair["b"]))) for pair in reordered["pairs"]],
        )
        seeds[0] = "100"
        self.assertEqual(plan["seeds"][0], "0", "plan owns its frozen seed list")

    def test_make_plan_rejects_invalid_seeds_hash_and_inadequate_strata(self):
        seeds = [str(index) for index in range(8)]
        for invalid in (seeds[:-1], ["1"] * 8, ["01", *seeds[1:]], [2**64, *seeds[1:]]):
            with self.subTest(seeds=invalid), self.assertRaises(ValueError):
                REPORT.make_plan({}, "1" * 64, invalid)
        with self.assertRaisesRegex(ValueError, "SHA256"):
            REPORT.make_plan({}, "not-a-hash", seeds)
        with self.assertRaisesRegex(ValueError, "rounds 10"):
            REPORT.make_plan({}, "1" * 64, seeds)
        field = {"rounds": {"10": {"boards": [{"id": "a", "line": "tribal"}, {"id": "b", "line": "other"}]}}}
        with self.assertRaisesRegex(ValueError, "insufficient distinct hard-cross"):
            REPORT.make_plan(field, "1" * 64, seeds)

    def test_complete_design_and_cli(self):
        rows = []
        for pair in range(8):
            for seed in range(8):
                for orientation in (0, 1):
                    row = trial(seed=str(seed), orientation=orientation)
                    a, b = f"a-{pair}", f"b-{pair}"
                    row.update(a=a, b=b, side_board_ids=[a, b] if orientation == 0 else [b, a])
                    row["layouts"] = dict(zip((a, b), row["layouts"].values(), strict=True))
                    rows.append(row)
        report = REPORT.upset_report(rows, bootstrap_replicates=0)
        self.assertTrue(report["complete_frozen_design"])
        self.assertEqual(report["fights"], 1024)
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory) / "trials.jsonl", Path(directory) / "report.json"
            source.write_text("\n".join(json.dumps(row) for row in rows))
            result = subprocess.run(
                [sys.executable, str(REPORT_PATH), str(source), "--out", str(output), "--bootstrap-replicates", "0"],
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(output.read_text()), report)


if __name__ == "__main__":
    unittest.main()
