"""Hand-worked fixtures for the deep analyses (tools/league/analysis/deep)."""
import json
import math
from pathlib import Path
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE.parent / "deep"))
from match_data import Stat  # noqa: E402
import common  # noqa: E402
from common import Acc, Combo, Contrast, Side  # noqa: E402
import cardplay  # noqa: E402
import fights  # noqa: E402
import synergy  # noqa: E402
import tempo  # noqa: E402
import run as run_one  # noqa: E402


class Pairs(unittest.TestCase):
    def test_acc_by_hand(self):
        # Pair 0: 1 hit in 2, pair 1: 3 in 2 (a mean, not a rate). v = 4/4 = 1.
        # Residuals (1-2) and (3-2): sum of squares 2; k = 2;
        # half = 1.96 * sqrt(2/1 * 2) / 4 = 0.98.
        a = Acc()
        a.add(1, 3, 2)
        a.add(0, 1, 2)          # out of order on purpose
        r = a.result()
        self.assertEqual((r["mean"], r["count"], r["pairs"]), (1.0, 4, 2))
        self.assertAlmostEqual(r["ci95"][0], 0.02)
        self.assertAlmostEqual(r["ci95"][1], 1.98)
        self.assertTrue(r["thin"])

    def test_acc_matches_stat(self):
        data = [(p, (p * 7) % 5, 1 + p % 3) for p in range(40)]
        s, a = Stat(), Acc()
        for p, x, n in data:
            s.add(p, x, n)
        for p, x, n in reversed(data):
            a.add(p, x, n)
        rs, ra = s.result(), a.result()
        self.assertAlmostEqual(rs["mean"], ra["mean"])
        self.assertAlmostEqual(rs["ci95"][0], ra["ci95"][0])
        self.assertFalse(ra["thin"])

    def test_contrast_by_hand(self):
        # Group a: pair 0 2/2, pair 1 0/2 -> 0.5. Group b: pair 0 0/1, pair 1 1/1 -> 0.5.
        # Influences: pair 0: (2-1)/4 - (0-.5)/2 = 0.5; pair 1: (0-1)/4 - (1-.5)/2 = -0.5.
        # half = 1.96 * sqrt(2 * 0.5) = 1.96.
        c = Contrast()
        c.add(0, 0, 2, 2)
        c.add(1, 0, 0, 2)
        c.add(0, 1, 0, 1)
        c.add(1, 1, 1, 1)
        r = c.result()
        self.assertEqual(r["diff"], 0.0)
        self.assertAlmostEqual(r["ci95"][1], 1.96)

    def test_combo_weights(self):
        c = Combo((1, -1, -1, 1))
        for g, (x, n) in enumerate(((3, 4), (1, 4), (2, 4), (1, 2))):
            c.add(0, g, x, n)
        # .75 - .25 - .5 + .5 = 0.5
        self.assertAlmostEqual(c.estimate()["value"], 0.5)


def side(pair, rnd, cards, score, colour="red", tribe="Mouse", stats=10, opp=1, opp_stats=10):
    s = Side()
    s.game, s.pair, s.round, s.seat = 2 * pair, pair, rnd, 0
    s.colour, s.tribe, s.cards, s.stats, s.score = colour, tribe, tuple(cards), stats, score
    s.opp, s.opp_tribe, s.opp_stats, s.damage, s.board_n, s.opp_n = opp, tribe, opp_stats, 0, len(cards), 1
    return s


