"""Bought against passed, and pick rate, per card, from a ghost match's shop log.

Definitions: docs/workstreams/card-power/definitions.md. One observation is one turn of the live
seat in which a unit card was in a shop view with `buyable` true. It counts as bought when the
card is in the `bought` list of any shop view that turn. The number is mean final place when
bought minus when passed, taken inside groups of (bot, round, card's tribe is the seat's main
tribe when the turn began) and averaged with weight n_bought * n_passed / (n_bought + n_passed).

usage: bought_passed.py <match dir>... --out <cards.csv> [--resamples 1000] [--seed 1]
"""
import argparse
import csv
import gzip
import json
from collections import defaultdict
from pathlib import Path

import numpy as np

MIN_GROUP = 5        # bought and passed turns a group needs before it is compared
MIN_CARD = 100       # bought and passed turns a card needs before its number is shown
FLAG_PLACES = -0.5   # half a place or more better when bought
MAIN_TRIBE_UNITS = 3


def read_lines(path):
    gz = path.with_name(path.name + ".gz")
    opener, source = (gzip.open, gz) if gz.exists() else (open, path)
    with opener(source, "rt") as stream:
        for line in stream:
            if line.strip():
                yield json.loads(line)


def main_tribe(tribes):
    """The tribe with the most units, three or more; ties go to the first name."""
    best = max(sorted(tribes.items()), key=lambda kv: kv[1], default=(None, 0))
    return best[0] if best[1] >= MAIN_TRIBE_UNITS else None


def load_match(directory, tag):
    """Yield (game key, bot label, place, {(round, card): bought}, {round: main tribe at turn start})."""
    directory = Path(directory)
    summary = json.loads((directory / "summary.json").read_text())
    summary = summary.get("summary", summary)
    labels = {"red": summary.get("red_label") or summary["red"],
              "blue": summary.get("blue_label") or summary["blue"]}
    turns = defaultdict(dict)
    for row in read_lines(directory / "shops.jsonl"):
        seen = turns[row["game"]]
        for offer in row["offers"]:
            if not offer["spell"] and offer["buyable"]:
                seen.setdefault((row["round"], offer["card"]), False)
        for bought in row["bought"]:
            if not bought["spell"]:
                seen[(row["round"], bought["card"])] = True
    for game in read_lines(directory / "games.jsonl"):
        seat = game["seats"][0]
        label = seat.get("label") or labels.get(seat.get("colour"), seat["bot"])
        before = {r["round"] + 1: main_tribe(r["tribes"]) for r in seat["rounds"]}
        yield (tag, game["game"]), label, seat["place"], turns.get(game["game"], {}), before


def collect(directories):
    """rows[card] = list of (game key, bot, group, bought, place)."""
    rows = defaultdict(list)
    for tag, directory in enumerate(directories):
        library = {c["id"]: c for c in json.loads((Path(directory) / "library.json").read_text())}
        for key, bot, place, seen, before in load_match(directory, tag):
            for (round_no, card), bought in seen.items():
                tribe = before.get(round_no)
                in_tribe = tribe is not None and tribe in library[card]["tribes"]
                rows[card].append((key, bot, (bot, round_no, in_tribe), bought, place))
    return rows, library


def arrays(observations):
    """Per observation: game index, group index, bought (0 or 1) and place, as numpy arrays."""
    games = {key: i for i, key in enumerate(sorted({o[0] for o in observations}))}
    groups = {group: i for i, group in enumerate(sorted({o[2] for o in observations}))}
    return (np.array([games[o[0]] for o in observations]), np.array([groups[o[2]] for o in observations]),
            np.array([1.0 if o[3] else 0.0 for o in observations]), np.array([float(o[4]) for o in observations]),
            len(games), len(groups))


def grouped_difference(group, bought, place, n_groups, weight=None):
    """Weighted mean over groups of (mean place bought - mean place passed), and the groups used."""
    w = np.ones(len(group)) if weight is None else weight
    nb = np.bincount(group, w * bought, n_groups)
    pb = np.bincount(group, w * bought * place, n_groups)
    npass = np.bincount(group, w * (1 - bought), n_groups)
    pp = np.bincount(group, w * (1 - bought) * place, n_groups)
    ok = (nb >= MIN_GROUP) & (npass >= MIN_GROUP)
    if not ok.any():
        return None, 0
    share = nb[ok] * npass[ok] / (nb[ok] + npass[ok])
    return float((share * (pb[ok] / nb[ok] - pp[ok] / npass[ok])).sum() / share.sum()), int(ok.sum())


def interval(game, group, bought, place, n_games, n_groups, resamples, rng):
    """95% interval by resampling whole games."""
    values = []
    for _ in range(resamples):
        weight = rng.multinomial(n_games, np.full(n_games, 1.0 / n_games)).astype(float)[game]
        value, _ = grouped_difference(group, bought, place, n_groups, weight)
        if value is not None:
            values.append(value)
    if len(values) < resamples * 0.9:
        return None, None
    return float(np.percentile(values, 2.5)), float(np.percentile(values, 97.5))


def card_row(card, info, bot, observations, resamples, rng):
    bought = [o for o in observations if o[3]]
    passed = [o for o in observations if not o[3]]
    row = {"card": card, "tier": info["tier"], "tribe": "/".join(info["tribes"]) or "none", "bot": bot,
           "offered": len(observations), "bought": len(bought), "passed": len(passed),
           "pick_rate": round(len(bought) / len(observations), 4) if observations else "",
           "place_bought": round(sum(o[4] for o in bought) / len(bought), 3) if bought else "",
           "place_passed": round(sum(o[4] for o in passed) / len(passed), 3) if passed else "",
           "difference": "", "low": "", "high": "", "groups": 0, "status": "too few", "flag": ""}
    if len(bought) < MIN_CARD or len(passed) < MIN_CARD:
        return row
    game, group, took, place, n_games, n_groups = arrays(observations)
    value, used = grouped_difference(group, took, place, n_groups)
    row["groups"] = used
    if value is None:
        return row
    low, high = interval(game, group, took, place, n_games, n_groups, resamples, rng)
    row.update(difference=round(value, 3), status="ok")
    if low is not None:
        row.update(low=round(low, 3), high=round(high, 3))
        if value <= FLAG_PLACES and high < 0:
            row["flag"] = "better when bought"
    return row


def report(directories, resamples=1000, seed=1):
    rows, library = collect(directories)
    rng = np.random.default_rng(seed)
    out = []
    for card in sorted(rows):
        observations = rows[card]
        out.append(card_row(card, library[card], "all", observations, resamples, rng))
        for bot in sorted({o[1] for o in observations}):
            mine = [o for o in observations if o[1] == bot]
            out.append(card_row(card, library[card], bot, mine, resamples, rng))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("match", nargs="+")
    parser.add_argument("--out", required=True)
    parser.add_argument("--resamples", type=int, default=1000)
    parser.add_argument("--seed", type=int, default=1)
    args = parser.parse_args()
    rows = report(args.match, args.resamples, args.seed)
    with open(args.out, "w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f"{len(rows)} rows, {sum(r['status'] == 'ok' for r in rows)} with a number, "
          f"{sum(bool(r['flag']) for r in rows)} flagged -> {args.out}")


if __name__ == "__main__":
    main()
