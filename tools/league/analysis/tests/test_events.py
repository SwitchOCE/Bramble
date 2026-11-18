"""Event summaries from a hand-made two-pair match."""

from contextlib import redirect_stdout
import gzip
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import events


class EventAnalysisTest(unittest.TestCase):
    def test_rates_by_seed_pair_and_zero_event_exposures(self):
        gorger = {"card": "gorger", "uid": 14}
        glutton = {"card": "granary-glutton", "uid": 15}
        colour = {"card": "colour-sergeant", "uid": 24}
        major = {"card": "regimental-sergeant-major", "uid": 25}
        second_major = {"card": "regimental-sergeant-major", "uid": 26}
        padre = {"card": "padre", "uid": 27}
        recruit = {"card": "green-recruit", "tier": 1}
        relic_seeker = {"card": "relic-seeker", "tier": 2}

        def row(kind, game=0, round_no=3, seat=0, **fields):
            return dict(type=kind, game=game, round=round_no, seat=seat, **fields)

        def amount(attack, health):
            return {"attack": attack, "health": health}

        rows = [
            row("unit_round", unit=gorger),
            row("unit_round", unit=glutton),
            row("eat", eater=gorger, eaten=recruit, gain=amount(4, 2)),
            row("sale", rounds_on_board=2, fed=[{"type": "eat"}]),
            row("sale", rounds_on_board=0, fed=[]),
            row("unit_round", round_no=4, unit=gorger),
            row("unit_round", game=1, unit=colour),
            row("unit_round", game=1, unit=major),
            row("unit_round", game=1, unit=second_major),
            row("slot_growth", game=1, source=colour, amount=amount(6, 6),
                amplification={"amount": amount(3, 3), "sources": [major, second_major]}),
            row("slot_growth", game=1, source=padre, amount=amount(5, 6), ghost=True),
            row("unit_round", game=2, unit=gorger),
            row("unit_round", game=2, round_no=4, unit=glutton),
            row("eat", game=2, round_no=4, eater=glutton, eaten=relic_seeker, gain=amount(2, 6)),
            row("sale", game=2, round_no=4, rounds_on_board=4, fed=[{"type": "eat"}]),
            row("slot_growth", game=2, source=padre, amount=amount(1, 2)),
        ]

        with tempfile.TemporaryDirectory(dir=Path.cwd()) as tmp:
            path = Path(tmp)
            (path / "summary.json").write_text(json.dumps({"schema": 1, "complete": True, "games": 4}))
            (path / "library.json").write_text(json.dumps([
                {"id": "green-recruit", "name": "Green Recruit", "tribes": [], "spell": False},
                {"id": "relic-seeker", "name": "Relic Seeker", "tribes": [], "spell": False},
                {"id": "padre", "name": "Padre", "tribes": [], "spell": False},
            ]))
            with (path / "games.jsonl").open("w") as output:
                for game in range(4):
                    red = list(range(4 * (game % 2), 4 * (game % 2) + 4))
                    line = dict(game=game, swapped=bool(game % 2), red_seats=red, rounds=4,
                                seats=[dict(seat=seat, colour="red" if seat in red else "blue")
                                       for seat in range(8)])
                    print(json.dumps(line), file=output)
            with gzip.open(path / "events.jsonl.gz", "wt") as output:
                for event in rows:
                    print(json.dumps(event), file=output)
            output = io.StringIO()
            with redirect_stdout(output):
                events.main([str(path)])
            report = json.loads((path / "events.json").read_text())

        self.assertIn("| both | 0.50 [0.50, 0.50] (4) |", output.getvalue())
        self.assertEqual(report["seed_pairs"], 2)
        red, blue, both = (report["scopes"][scope] for scope in ("red", "blue", "both"))
        self.assertEqual(both["eats_per_game"],
                         dict(mean=0.5, count=4, pairs=2, ci95=[0.5, 0.5], total=2))
        self.assertEqual(red["fed_sales"]["hits"], 2)
        self.assertEqual(red["fed_sales"]["count"], 3)
        self.assertEqual(red["fed_sales"]["pairs"], 2)
        self.assertIsNone(blue["fed_sales"]["rate"])
        self.assertEqual(both["stats_per_eat"]["attack"]["mean"], 3)
        self.assertEqual(both["stats_per_eat"]["health"]["mean"], 4)
        self.assertEqual(both["by_round"]["3"]["stats_per_eat"]["attack"]["mean"], 4)
        self.assertEqual(both["by_round"]["4"]["stats_per_eat"]["health"]["mean"], 6)
        self.assertIsNone(both["by_round"]["1"]["stats_per_eat"]["total"]["mean"])
        age = both["rounds_on_board_before_sale"]
        self.assertEqual((age["fed"]["mean"], age["fed"]["count"]), (3, 2))
        self.assertEqual((age["unfed"]["mean"], age["unfed"]["count"]), (0, 1))

        diet = both["eaten"]
        self.assertEqual(diet["top_15_cards"], ["green-recruit", "relic-seeker"])
        self.assertEqual(diet["by_tier"]["1"]["hits"], 1)
        self.assertEqual(diet["by_tier"]["2"]["count"], 2)
        self.assertEqual(diet["by_card"]["green-recruit"]["name"], "Green Recruit")
        self.assertEqual(diet["by_card"]["green-recruit"]["pairs"], 2)
        self.assertIsNotNone(diet["by_card"]["green-recruit"]["ci95"])
        self.assertEqual(blue["eaten"]["top_15_cards"], [])

        source_growth = both["slot_growth_by_source"]
        self.assertEqual(source_growth["padre"]["live"]["total"]["total"], 3)
        self.assertEqual(source_growth["padre"]["ghost"]["total"]["total"], 11)
        self.assertEqual(blue["slot_growth_by_source"]["padre"]["ghost"]["attack"]["count"], 1)
        self.assertEqual(source_growth["colour-sergeant"]["live"]["total"]["total"], 12)
        for text in ("### What gets eaten by tier", "| Green Recruit | 1 |",
                     "### Mean stats gained per eat by round", "### Rounds on board before sale",
                     "| Padre | Ghost | — (0) | 5 / 6 (1) | 5 / 6 (1) |"):
            self.assertIn(text, output.getvalue())

        gorger = red["eaters"]["gorger"]["by_round"]
        self.assertEqual(gorger["3"]["eats_per_unit_round"]["mean"], 0.5)
        self.assertEqual(gorger["3"]["eats_per_unit_round"]["pairs"], 2)
        self.assertEqual(gorger["3"]["eats_per_game"]["mean"], 0.25)
        self.assertEqual(gorger["4"]["eats_per_unit_round"]["mean"], 0)
        self.assertIsNone(gorger["2"]["eats_per_unit_round"]["mean"])
        glutton = red["eaters"]["granary-glutton"]["by_round"]
        self.assertEqual(glutton["3"]["eats_per_unit_round"]["mean"], 0)
        self.assertEqual(glutton["4"]["eats_per_unit_round"]["mean"], 1)

        colour_stats = blue["sergeants"]["colour-sergeant"]["growth_per_fight_round"]
        self.assertEqual(colour_stats["direct"]["total"]["mean"], 6)
        major_stats = blue["sergeants"]["regimental-sergeant-major"]["growth_per_fight_round"]
        self.assertEqual(major_stats["amplified"]["total"]["count"], 2)
        self.assertEqual(major_stats["amplified"]["total"]["mean"], 3)
        self.assertEqual(major_stats["amplified"]["total"]["total"], 6)
        self.assertIsNone(major_stats["amplified"]["total"]["ci95"])

    def test_eat_without_observed_unit_is_an_error(self):
        event = {"type": "eat", "round": 2, "seat": 1,
                 "eater": {"card": "gorger", "uid": 1}, "eaten": {"card": "hopper", "tier": 1},
                 "gain": {"attack": 1, "health": 1}}
        with self.assertRaisesRegex(ValueError, "missing a unit-round observation"):
            events.scope_measures(events.Measures(), 0, "red", 2, [event], {1})


if __name__ == "__main__":
    unittest.main()