class Formulas(unittest.TestCase):
    def test_tenure_by_hand(self):
        class S:
            pair, colour, tribe, place = 0, "red", "Mouse", 1
        turns = {1: {1: ("a", False), 2: ("a", False), 4: ("c", False)},
                 2: {1: ("a", False), 2: ("a", False), 3: ("b", False)},
                 3: {9: ("a", True), 3: ("b", False)}}
        rows = {r["card"] + str(r["fights"]) + r["end"] for r in cardplay.tenure_rows(S, turns)}
        # uids 1 and 2 merge into the new golden 9; c is sold after one fight;
        # b and the golden survive to the last board.
        self.assertEqual(rows, {"a2tripled", "c1left", "b2kept", "a1kept"})

    def test_lift_sign_and_value(self):
        # One stratum, one pair: 4 boards, 3 wins -> baseline .75. Card boards: 2, both won.
        # Lift = 1 - .75 = +.25 (positive = more fights won).
        present = {("k",): {0: [2, 2]}}
        reference = {("k",): {0: [3, 4]}}
        r = cardplay.lift(present, reference, True)
        self.assertAlmostEqual(r["mean"], 0.25)
        # For placement lower is better: card boards placed 1 and 2 against a mean of 3.5.
        r = cardplay.lift({("k",): {0: [3, 2]}}, {("k",): {0: [14, 4]}}, False)
        self.assertAlmostEqual(r["mean"], 2.0)

    def test_fight_lift_is_within_team(self):
        # Red boards all win, blue boards all lose; the card is on half of each.
        # Within each team the card makes no difference, so its lift is 0.
        class D:
            sides = []
        for p in range(4):
            D.sides += [side(p, 5, ["x"], 1.0, "red"), side(p, 5, ["y"], 1.0, "red"),
                        side(p, 5, ["x"], 0.0, "blue"), side(p, 5, ["y"], 0.0, "blue")]
        rows = [r for r in cardplay.fight_lift(D) if r["scope"] == "both" and r["band"] == "all"]
        self.assertEqual({r["card"]: round(r["mean"], 9) for r in rows}, {"x": 0, "y": 0})

    def test_interaction_by_hand(self):
        # Residuals are 0 here because every stratum is the same and we pass
        # cells directly: AB .9, A-only .5, B-only .4, neither .2 -> .9-.5-.4+.2 = .2
        cells = lambda v: {0: [v * 10, 10], 1: [v * 10, 10]}
        r = synergy.interaction(cells(.9), cells(.5), cells(.4), cells(.2))
        self.assertAlmostEqual(r["value"], 0.2)

    def test_synergy_pair_counts(self):
        # Additive cards: A adds .2, B adds .2, no interaction.
        sides = []
        for p in range(20):
            for cards, score in ((("a", "b"), 0.9), (("a",), 0.7), (("b",), 0.7), (("z",), 0.5)):
                sides += [side(p, 8, cards, score) for _ in range(5)]
        class D:
            pass
        D.sides = sides
        old = (synergy.MIN_TOGETHER, synergy.MIN_APART)
        synergy.MIN_TOGETHER = synergy.MIN_APART = 10
        try:
            rows = {(r["a"], r["b"]): r for r in synergy.analyse(D)["pairs"]}
        finally:
            synergy.MIN_TOGETHER, synergy.MIN_APART = old
        self.assertAlmostEqual(rows["a", "b"]["interaction"]["value"], 0.0)
        self.assertAlmostEqual(rows["a", "b"]["excess_over_best_single"]["diff"], 0.2)

    def test_decided_round_and_rank(self):
        # Seat 0 wins. After round 1 it trails (30 < 40), leads from round 2 on.
        hp = {(1, 0): 30, (1, 1): 40, (2, 0): 35, (2, 1): 20, (3, 0): 35, (3, 1): 35, (4, 0): 30, (4, 1): 0}
        g = {"rounds": 4, "hp": hp}
        self.assertEqual(fights.decided_round(g, 0), 2)
        self.assertEqual(fights.hp_rank(g, 0, 1), 2)
        self.assertEqual(fights.hp_rank(g, 0, 3), 1)      # a tie is rank 1
        # Losing the lead later resets the decided round.
        hp[3, 1] = 36
        self.assertEqual(fights.decided_round(g, 0), 4)

    def test_ratio_bucket(self):
        self.assertEqual(fights.ratio_bucket(12, 10), "1-1.25x")
        self.assertEqual(fights.ratio_bucket(15, 10), "1.5-2x")
        self.assertEqual(fights.ratio_bucket(30, 10), "3x+")
        self.assertEqual(fights.ratio_bucket(5, 0), "3x+")

    def test_reach_rounds(self):
        class R:
            def __init__(self, t):
                self.tier = t
        class S:
            rounds = {1: R(1), 2: R(1), 3: R(3), 4: R(3), 5: R(4)}
        self.assertEqual(tempo.reach_rounds(S), {2: 3, 3: 3, 4: 5, 5: None, 6: None})
        self.assertEqual(tempo.tier2_group(None), "never")
        self.assertEqual(tempo.tier2_group(7), "6+")


# ---------------------------------------------------------------------------
# A two-game match on disk, end to end.

def unit(card, slot, golden=False):
    return {"card": card, "golden": golden, "slot": slot, "attack": 2, "health": 3}


def snap(rd, cards, tier, tribe="Mouse", gold_start=5, gold_left=1):
    return {"round": rd, "tribes": {tribe: len(cards)}, "board": [unit(c, i) for i, c in enumerate(cards)],
            "hand": [], "heaps": {}, "counters": {}, "board_attack": 2 * len(cards), "board_health": 3 * len(cards),
            "tier": tier, "gold_start": gold_start, "gold_left": gold_left, "gold_from_cards": 0,
            "triple": False, "golden_gained": False, "slot_buff": False}


