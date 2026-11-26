#!/usr/bin/env python3
"""Handed a copy: a card's worth to each bot when it is given to the bot, not bought.

    python3 card_grant.py BASELINE --reference REF CARD [CARD ...] [--control RERUN] [--out FILE.csv]

BASELINE is a `league ghost-match` folder with nothing handed over. REF and each CARD are the
same match played with `--grant <card>@<round> --keep <rounds>` (same seeds, secret, games,
bots and field runs, and the same round and keep): REF hands over a reference card of the same
tier that the bots do buy, each CARD the card under test. Writes one CSV row per match per bot
(stdout without `--out`): places better with the copy than with nothing, and than with the
reference, with 95% intervals over seed lines, and how long the copy stayed on the board.
`--control` takes a second run of the baseline; its rows (card `(control)`) show how far the
bots' own CPU-clock noise moves places. The definition is fixed in
docs/workstreams/card-power/definitions.md, "Handed a copy".
"""
import argparse
import csv
import sys
from pathlib import Path

from card_without import CONTROL, SAME, Refused, live_games, refuse_other_tools, secret
from match_data import Match, Stat

# definitions.md, "Handed a copy": the reading lines, fixed before any result was read.
LINE_PLACES = 0.3
HELD_SHARE = 0.8
# Set AFTER the first results were read (definitions.md, "Changes"): a bot that cannot sell a
# card it does not want fills its hand and banks gold instead of playing on. Gold left at the
# end of the keep rounds, above the same games with nothing handed over.
STALL_GOLD = 3

COLUMNS = ("card", "round", "keep", "bot", "colour", "games", "granted",
           "better_than_nothing", "btn_low", "btn_high",
           "better_than_reference", "btr_low", "btr_high", "seed_lines",
           "held_rounds_mean", "kept_through_share", "displaced_share", "sold_after_keep_share",
           "extra_gold_in_keep", "extra_hand_in_keep", "reading")


def grant_of(match):
    grant = match.summary.get("grant")
    if not grant:
        raise Refused(f"{match.path}: summary.json has no `grant`; not a ghost-match --grant match")
    return grant


def same_match(base, other):
    """Refuse unless `other` is `base` played again with the same seeds, secret, bots, field
    runs and live seats (anything handed over aside)."""
    if other.summary.get("mode") != "async":
        raise Refused(f"{other.path}: not a ghost-match")
    if "without" in other.summary:
        raise Refused(f"{other.path}: left cards out of the shop ({other.summary['without']})")
    for key in SAME:
        if base.summary.get(key) != other.summary.get(key):
            raise Refused(f"{other.path}: {key} is {other.summary.get(key)!r}, "
                          f"the baseline has {base.summary.get(key)!r}")
    if secret(base) != secret(other):
        raise Refused(f"{other.path}: a different match secret")


def games_of(match, base_games):
    """Per game index: (seed, runs, colour, bot, place, the seat's line)."""
    out = []
    for g in match.games():
        seat = g["seats"][0]
        out.append((g["seed"], g.get("runs"), seat["colour"], seat["bot"], seat["place"], seat,
                    g["rounds"]))
    if len(out) != len(base_games):
        raise Refused(f"{match.path}: {len(out)} games, the baseline has {len(base_games)}")
    for index, (b, o) in enumerate(zip(base_games, out)):
        if b[:4] != o[:4]:
            raise Refused(f"{match.path}: game {index} has a different seed, runs or live bot")
    return out


def kept_through(seat, rounds):
    """Whether the copy stood on the board in every round of the keep window that the seat
    played (a seat out of the game cannot hold anything)."""
    line = seat["grant"]
    if not line["granted"]:
        return False
    last = seat.get("died_round") or rounds
    window = [r for r in range(line["round"], line["round"] + line["keep"]) if r <= last]
    return all(r in line["held"] for r in window)


def window_rounds(line):
    return range(line["round"], line["round"] + max(line["keep"], 1))


