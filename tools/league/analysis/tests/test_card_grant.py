from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import card_grant
from card_without import Refused
from test_card_without import write_match


def granted(card, round_=7, keep=3, held=(7, 8, 9), left=(), displaced="acorn", given=True):
    """The live seat's `grant` line, as `ghost-match --grant` writes it."""
    def line(g):
        return {"grant": dict(card=card, round=round_, keep=keep, granted=given,
                              reason=None if given else "out of the game", slot=2,
                              displaced=displaced if given else None,
                              held_rounds=len(held) if given else 0,
                              held=list(held) if given else [], left=list(left),
                              merged_round=None, hidden=4)}
    return line


def grant_match(folder, places, card, **kw):
    round_, keep = kw.pop("round_", 7), kw.pop("keep", 3)
    return write_match(folder, places, extra={"grant": dict(card=card, round=round_, keep=keep)},
                       seat_extra=granted(card, round_, keep, **kw))


class CardGrant(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.dir = Path(scratch.name)
        self.base = write_match(self.dir / "base", [4, 4, 4, 4, 4, 4])
        self.ref = grant_match(self.dir / "ref", [3, 4, 3, 4, 3, 4], "beech")

    def rows(self, *cards, controls=()):
        return {(r["card"], r["colour"]): r
                for r in card_grant.table(self.base, self.ref, cards, controls)}

    def test_better_than_nothing_and_than_the_reference(self):
        card = grant_match(self.dir / "card", [1, 4, 2, 4, 1, 5], "acorn")
        rows = self.rows(card)
        ref = rows["beech (reference)", "red"]
        self.assertEqual((ref["better_than_nothing"], ref["reading"]), (1, "reference"))
        self.assertIsNone(ref["better_than_reference"])
        red = rows["acorn", "red"]
        self.assertAlmostEqual(red["better_than_nothing"], (3 + 2 + 3) / 3)
        self.assertAlmostEqual(red["better_than_reference"], (2 + 1 + 2) / 3)
        self.assertGreater(red["btr_low"], 0)
        self.assertEqual(red["reading"], "stronger than the reference")
        self.assertEqual((red["granted"], red["held_rounds_mean"], red["kept_through_share"]),
                         (3, 3, 1))
        self.assertEqual(red["displaced_share"], 1)
        blue = rows["acorn", "blue"]
        self.assertAlmostEqual(blue["better_than_reference"], -1 / 3)
        self.assertEqual(blue["reading"], "no clear difference from the reference")

    def test_weaker_and_not_held_readings(self):
        weak = grant_match(self.dir / "weak", [5, 6, 6, 6, 5, 7], "acorn")
        self.assertEqual(self.rows(weak)["acorn", "red"]["reading"], "weaker than the reference")
        sold = grant_match(self.dir / "sold", [5, 6, 6, 6, 5, 7], "acorn", held=(7,),
                           left=[{"round": 8, "how": "sell", "to": "gone"}])
        row = self.rows(sold)["acorn", "red"]
        self.assertEqual(row["kept_through_share"], 0)
        self.assertEqual(row["reading"], "not held through the keep: says little")
        self.assertEqual(row["sold_after_keep_share"], 0)

    def test_games_without_a_copy_do_not_count(self):
        none = grant_match(self.dir / "none", [8, 8, 8, 8, 8, 8], "acorn", given=False)
        row = self.rows(none)["acorn", "red"]
        self.assertEqual((row["games"], row["granted"]), (3, 0))
        self.assertIsNone(row["better_than_nothing"])
        self.assertEqual(row["reading"], "not handed over")

    def test_control_rows(self):
        rerun = write_match(self.dir / "rerun", [4, 4, 5, 4, 4, 4])
        row = self.rows(controls=[rerun])["(control)", "red"]
        self.assertAlmostEqual(row["better_than_nothing"], -1 / 3)

    def test_refuses_what_does_not_pair(self):
        cases = {
            "round": dict(round_=8),
            "keep": dict(keep=2),
        }
        for name, kw in cases.items():
            card = grant_match(self.dir / name, [4] * 6, "acorn", **kw)
            with self.assertRaises(Refused, msg=name):
                card_grant.table(self.base, self.ref, [card])
        twice = grant_match(self.dir / "twice", [4] * 6, "beech")
        with self.assertRaises(Refused):
            card_grant.table(self.base, self.ref, [twice])
        plain = write_match(self.dir / "plain", [4] * 6)
        with self.assertRaises(Refused):
            card_grant.table(self.base, self.ref, [plain])
        other_secret = write_match(self.dir / "secret", [4] * 6, secret="cd" * 32,
                                   extra={"grant": dict(card="acorn", round=7, keep=3)},
                                   seat_extra=granted("acorn"))
        with self.assertRaises(Refused):
            card_grant.table(self.base, self.ref, [other_secret])
        trial = write_match(self.dir / "trial", [4] * 6,
                            extra={"grant": dict(card="acorn", round=7, keep=3),
                                   "trial_rules": {"field_rules_hash": "r" * 64}},
                            seat_extra=granted("acorn"))
        with self.assertRaises(Refused):
            card_grant.table(self.base, self.ref, [trial])
        with self.assertRaises(Refused):
            card_grant.table(self.ref, self.ref, [])
        with self.assertRaises(Refused):
            card_grant.table(self.base, self.ref, [], [self.ref])

    def test_a_bot_that_banks_gold_while_holding_the_copy_says_little(self):
        def stalled(g):
            line = granted("acorn")(g)
            line["rounds"] = [dict(round=r, gold_left=20, hand=["x"] * 7) for r in (7, 8, 9)]
            return line
        base = write_match(self.dir / "base2", [4] * 6, seat_extra=lambda g: {"rounds": [
            dict(round=r, gold_left=2, hand=["x"]) for r in (7, 8, 9)]})
        card = write_match(self.dir / "stall", [6, 4, 7, 4, 6, 4],
                           extra={"grant": dict(card="acorn", round=7, keep=3)},
                           seat_extra=stalled)
        rows = {(r["card"], r["colour"]): r for r in card_grant.table(base, self.ref, [card])}
        red = rows["acorn", "red"]
        self.assertEqual((red["extra_gold_in_keep"], red["extra_hand_in_keep"]), (18, 6))
        self.assertEqual(red["reading"], "the bot stalled while holding it: says little")
        self.assertIsNone(rows["beech (reference)", "red"]["extra_gold_in_keep"])

    def test_kept_through_ignores_rounds_after_the_seat_is_out(self):
        seat = {"died_round": 8, "grant": dict(granted=True, round=7, keep=3, held=[7, 8])}
        self.assertTrue(card_grant.kept_through(seat, 12))
        seat["died_round"] = None
        self.assertFalse(card_grant.kept_through(seat, 12))

    def test_main_writes_csv_and_exits_2_on_refusal(self):
        card = grant_match(self.dir / "card", [1, 4, 2, 4, 1, 5], "acorn")
        out = self.dir / "out.csv"
        self.assertEqual(card_grant.main([str(self.base), str(card), "--reference",
                                          str(self.ref), "--out", str(out)]), 0)
        lines = out.read_text().splitlines()
        self.assertEqual(lines[0].split(",")[:3], ["card", "round", "keep"])
        self.assertEqual(len(lines), 5)
        self.assertEqual(card_grant.main([str(self.base), "--reference", str(self.base)]), 2)


if __name__ == "__main__":
    unittest.main()