class Disk(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=HERE)
        self.addCleanup(self.temp.cleanup)
        p = self.path = Path(self.temp.name)
        (p / "summary.json").write_text(json.dumps(dict(
            schema=1, complete=True, games=2, red="r", blue="b", red_avg_place=4.5, blue_avg_place=4.5,
            gap_red_minus_blue=0, rules_hash="h")))
        (p / "library.json").write_text(json.dumps(
            [dict(id=c, name=c.upper(), tribes=["Mouse"], tier=1, attack=1, health=1, spell=False, token=False)
             for c in ("a", "b", "c")]))
        games, decisions = [], []
        for g in range(2):
            red = {0, 2, 4, 6} if g == 0 else {1, 3, 5, 7}
            seats = []
            for sid in range(8):
                colour = "red" if sid in red else "blue"
                bot = "r" if colour == "red" else "b"
                if sid == 0:
                    rounds = [snap(1, ["a"], 1), snap(2, ["a", "b"], 2, gold_start=9, gold_left=3),
                              snap(3, ["a", "b"], 2)]
                else:
                    rounds = [snap(r, ["c"], 1) for r in (1, 2, 3)]
                seats.append(dict(seat=sid, colour=colour, bot=bot, place=sid + 1, main_tribe="Mouse",
                                  died_round=None, commit_round=None, pivots=[], final_board=rounds[-1]["board"],
                                  rounds=rounds))
            fr = []
            for r in (1, 2, 3):
                fl = [dict(a=0, b=1, winner=None if r == 1 else 0, loser=-2 if r == 1 else 1,
                           damage=0 if r == 1 else 4, result={}, ghost_of=None)]
                fl += [dict(a=2 * k, b=2 * k + 1, winner=2 * k, loser=2 * k + 1, damage=2, result={}, ghost_of=None)
                       for k in (1, 2, 3)]
                fr.append(dict(round=r, fights=fl, players=[dict(seat=s, hp=40 - r * (s % 2), armor=0, alive=True)
                                                            for s in range(8)]))
            games.append(dict(game=g, seed="1", swapped=bool(g), red_seats=sorted(red), rounds=3,
                              round_limit_hit=False, seats=seats, fights=fr))
            c0 = "red" if 0 in red else "blue"
            base = dict(game=g, seat=0, colour=c0, bot="r" if c0 == "red" else "b", by="bot", result="",
                        board_n=1, hand_n=0)
            decisions += [
                dict(base, round=2, step=0, gold=9, tier=1, legal=[{"type": "upgrade"}, {"type": "end_turn"}], chosen=0),
                dict(base, round=2, step=1, gold=3, tier=2, legal=[{"type": "end_turn"}], chosen=0),
                dict(base, round=3, step=0, gold=6, tier=2, legal=[{"type": "buy", "card": "b", "price": 3}], chosen=0),
                dict(base, round=3, step=1, gold=3, tier=2, legal=[{"type": "sell", "slot": 1, "card": "b"}], chosen=0),
                dict(base, round=3, step=2, gold=4, tier=2, legal=[{"type": "sell", "slot": 0, "card": "a"}], chosen=0),
            ]
        (p / "games.jsonl").write_text("".join(json.dumps(g) + "\n" for g in games))
        (p / "decisions.jsonl").write_text("".join(json.dumps(d) + "\n" for d in decisions))

    def test_load_and_run(self):
        deep = common.load(self.path)
        self.assertEqual(deep.coverage, {"decisions": True, "shops": False, "records": False})
        # Upgrade: 9 gold before, 3 at the next decision -> paid 6, waited 1 turn.
        turn = deep.turns[0, 0, 2]
        self.assertEqual(turn.upgrade_paid, [(1, 6)])
        data = tempo.analyse(deep)
        paid = tempo.lookup(data["upgrade_prices"], "paid", scope="both", from_tier=1)
        waited = tempo.lookup(data["upgrade_prices"], "turns_waited", scope="both", from_tier=1)
        self.assertEqual((paid["mean"], paid["count"], waited["mean"]), (6, 2, 1))
        # Seat 0: tier 2 in round 2, place 1. All other seats never level.
        win = tempo.lookup(data["outcome_by_tempo"], "win", scope="both", grouping="tier2_round", group="2")
        self.assertEqual((win["hits"], win["count"]), (2, 2))
        # Draw scores half; seat 0 scores .5 + 1 + 1 over its three fights.
        s0 = [s.score for s in deep.sides if s.seat == 0 and s.game == 0]
        self.assertEqual(s0, [0.5, 1.0, 1.0])
        # Resales: b sold in the turn it was bought, a was not.
        rs = {r["card"]: r for r in cardplay.resales(deep) if r["scope"] == "both"}
        self.assertEqual((rs["b"]["buys"], rs["b"]["sells"], rs["b"]["sold_same_turn_as_a_buy"]), (2, 2, 2))
        self.assertEqual(rs["a"]["sold_same_turn_as_a_buy"], 0)
        out, meta = run_one.run(self.path, self.path / "deep")
        for name in ("meta", "tempo", "cards", "fights", "synergy"):
            json.loads((out / f"{name}.json").read_text())
        self.assertIn("## Tempo and economy", (out / "deep.md").read_text())


if __name__ == "__main__":
    unittest.main()