def extra_in_keep(seat, base_seat, line):
    """Mean gold left and cards in hand at the end of the keep rounds, minus the same rounds of
    the same game with nothing handed over; None when no round of the window is in both."""
    mine = {r["round"]: r for r in seat.get("rounds", [])}
    theirs = {r["round"]: r for r in base_seat.get("rounds", [])}
    both = [r for r in window_rounds(line) if r in mine and r in theirs]
    if not both:
        return None
    gold = sum(mine[r]["gold_left"] - theirs[r]["gold_left"] for r in both) / len(both)
    hand = sum(len(mine[r]["hand"]) - len(theirs[r]["hand"]) for r in both) / len(both)
    return gold, hand


def sold_after_keep(line):
    end = line["round"] + line["keep"]
    return any(left.get("how") == "sell" and left["round"] >= end for left in line["left"])


def reading(row):
    if row["granted"] == 0:
        return "not handed over"
    if row["kept_through_share"] < HELD_SHARE:
        return "not held through the keep: says little"
    if row["extra_gold_in_keep"] is not None and row["extra_gold_in_keep"] >= STALL_GOLD:
        return "the bot stalled while holding it: says little"
    low, high, mean = row["btr_low"], row["btr_high"], row["better_than_reference"]
    if mean is None or low is None:
        return "too few games"
    if mean >= LINE_PLACES and low > 0:
        return "stronger than the reference"
    if mean <= -LINE_PLACES and high < 0:
        return "weaker than the reference"
    return "no clear difference from the reference"


def rows_for(base_games, match, games, ref_games=None, label=None):
    """Rows for one handed-over match, against nothing and (unless it is the reference)
    against the reference. Only games where the copy was handed over count (in both matches
    for the reference comparison): before the grant round nothing differs, so other games add
    only the bots' noise."""
    grant = grant_of(match)
    per = {}
    for index, (b, g) in enumerate(zip(base_games, games)):
        seat = g[5]
        key = (b[2], b[3])
        st = per.setdefault(key, dict(games=0, granted=0, btn=Stat(), btr=Stat(), held=0,
                                      kept=0, displaced=0, sold=0, extra=[]))
        st["games"] += 1
        line = seat["grant"]
        if not line["granted"]:
            continue
        pair = index // 2
        st["granted"] += 1
        st["btn"].add(pair, b[4] - g[4])
        if ref_games is not None and ref_games[index][5]["grant"]["granted"]:
            st["btr"].add(pair, ref_games[index][4] - g[4])
        st["held"] += line["held_rounds"]
        st["kept"] += kept_through(seat, g[6])
        st["displaced"] += line["displaced"] is not None
        st["sold"] += sold_after_keep(line)
        extra = extra_in_keep(seat, b[5], line)
        if extra is not None:
            st["extra"].append(extra)
    out = []
    for (colour, bot), st in sorted(per.items()):
        n = st["granted"]
        btn, btr = st["btn"].result(), st["btr"].result()
        row = dict(card=label or grant["card"], round=grant["round"], keep=grant["keep"],
                   bot=bot, colour=colour, games=st["games"], granted=n,
                   better_than_nothing=btn["mean"], btn_low=(btn["ci95"] or [None])[0],
                   btn_high=(btn["ci95"] or [None, None])[1],
                   better_than_reference=btr["mean"] if ref_games is not None else None,
                   btr_low=(btr["ci95"] or [None])[0] if ref_games is not None else None,
                   btr_high=(btr["ci95"] or [None, None])[1] if ref_games is not None else None,
                   seed_lines=btn["pairs"],
                   held_rounds_mean=st["held"] / n if n else None,
                   kept_through_share=st["kept"] / n if n else 0,
                   displaced_share=st["displaced"] / n if n else None,
                   sold_after_keep_share=st["sold"] / n if n else None,
                   extra_gold_in_keep=(sum(e[0] for e in st["extra"]) / len(st["extra"])
                                       if st["extra"] else None),
                   extra_hand_in_keep=(sum(e[1] for e in st["extra"]) / len(st["extra"])
                                       if st["extra"] else None))
        row["reading"] = "reference" if ref_games is None else reading(row)
        out.append(row)
    return out


