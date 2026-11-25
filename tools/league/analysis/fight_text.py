"""Per-card and per-keyword tables from `league refight --text-off --keyword-off --overrun-swings`.

Definitions: docs/workstreams/card-power/definitions.md. The text-off number is how much of a
unit's fight power is in its own text. It is not the card's power: `pointer` marks a card as
worth a look, never as too strong.

With `league refight --stat-worth` the text table also gets the stat worth of each card's text:
the multiplier on a plain unit's own Attack and Health at which it does as well as the card did.

With `league refight --fresh-copy` it writes fresh_copy.csv: what a fresh copy's own fight text is
worth on recorded boards it was added to. Each card is read against the fresh copies of the other
cards at the same stage: this run's, plus those of --fresh-reference (an earlier full
fresh_copy.csv) for cards this run did not try. Also in-fight text worth, never card power.

usage: fight_text.py <refight modes dir> --out <dir> [--fresh-reference <fresh_copy.csv>]
Writes text_cards.csv, keywords.csv, overrun_swings.csv and (with fresh copies) fresh_copy.csv into --out.
"""
import argparse
import csv
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

import numpy as np

STAGES = ("1-4", "5-8", "9-12", "13+")
MIN_OBSERVATIONS = 200
LOOK_SPREADS = 3.0
LOOK_FLOOR = 0.05  # the text must turn at least 5 fights in 100, however tight the table is
# Stat worth: the plain unit's score with its own stats at each multiplier (x1 is plain text off).
RUNGS = (1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0)
RUNG_FIELDS = ("score_off",) + tuple(f"score_x{round(100 * rung)}" for rung in RUNGS[1:])
BEYOND = 9.0  # stands for "more than the top rung"
WORTH_COLUMNS = ("stat_worth", "stat_worth_low", "stat_worth_high", "adds_attack", "adds_health")


def read(path):
    if not path.exists():
        return []
    with open(path) as stream:
        return [json.loads(line) for line in stream if line.strip()]


def middle_and_spread(values):
    """The median, and 1.4826 x the median distance from it (about one standard deviation)."""
    middle = statistics.median(values)
    return middle, 1.4826 * statistics.median(abs(v - middle) for v in values)


def clustered(rows, value):
    """Mean of value(row) with a 95% interval grouped by game: (mean, low, high, n)."""
    per_game = defaultdict(lambda: [0.0, 0])
    for row in rows:
        cell = per_game[row["game"]]
        cell[0] += value(row)
        cell[1] += 1
    n = sum(c[1] for c in per_game.values())
    if not n:
        return None, None, None, 0
    mean = sum(c[0] for c in per_game.values()) / n
    games = len(per_game)
    if games < 2:
        return mean, None, None, n
    spread = sum((c[0] - mean * c[1]) ** 2 for c in per_game.values())
    half = 1.96 * math.sqrt(spread * games / (games - 1)) / n
    return mean, mean - half, mean + half, n


def fmt(x, digits=3):
    return "" if x is None else round(x, digits)


def solve(target, scores):
    """The multiplier at which the plain unit's mean score reaches the card's mean score, read
    between the first rung that reaches it and the rung before (so a later dip is ignored).
    1 when plain text off already does as well; BEYOND when no rung reaches it."""
    if scores[0] >= target:
        return RUNGS[0]
    for i in range(1, len(RUNGS)):
        if scores[i] >= target:
            share = (target - scores[i - 1]) / (scores[i] - scores[i - 1])
            return RUNGS[i - 1] + share * (RUNGS[i] - RUNGS[i - 1])
    return BEYOND


def stat_worth(obs, resamples=300, seed=1):
    """Solved over the sample, not per fight; the interval resamples whole games and solves again."""
    games = {game: i for i, game in enumerate(sorted({r["game"] for r in obs}, key=str))}
    sums = np.zeros((len(games), 1 + len(RUNGS)))
    counts = np.zeros(len(games))
    for r in obs:
        i = games[r["game"]]
        sums[i] += [r["score_recorded"]] + [r[field] for field in RUNG_FIELDS]
        counts[i] += 1
    means = sums.sum(0) / counts.sum()
    value = solve(means[0], means[1:])
    weights = np.random.default_rng(seed).multinomial(len(games), np.full(len(games), 1 / len(games)), size=resamples)
    again = (weights @ sums) / (weights @ counts)[:, None]
    low, high = np.percentile([solve(row[0], row[1:]) for row in again], [2.5, 97.5])
    show = lambda m: f">{RUNGS[-1]:g}" if m > RUNGS[-1] else round(float(m), 2)
    adds = lambda field: (f">{(RUNGS[-1] - 1) * statistics.fmean(r[field] for r in obs):.0f}" if value > RUNGS[-1]
                          else round((value - 1) * statistics.fmean(r[field] for r in obs), 1))
    return {"stat_worth": show(value), "stat_worth_low": show(low), "stat_worth_high": show(high),
            "adds_attack": adds("own_attack"), "adds_health": adds("own_health")}


