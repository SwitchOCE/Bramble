#!/usr/bin/env python3
"""Left out of the shop: a card's worth to each bot over whole games.

    python3 card_without.py BASELINE WITHOUT [WITHOUT ...] [--control RERUN] [--out FILE.csv]

BASELINE is a `league ghost-match` folder with every card present. Each WITHOUT folder is the
same match played with `--without <card>`: same seeds, secret, games, bots and field runs.
To read a card inside a proposed change, give a `--trial-rules` baseline and WITHOUT matches
played on the same trial rules.
Writes one CSV row per card per bot (stdout without `--out`). `--control` takes a second run
of the baseline with nothing left out; its rows (card `(control)`) show how far the bots' own
CPU-clock noise moves places when no card is left out. The definition is fixed in
docs/workstreams/card-power/definitions.md, "Left out of the shop".
"""
import argparse
import csv
import sys
from pathlib import Path

from match_data import Match, Stat

# definitions.md: under 100 baseline games with a buy says little; the flag is a first guess.
TOO_FEW_BOUGHT = 100
FLAG_PLACES = 0.5

COLUMNS = ("card", "bot", "colour", "games", "place_with", "place_without", "diff_mean",
           "ci95_low", "ci95_high", "seed_lines", "bought_games", "too_few", "flag")

# Fields of summary.json that must agree before two matches pair.
SAME = ("rules_hash", "seeds_sha256", "games", "red", "blue", "red_label", "blue_label",
        "clock_ms", "content", "mode")


CONTROL = "(control)"


class Refused(Exception):
    """The two matches are not the same match with a card left out."""


def secret(match):
    path = match.path / "private/secret.txt"
    try:
        return path.read_text(encoding="utf-8").strip()
    except FileNotFoundError:
        raise Refused(f"{match.path}: no private/secret.txt")


def live_games(match):
    """Per game index: (seed, runs, live seat's colour, bot, place)."""
    out = []
    for g in match.games():
        seat = g["seats"][0]
        out.append((g["seed"], g.get("runs"), seat["colour"], seat["bot"], seat["place"]))
    return out


# summary.json keys of the other card-power tools' matches: changed card data
# (`card_trial.py`). A trial match pairs here only with a baseline played on the same trial rules.
OTHER_TOOLS = ("trial_rules",)


def refuse_other_tools(match, allowed=()):
    """Refuse a match made with another tool's option, unless that option is `allowed`."""
    for key in OTHER_TOOLS:
        if key in match.summary and key not in allowed:
            raise Refused(f"{match.path}: a ghost-match --{key.replace('_', '-')} match "
                          f"({match.summary[key]}); it does not pair here")


def check_pair(base, other, control=False):
    """Refuse unless `other` is `base` replayed with cards left out (or, as a control, with
    nothing left out). Returns the cards, or `["(control)"]`."""
    # A card can be left out inside a trial: both matches then carry the same trial rules.
    trial = base.summary.get("trial_rules")
    for match in (base, other):
        if match.summary.get("mode") != "async":
            raise Refused(f"{match.path}: not a ghost-match")
        refuse_other_tools(match, allowed=("trial_rules",) if trial else ())
    if other.summary.get("trial_rules") != trial:
        raise Refused(f"{other.path}: trial rules {other.summary.get('trial_rules')!r}, "
                      f"the baseline has {trial!r}")
    if "without" in base.summary:
        raise Refused(f"{base.path}: the baseline itself left out {base.summary['without']}")
    cards = other.summary.get("without")
    if control:
        if cards:
            raise Refused(f"{other.path}: a control must leave nothing out, it left out {cards}")
        if other.path.resolve() == base.path.resolve():
            raise Refused(f"{other.path}: a control must be a second run, not the baseline")
        cards = [CONTROL]
    elif not cards:
        raise Refused(f"{other.path}: summary.json lists no cards left out (`without`)")
    for key in SAME:
        if base.summary.get(key) != other.summary.get(key):
            raise Refused(f"{other.path}: {key} is {other.summary.get(key)!r}, "
                          f"the baseline has {base.summary.get(key)!r}")
    if secret(base) != secret(other):
        raise Refused(f"{other.path}: a different match secret")
    return cards


