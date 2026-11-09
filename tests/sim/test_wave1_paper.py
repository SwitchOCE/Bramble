import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools/sim"))
from wave1_paper import (
    MODEL_DIR,
    ROOT,
    _model,
    _timing_reconciled_birds,
    _timing_reconciled_fairies,
    build_paper_reference,
)


class Wave1PaperTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reference = build_paper_reference()

    def test_original_bird_known_answers_match_the_archived_output(self):
        lines = self.reference["authored_paper_pre_start"]
        self.assertEqual(
            [lines["birds_homecoming"][str(r)]["pre_start"] for r in (8, 10, 12, 14)], [96, 240, 615, 1275]
        )
        self.assertEqual([lines["birds_tempo"][str(r)]["pre_start"] for r in (8, 10, 12, 14)], [106, 159, 361, 894])
        archived = (MODEL_DIR / "birds-pass3-model.out.txt").read_text()
        self.assertIn("R12 615", archived)

    def test_fairy_known_pre_start_figures_remove_the_twin_and_wisps(self):
        lines = self.reference["authored_paper_pre_start"]
        self.assertEqual([lines["fairies_ring"][str(r)]["pre_start"] for r in (8, 10, 12, 14)], [92, 275, 530, 1410])
        self.assertEqual([lines["fairies_court"][str(r)]["pre_start"] for r in (8, 10, 12, 14)], [107, 389, 945, 1325])
        for name in ("fairies_ring", "fairies_court"):
            for number in (8, 10, 12, 14):
                row = lines[name][str(number)]
                self.assertAlmostEqual(
                    row["pre_start"] + row["removed_start_effect_stats"],
                    row["paper_combat_including_twin_and_wisps"],
                )
        self.assertGreater(lines["fairies_ring"]["12"]["removed_start_effect_stats"], 0)
        self.assertGreater(lines["fairies_court"]["12"]["removed_start_effect_stats"], 0)

    def test_fetch_dial_changes_only_post_start_paper_figures(self):
        rates = dict(self.reference["rates"], fairies_fetch_share=1.0)
        full = build_paper_reference(rates)["authored_paper_pre_start"]["fairies_ring"]["12"]
        half = self.reference["authored_paper_pre_start"]["fairies_ring"]["12"]
        self.assertEqual(full["pre_start"], half["pre_start"])
        self.assertGreater(full["paper_combat_including_twin_and_wisps"], half["paper_combat_including_twin_and_wisps"])

    def test_birds_printed_board_already_excludes_the_sky(self):
        row = self.reference["authored_paper_pre_start"]["birds_homecoming"]["12"]
        self.assertEqual(row["pre_start"], 615)
        self.assertEqual(row["sky_excluded"], 207)
        self.assertEqual(row["paper_printed_board"], row["pre_start"])

    def test_mapped_dials_are_explicit_and_unparameterized_changes_fail(self):
        rates = self.reference["rates"]
        self.assertEqual(self.reference["parameters"]["fairies"]["fetch"], rates["fairies_fetch_share"])
        self.assertEqual(self.reference["parameters"]["fairies"]["g"], 1 / 3)
        with self.assertRaisesRegex(ValueError, "no parameter"):
            build_paper_reference(dict(rates, fairies_silky_growth=2))
        with self.assertRaisesRegex(ValueError, "no parameter"):
            build_paper_reference(dict(rates, birds_golden_egg_multiplier=3))

    def test_reconciliation_is_a_distinct_named_diagnostic(self):
        original = self.reference["authored_paper_pre_start"]
        translated = self.reference["built_timing_reconciliation"]
        self.assertEqual(original["birds_homecoming"]["12"]["pre_start"], 615)
        self.assertEqual(translated["birds_homecoming"]["12"]["pre_start"], 551)
        self.assertEqual(original["fairies_court"]["8"]["pre_start"], 107)
        self.assertEqual(translated["fairies_court"]["8"]["pre_start"], 165)
        self.assertEqual(len(self.reference["intentional_timing_differences"]), 2)

    def test_built_swallow_trip_translation_reads_the_live_duration_dial(self):
        parameters = self.reference["parameters"]["birds"]
        model = _model("birds", parameters)
        original = model.Game(model.LINES["A"])
        original.t = 4
        bird = model.Unit("Swallow")
        original.fly(bird)
        self.assertEqual(bird.due, 6)
        _timing_reconciled_birds(model, self.reference["rates"])
        translated = model.Game(model.LINES["A"])
        translated.t = 4
        translated.fly(bird)
        self.assertEqual(bird.due, 5)

    def test_built_cluricaun_grows_on_tier_up_once_for_the_strongest_copy(self):
        parameters = self.reference["parameters"]["fairies"]
        model = _model("fairies", parameters)
        _timing_reconciled_fairies(model, self.reference["rates"])
        game = model.Game(dict(model.P))
        game.gold = 100
        game.b["F1"] = model.Unit("clur")
        game.b["F2"] = model.Unit("clur", golden=True)
        game.ring = dict.fromkeys(model.SLOTS, 1)
        for _ in range(6):
            game.end_of_turn()
        self.assertEqual(game.S, 1, "the authored periodic trigger is suppressed")
        game.act(("tier",))
        self.assertEqual(game.S, 3, "strongest copy grows twice, no additive copy trigger")
        game.end_of_turn()
        self.assertEqual(game.S, 3)

    def test_models_and_live_rates_are_read_without_mutating_argv_or_source(self):
        before = list(sys.argv)
        sources = {p: p.read_bytes() for p in MODEL_DIR.glob("*-pass3-model.py")}
        actual = build_paper_reference()
        self.assertEqual(sys.argv, before)
        self.assertEqual(actual["rates"], json.loads((ROOT / "content/pass3/rates.json").read_text()))
        self.assertTrue(all(path.read_bytes() == data for path, data in sources.items()))
        self.assertEqual(actual, self.reference)


if __name__ == "__main__":
    unittest.main()
