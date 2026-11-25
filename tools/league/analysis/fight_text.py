"""Per-card and per-keyword tables from `league refight --text-off --keyword-off --overrun-swings`.

Definitions: docs/workstreams/card-power/definitions.md. The text-off number is how much of a
unit's fight power is in its own text. It is not the card's power, and this script raises no flag
from it: `pointer` only says where to look.

usage: fight_text.py <refight modes dir> --out <dir>
Writes text_cards.csv, keywords.csv and overrun_swings.csv into --out.
"""
import argparse
import csv
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

STAGES = ("1-4", "5-8", "9-12", "13+")
MIN_OBSERVATIONS = 200


def read(path):
    if not path.exists():
        return []
    with open(path) as stream:
        return [json.loads(line) for line in stream if line.strip()]


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


def text_table(rows):
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
                    "tier_median": "", "pointer": ""})
    # Compare inside one stage: the median card of each tier, then the pointer.
    for stage in STAGES:
        here = [r for r in out if r["stage"] == stage and r["status"] == "ok"]
        by_tier = defaultdict(list)
        for r in here:
            by_tier[r["tier"]].append(r["text_value"])
        median = {tier: statistics.median(values) for tier, values in by_tier.items()}
        top6 = statistics.quantiles(by_tier[6], n=4)[2] if len(by_tier.get(6, [])) >= 4 else None
        for r in here:
            tier = r["tier"]
            r["tier_median"] = fmt(median[tier])
            bar = top6 if tier >= 5 else median.get(tier + 2)
            own = statistics.quantiles(by_tier[tier], n=4)[2] if len(by_tier[tier]) >= 4 else median[tier]
            if bar is not None and r["low"] != "" and r["low"] > max(bar, own):
                r["pointer"] = "text fights above its tier"
    return out


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
    args = parser.parse_args()
    source, out = Path(args.modes), Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    text = read(source / "text_off.jsonl")
    keywords = read(source / "keyword_off.jsonl")
    write(out / "text_cards.csv", text_table(text))
    write(out / "keywords.csv", keyword_table(keywords, thirds(text + keywords)))
    write(out / "overrun_swings.csv", swing_table(read(source / "overrun_swings.jsonl")))
    print(f"{len(text)} text-off and {len(keywords)} keyword-off observations -> {out}")


if __name__ == "__main__":
    main()
