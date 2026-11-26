import hashlib
import json
from pathlib import Path
import shutil
import stat
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import card_without
import card_without_run

SEEDS = b"11\n12\n13\n"


def write_match(folder, places, without=None, bought=(), secret="ab" * 32, seeds=SEEDS,
                runs=None, red="red", rules="r" * 64, extra=None, seat_extra=None):
    """A minimal ghost-match folder: games alternate red (even) and blue (odd) in seat 0.
    `extra` adds summary.json keys; `seat_extra(game)` adds keys to the live seat's line."""
    folder = Path(folder)
    (folder / "private").mkdir(parents=True, exist_ok=True)
    (folder / "private/secret.txt").write_text(secret + "\n")
    summary = dict(schema=1, complete=True, rules_hash=rules,
                   seeds_sha256=hashlib.sha256(seeds).hexdigest(), games=len(places),
                   red=red, blue="blue", red_label=red, blue_label="blue", clock_ms=1000,
                   content="all", mode="async")
    if without:
        summary["without"] = list(without)
    summary.update(extra or {})
    (folder / "summary.json").write_text(json.dumps(summary))
    (folder / "library.json").write_text(json.dumps([
        dict(id="acorn", tribes=["Mouse"], spell=False, token=False),
        dict(id="sp_x", tribes=[], spell=True, token=False)]))
    games, shops = [], []
    for g, place in enumerate(places):
        colour = "blue" if g % 2 else "red"
        bot = "blue" if g % 2 else red
        games.append(dict(game=g, seed=str(11 + g // 2), swapped=bool(g % 2),
                          red_seats=[] if g % 2 else [0], mode="async",
                          runs=(runs or {}).get(g, [f"run-{g // 2}-{i}" for i in range(7)]),
                          rounds=12,
                          seats=[dict(seat=0, colour=colour, bot=bot, place=place,
                                      main_tribe=None, **(seat_extra(g) if seat_extra else {}))]))
        shops.append(dict(game=g, seat=0, colour=colour, bot=bot, round=1,
                          bought=[dict(card="acorn", spell=False, index=0)] if g in bought
                          else []))
    for name, rows in (("games", games), ("shops", shops)):
        (folder / f"{name}.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
    return folder


class CardWithout(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        self.dir = Path(scratch.name)
        self.places = [1, 2, 3, 4, 5, 6]
        self.base = write_match(self.dir / "base", self.places, bought={0, 2, 3})

    def rows(self, *others, controls=()):
        return {(r["card"], r["colour"]): r
                for r in card_without.table(self.base, others, controls)}

    def test_the_same_places_read_zero_with_a_zero_interval(self):
        same = write_match(self.dir / "same", self.places, without=["acorn"])
        rows = self.rows(same)
        for colour in ("red", "blue"):
            row = rows["acorn", colour]
            self.assertEqual((row["diff_mean"], row["ci95_low"], row["ci95_high"]), (0, 0, 0))
            self.assertEqual((row["games"], row["seed_lines"]), (3, 3))
        self.assertEqual(rows["acorn", "red"]["bought_games"], 2)  # games 0 and 2
        self.assertEqual(rows["acorn", "blue"]["bought_games"], 1)  # game 3
        self.assertTrue(rows["acorn", "red"]["too_few"])
        self.assertFalse(rows["acorn", "red"]["flag"])

    def test_paired_difference_is_without_minus_with_by_game(self):
        worse = write_match(self.dir / "worse", [3, 2, 4, 4, 8, 6], without=["acorn"])
        red = self.rows(worse)["acorn", "red"]
        self.assertAlmostEqual(red["place_with"], 3)
        self.assertAlmostEqual(red["place_without"], 5)
        self.assertAlmostEqual(red["diff_mean"], 2)  # (2 + 1 + 3) / 3
        self.assertLess(red["ci95_low"], 2)
        self.assertGreater(red["ci95_high"], 2)
        blue = self.rows(worse)["acorn", "blue"]
        self.assertEqual((blue["diff_mean"], blue["ci95_low"]), (0, 0))

    def test_a_control_rerun_has_no_buy_count_and_no_flag(self):
        rerun = write_match(self.dir / "rerun", [1, 2, 3, 4, 5, 7])
        row = self.rows(controls=[rerun])["(control)", "blue"]
        self.assertAlmostEqual(row["diff_mean"], 1 / 3)
        self.assertIsNone(row["bought_games"])
        self.assertFalse(row["flag"])

    def test_refuses_matches_that_are_not_the_same_match(self):
        cases = {
            "seeds": dict(seeds=b"11\n12\n14\n"),
            "secret": dict(secret="cd" * 32),
            "bots": dict(red="other"),
            "rules": dict(rules="s" * 64),
            "runs": dict(runs={4: ["elsewhere"] * 7}),
        }
        for name, change in cases.items():
            other = write_match(self.dir / name, self.places, without=["acorn"], **change)
            with self.assertRaises(card_without.Refused, msg=name):
                card_without.table(self.base, [other])
        fewer = write_match(self.dir / "fewer", self.places[:4], without=["acorn"])
        with self.assertRaises(card_without.Refused):
            card_without.table(self.base, [fewer])
        nothing_left_out = write_match(self.dir / "plain", self.places)
        with self.assertRaises(card_without.Refused):
            card_without.table(self.base, [nothing_left_out])
        with self.assertRaises(card_without.Refused):
            card_without.table(nothing_left_out, [], [nothing_left_out])
        one = write_match(self.dir / "one", self.places, without=["acorn"])
        two = write_match(self.dir / "two", self.places, without=["acorn"])
        with self.assertRaises(card_without.Refused):
            card_without.table(self.base, [one, two])

    def test_refuses_handed_over_and_trial_matches(self):
        for key, value in (("grant", {"card": "acorn", "round": 3, "keep": 1}),
                           ("trial_rules", {"field_rules_hash": "r" * 64})):
            other = write_match(self.dir / key, self.places, without=["acorn"], extra={key: value})
            with self.assertRaises(card_without.Refused, msg=key):
                card_without.table(self.base, [other])
            rerun = write_match(self.dir / f"{key}-rerun", self.places, extra={key: value})
            with self.assertRaises(card_without.Refused, msg=key):
                card_without.table(self.base, [], [rerun])

    def test_pairs_inside_one_trial_and_refuses_across_trials(self):
        trial = {"field_rules_hash": "r" * 64, "card_data": "/scratch/a"}
        base = write_match(self.dir / "t-base", self.places, bought={0, 2, 3},
                           extra={"trial_rules": trial})
        other = write_match(self.dir / "t-out", [2, 2, 3, 4, 5, 6], without=["acorn"],
                            extra={"trial_rules": trial})
        rows = {r["colour"]: r for r in card_without.table(base, [other])}
        self.assertAlmostEqual(rows["red"]["diff_mean"], 1 / 3)
        elsewhere = write_match(self.dir / "t-else", self.places, without=["acorn"],
                                extra={"trial_rules": dict(trial, card_data="/scratch/b")})
        plain = write_match(self.dir / "t-plain", self.places, without=["acorn"])
        for wrong in (elsewhere, plain):
            with self.assertRaises(card_without.Refused):
                card_without.table(base, [wrong])

    def test_main_exits_2_on_refusal(self):
        other = write_match(self.dir / "o", self.places, without=["acorn"], secret="ef" * 32)
        self.assertEqual(card_without.main([str(self.base), str(other)]), 2)


FAKE_LEAGUE = """#!/usr/bin/env python3
import sys
sys.path.insert(0, {tests!r})
from test_card_without import write_match
args = sys.argv[1:]
get = lambda name: args[args.index("--" + name) + 1]
assert "--no-records" in args and "--no-decisions" in args, args
with open({calls!r}, "a") as f:
    f.write(get("without") + "\\n")
trial = {{"card_data": get("repo-root")}} if "--trial-rules" in args else None
write_match(get("out"), {places!r}, without=[get("without")], secret=get("secret"),
            extra={{"trial_rules": trial}} if trial else None)
"""


class Runner(unittest.TestCase):
    def test_plays_each_card_once_and_skips_finished_ones(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        d = Path(scratch.name)
        places = [1, 2, 3, 4, 5, 6]
        base = write_match(d / "base", places)
        seeds = d / "seeds.txt"
        seeds.write_bytes(SEEDS)
        calls = d / "calls.txt"
        league = d / "league"
        league.write_text(FAKE_LEAGUE.format(tests=str(Path(__file__).parent),
                                             calls=str(calls), places=places))
        league.chmod(league.stat().st_mode | stat.S_IEXEC)
        argv = [str(base), str(d / "out"), "acorn", "beech", "--field", "f",
                "--seeds", str(seeds), "--league", str(league), "--timeout", "60"]
        self.assertEqual(card_without_run.main(argv), 0)
        self.assertEqual(card_without_run.main(argv), 0)
        self.assertEqual(calls.read_text().split(), ["acorn", "beech"])
        rows = card_without.table(base, [d / "out/acorn", d / "out/beech"])
        self.assertEqual({r["diff_mean"] for r in rows}, {0})
        wrong = d / "wrong.txt"
        wrong.write_bytes(b"99\n")
        self.assertEqual(card_without_run.main([str(wrong) if a == str(seeds) else a for a in argv]), 2)
        shutil.rmtree(d / "out/beech")
        (d / "out/beech").mkdir()
        self.assertEqual(card_without_run.main(argv), 0)
        self.assertEqual(calls.read_text().split(), ["acorn", "beech", "beech"])


if __name__ == "__main__":
    unittest.main()

    def test_a_trial_baseline_is_replayed_on_its_own_card_data(self):
        scratch = tempfile.TemporaryDirectory()
        self.addCleanup(scratch.cleanup)
        d = Path(scratch.name)
        places = [1, 2, 3, 4, 5, 6]
        base = write_match(d / "base", places, extra={"trial_rules": {"card_data": "/scratch/a"}})
        seeds = d / "seeds.txt"
        seeds.write_bytes(SEEDS)
        league = d / "league"
        league.write_text(FAKE_LEAGUE.format(tests=str(Path(__file__).parent),
                                             calls=str(d / "calls.txt"), places=places))
        league.chmod(league.stat().st_mode | stat.S_IEXEC)
        argv = [str(base), str(d / "out"), "acorn", "--field", "f", "--seeds", str(seeds),
                "--league", str(league), "--timeout", "60"]
        self.assertEqual(card_without_run.main(argv), 0)
        self.assertEqual(card_without.table(base, [d / "out/acorn"])[0]["diff_mean"], 0)