def text_table(rows):
    with_worth = any(RUNG_FIELDS[-1] in row for row in rows)
    cells = defaultdict(list)
    for row in rows:
        cells[(row["card"], row["tier"], row["stage"])].append(row)
    out = []
    for (card, tier, stage), obs in sorted(cells.items(), key=lambda kv: (STAGES.index(kv[0][2]), kv[0][1], kv[0][0])):
        value, low, high, n = clustered(obs, lambda r: r["score_recorded"] - r["score_off"])
        dealt = statistics.fmean(r["dealt_recorded"] - r["dealt_off"] for r in obs)
        enough = n >= MIN_OBSERVATIONS
        out.append({"stage": stage, "card": card, "tier": tier, "n": n, "status": "ok" if enough else "too few",
                    "text_value": fmt(value) if enough else "", "low": fmt(low) if enough else "",
                    "high": fmt(high) if enough else "", "damage_change": fmt(dealt, 2) if enough else "",
                    "results_changed": fmt(statistics.fmean(r["result_changed"] for r in obs)) if enough else "",
                    "tier_median": "", "spreads": "", "pointer": ""})
        if with_worth:
            measured = enough and all(RUNG_FIELDS[-1] in r for r in obs)
            out[-1].update(stat_worth(obs) if measured else dict.fromkeys(WORTH_COLUMNS, ""))
    # Compare inside one stage. Worth a look: three or more spreads above the middle card of the
    # stage (spread = 1.4826 x the median distance from the middle), with the interval clear of it.
    for stage in STAGES:
        here = [r for r in out if r["stage"] == stage and r["status"] == "ok"]
        if not here:
            continue
        middle, spread = middle_and_spread([r["text_value"] for r in here])
        by_tier = defaultdict(list)
        for r in here:
            by_tier[r["tier"]].append(r["text_value"])
        for r in here:
            r["tier_median"] = fmt(statistics.median(by_tier[r["tier"]]))
            r["spreads"] = fmt((r["text_value"] - middle) / spread, 1) if spread else ""
            if (spread and r["spreads"] >= LOOK_SPREADS and r["low"] != "" and r["low"] > middle
                    and r["text_value"] >= LOOK_FLOOR):
                r["pointer"] = "worth a look"
    return out


MIN_REFERENCE = 10  # fresh copies of at least this many cards at a stage before any is marked


def fresh_table(rows, reference=()):
    """Per card and stage: the fresh copy's score with its text on minus with it off, and the share
    of boards where it took the weakest unit's place. Worth a look by the text-off rule, inside the
    stage's table of fresh copies (this table, plus `reference` rows for cards it lacks). A fresh
    copy is never compared with held copies: they carry the stats they gathered, and read higher."""
    cells = defaultdict(list)
    for row in rows:
        cells[(row["card"], row["tier"], row["stage"])].append(row)
    out = []
    for (card, tier, stage), obs in sorted(cells.items(), key=lambda kv: (STAGES.index(kv[0][2]), kv[0][1], kv[0][0])):
        value, low, high, n = clustered(obs, lambda r: r["score_on"] - r["score_off"])
        enough = n >= MIN_OBSERVATIONS
        out.append({"stage": stage, "card": card, "tier": tier, "boards": n, "status": "ok" if enough else "too few",
                    "fresh_value": fmt(value) if enough else "", "low": fmt(low) if enough else "",
                    "high": fmt(high) if enough else "",
                    "damage_change": fmt(statistics.fmean(r["dealt_on"] - r["dealt_off"] for r in obs), 2) if enough else "",
                    "results_changed": fmt(statistics.fmean(r["result_changed"] for r in obs)) if enough else "",
                    "displaced": fmt(statistics.fmean(r["displaced"] is not None for r in obs)),
                    "stage_middle": "", "spreads": "", "pointer": ""})
    mine = {(r["card"], r["stage"]) for r in out}
    tables = defaultdict(list)
    for r in out + [r for r in reference if (r["card"], r["stage"]) not in mine]:
        if r["status"] == "ok":
            tables[r["stage"]].append(float(r["fresh_value"]))
    for r in out:
        if r["status"] != "ok" or len(tables[r["stage"]]) < MIN_REFERENCE:
            continue
        middle, spread = middle_and_spread(tables[r["stage"]])
        r["stage_middle"] = fmt(middle)
        if spread:
            r["spreads"] = fmt((r["fresh_value"] - middle) / spread, 1)
            if (r["spreads"] >= LOOK_SPREADS and r["low"] != "" and r["low"] > middle
                    and r["fresh_value"] >= LOOK_FLOOR):
                r["pointer"] = "worth a look"
    readings = {card: fresh_reading([r for r in out if r["card"] == card]) for card in {r["card"] for r in out}}
    for r in out:
        r["reading"] = readings[r["card"]]
    return out