def compare(base, base_games, other, control=False):
    cards = check_pair(base, other, control)
    games = live_games(other)
    for index, (b, o) in enumerate(zip(base_games, games)):
        if b[:4] != o[:4]:
            raise Refused(f"{other.path}: game {index} has a different seed, runs or live bot")
    return cards, games


def bought_games(base, cards):
    """Per (colour, bot): baseline game indexes where the live seat bought any of `cards`."""
    wanted = set(cards)
    found = {}
    for row in base.rows("shops"):
        if row["seat"] != 0:
            continue
        if any(b["card"] in wanted and not b["spell"] for b in row["bought"]):
            found.setdefault((row["colour"], row["bot"]), set()).add(row["game"])
    return found


def rows_for(base, base_games, other, control=False):
    cards, games = compare(base, base_games, other, control)
    card = "+".join(cards)
    bought = {} if control else bought_games(base, cards)
    stats = {}
    for index, (b, o) in enumerate(zip(base_games, games)):
        key = (b[2], b[3])
        with_s, without_s, diff = stats.setdefault(key, (Stat(), Stat(), Stat()))
        pair = index // 2
        with_s.add(pair, b[4])
        without_s.add(pair, o[4])
        diff.add(pair, o[4] - b[4])
    out = []
    for (colour, bot), (with_s, without_s, diff) in sorted(stats.items()):
        w, wo, d = with_s.result(), without_s.result(), diff.result()
        ci = d["ci95"] or [None, None]
        n_bought = None if control else len(bought.get((colour, bot), ()))
        too_few = None if control else n_bought < TOO_FEW_BOUGHT
        flag = (not control and not too_few and d["mean"] >= FLAG_PLACES
                and ci[0] is not None and ci[0] > 0)
        out.append(dict(card=card, bot=bot, colour=colour, games=d["count"],
                        place_with=w["mean"], place_without=wo["mean"], diff_mean=d["mean"],
                        ci95_low=ci[0], ci95_high=ci[1], seed_lines=d["pairs"],
                        bought_games=n_bought, too_few=too_few, flag=flag))
    return out


def table(baseline, others, controls=()):
    base = Match(baseline)
    base_games = live_games(base)
    rows, seen = [], {}
    for path in others:
        other = Match(path)
        key = tuple(other.summary.get("without") or ())
        if key in seen:
            raise Refused(f"{path}: leaves out the same cards as {seen[key]}")
        seen[key] = path
        rows.extend(rows_for(base, base_games, other))
    for path in controls:
        rows.extend(rows_for(base, base_games, Match(path), control=True))
    return rows


def write(rows, stream):
    out = csv.DictWriter(stream, fieldnames=COLUMNS, lineterminator="\n")
    out.writeheader()
    for row in rows:
        out.writerow({k: (f"{v:.4f}" if isinstance(v, float) else v) for k, v in row.items()})


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("baseline")
    p.add_argument("without", nargs="*")
    p.add_argument("--control", action="append", default=[],
                   help="a second run of the baseline with nothing left out (repeatable)")
    p.add_argument("--out", help="CSV file to write (default: stdout)")
    a = p.parse_args(argv)
    try:
        if not a.without and not a.control:
            raise Refused("no WITHOUT match or --control given")
        rows = table(a.baseline, a.without, a.control)
    except Refused as e:
        print(f"card_without: refused: {e}", file=sys.stderr)
        return 2
    if a.out:
        tmp = Path(a.out).with_suffix(".tmp")
        with tmp.open("w", encoding="utf-8") as f:
            write(rows, f)
        tmp.replace(a.out)
    else:
        write(rows, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