def control_rows(base_games, rerun_games):
    per = {}
    for index, (b, r) in enumerate(zip(base_games, rerun_games)):
        per.setdefault((b[2], b[3]), Stat()).add(index // 2, b[4] - r[4])
    out = []
    for (colour, bot), stat in sorted(per.items()):
        d = stat.result()
        ci = d["ci95"] or [None, None]
        out.append(dict(card=CONTROL, bot=bot, colour=colour, games=d["count"],
                        better_than_nothing=d["mean"], btn_low=ci[0], btn_high=ci[1],
                        seed_lines=d["pairs"]))
    return out


def table(baseline, reference, cards, controls=()):
    base = Match(baseline)
    if base.summary.get("mode") != "async":
        raise Refused(f"{base.path}: not a ghost-match")
    for key in ("without", "grant"):
        if key in base.summary:
            raise Refused(f"{base.path}: the baseline itself has `{key}`")
    refuse_other_tools(base)
    base_games = [(g["seed"], g.get("runs"), g["seats"][0]["colour"], g["seats"][0]["bot"],
                   g["seats"][0]["place"], g["seats"][0]) for g in base.games()]
    ref = Match(reference)
    same_match(base, ref)
    refuse_other_tools(ref, allowed=("grant",))
    ref_grant = grant_of(ref)
    ref_games = games_of(ref, base_games)
    rows = rows_for(base_games, ref, ref_games, label=f"{ref_grant['card']} (reference)")
    seen = {ref_grant["card"]: reference}
    for path in cards:
        match = Match(path)
        same_match(base, match)
        refuse_other_tools(match, allowed=("grant",))
        grant = grant_of(match)
        if (grant["round"], grant["keep"]) != (ref_grant["round"], ref_grant["keep"]):
            raise Refused(f"{path}: handed over at round {grant['round']}, keep {grant['keep']}; "
                          f"the reference at round {ref_grant['round']}, keep {ref_grant['keep']}")
        if grant["card"] in seen:
            raise Refused(f"{path}: hands over {grant['card']}, as {seen[grant['card']]} does")
        seen[grant["card"]] = path
        rows.extend(rows_for(base_games, match, games_of(match, base_games), ref_games))
    for path in controls:
        rerun = Match(path)
        same_match(base, rerun)
        refuse_other_tools(rerun)
        if "grant" in rerun.summary:
            raise Refused(f"{path}: a control must hand nothing over")
        if rerun.path.resolve() == base.path.resolve():
            raise Refused(f"{path}: a control must be a second run, not the baseline")
        rows.extend(control_rows(base_games, live_games(rerun)))
    return rows


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("baseline")
    p.add_argument("cards", nargs="*")
    p.add_argument("--reference", required=True,
                   help="the same match with a reference card of the same tier handed over")
    p.add_argument("--control", action="append", default=[],
                   help="a second run of the baseline with nothing handed over (repeatable)")
    p.add_argument("--out", help="CSV file to write (default: stdout)")
    a = p.parse_args(argv)
    try:
        rows = table(a.baseline, a.reference, a.cards, a.control)
    except Refused as e:
        print(f"card_grant: refused: {e}", file=sys.stderr)
        return 2
    rows = [{k: row.get(k) for k in COLUMNS} for row in rows]
    if a.out:
        tmp = Path(a.out).with_suffix(".tmp")
        with tmp.open("w", encoding="utf-8") as f:
            write_rows(rows, f)
        tmp.replace(a.out)
    else:
        write_rows(rows, sys.stdout)
    return 0


def write_rows(rows, stream):
    out = csv.DictWriter(stream, fieldnames=COLUMNS, lineterminator="\n")
    out.writeheader()
    for row in rows:
        out.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in row.items()})


if __name__ == "__main__":
    sys.exit(main())