def fresh_reading(rows):
    """One reading per card over its stages: "too few boards" (no stage with enough), "no fight
    text" (every measured stage's interval includes zero), "fight text worth under the floor"
    (every stage under LOOK_FLOOR, some clear of zero), or "has fight text worth"."""
    measured = [r for r in rows if r["status"] == "ok"]
    if not measured:
        return "too few boards"
    clear = [r for r in measured if r["fresh_value"] != 0 and r["low"] != "" and r["low"] > 0]
    if not clear:
        return "no fight text: needs the whole-game route"
    if all(r["fresh_value"] < LOOK_FLOOR for r in measured):
        return "fight text worth under 5 in 100: needs the whole-game route"
    return "has fight text worth"


def read_csv(path):
    with open(path, newline="") as stream:
        return list(csv.DictReader(stream))


def thirds(rows):
    """Cut points of the enemy board's median Health per stage, from one value per fight side."""
    seen = defaultdict(dict)
    for row in rows:
        if row["enemy_median_health"] is not None:
            seen[row["stage"]][(row["game"], row["round"], row["position"])] = row["enemy_median_health"]
    cuts = {}
    for stage, values in seen.items():
        if len(values) >= 3:
            low, high = statistics.quantiles(values.values(), n=3)
            cuts[stage] = (low, high)
    return cuts


def keyword_table(rows, cuts):
    def band(row):
        cut = cuts.get(row["stage"])
        health = row["enemy_median_health"]
        if cut is None or health is None:
            return None
        return "low" if health <= cut[0] else "middle" if health <= cut[1] else "high"

    cells = defaultdict(list)
    for row in rows:
        cells[(row["keyword"], row["stage"], "all")].append(row)
        if band(row):
            cells[(row["keyword"], row["stage"], band(row))].append(row)
    order = ("all", "low", "middle", "high")
    out = []
    for (keyword, stage, health), obs in sorted(cells.items(), key=lambda kv: (kv[0][0], STAGES.index(kv[0][1]), order.index(kv[0][2]))):
        value, low, high, n = clustered(obs, lambda r: r["score_recorded"] - r["score_off"])
        enough = n >= MIN_OBSERVATIONS
        cut = cuts.get(stage)
        out.append({"keyword": keyword, "stage": stage, "enemy_health": health,
                    "health_cuts": "" if cut is None else f"{cut[0]:g}/{cut[1]:g}", "n": n,
                    "status": "ok" if enough else "too few", "keyword_value": fmt(value) if enough else "",
                    "low": fmt(low) if enough else "", "high": fmt(high) if enough else "",
                    "results_changed": fmt(statistics.fmean(r["result_changed"] for r in obs)) if enough else ""})
    return out


def swing_table(rows):
    cells = defaultdict(list)
    for row in rows:
        cells[(row["stage"], "all")].append(row)
        cells[(row["stage"], row["card"])].append(row)
    out = []
    for (stage, card), obs in sorted(cells.items(), key=lambda kv: (STAGES.index(kv[0][0]), kv[0][1] != "all", kv[0][1])):
        n = len(obs)
        out.append({"stage": stage, "card": card, "attacks": n,
                    "kills_2_plus": fmt(sum(r["kills"] >= 2 for r in obs) / n),
                    "kills_3_plus": fmt(sum(r["kills"] >= 3 for r in obs) / n),
                    "whole_board": fmt(sum(bool(r["whole_board"]) for r in obs) / n),
                    "whole_board_of_3_plus": fmt(sum(bool(r["whole_board"]) and r["enemy_standing"] >= 3 for r in obs) / n),
                    "mean_kills": fmt(statistics.fmean(r["kills"] for r in obs), 2)})
    return out


def write(path, rows):
    with open(path, "w", newline="") as stream:
        if rows:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("modes")
    parser.add_argument("--out", required=True)
    parser.add_argument("--fresh-reference", help="an earlier full fresh_copy.csv, for cards this run did not try")
    args = parser.parse_args()
    source, out = Path(args.modes), Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    text = read(source / "text_off.jsonl")
    keywords = read(source / "keyword_off.jsonl")
    fresh = read(source / "fresh_copy.jsonl")
    texts = text_table(text)
    if text:
        write(out / "text_cards.csv", texts)
    if keywords or text:
        write(out / "keywords.csv", keyword_table(keywords, thirds(text + keywords)))
    swings = read(source / "overrun_swings.jsonl")
    if swings or text:
        write(out / "overrun_swings.csv", swing_table(swings))
    if fresh:
        reference = read_csv(args.fresh_reference) if args.fresh_reference else []
        write(out / "fresh_copy.csv", fresh_table(fresh, reference))
    print(f"{len(text)} text-off, {len(keywords)} keyword-off and {len(fresh)} fresh-copy observations -> {out}")


if __name__ == "__main__":
    main()
