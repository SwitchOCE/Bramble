#!/usr/bin/env python3
"""Summarise place_probe.gd CSVs: what a layout is worth per fight, by game stage."""
import csv
import math
import sys


def mean_ci(values):
    n = len(values)
    if n < 2:
        return (values[0] if values else 0.0), 0.0
    m = sum(values) / n
    var = sum((v - m) ** 2 for v in values) / (n - 1)
    return m, 1.96 * math.sqrt(var / n)


def main(paths):
    rows = []
    for path in paths:
        with open(path, newline="") as handle:
            rows += list(csv.DictReader(handle))
    stages = [("rounds 1-4", 1, 4), ("rounds 5-8", 5, 8), ("rounds 9+", 9, 99), ("all", 1, 99)]
    print(f"{len(rows)} fight-sides from {len(paths)} file(s)")
    ladder(rows, stages)
    print()
    print("| Stage | Sides | Units | Pinned | Actual - shuffled all | Actual - shuffled free | Best - shuffled all | Best - actual | Contested share |")
    print("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
    for name, lo, hi in stages:
        chosen = [r for r in rows if lo <= int(r["round"]) <= hi]
        if not chosen:
            continue
        f = lambda key: [float(r[key]) for r in chosen]
        act, sa, sf, best = f("actual"), f("shuffled_all"), f("shuffled_free"), f("best")
        units = sum(f("units")) / len(chosen)
        pinned = sum(f("pinned")) / len(chosen)
        contested = sum(1 for v in sa if 0.1 < v < 0.9) / len(chosen)
        cells = []
        for x, y in ((act, sa), (act, sf), (best, sa), (best, act)):
            m, ci = mean_ci([a - b for a, b in zip(x, y)])
            cells.append(f"{100*m:+.1f} ±{100*ci:.1f}")
        print(f"| {name} | {len(chosen)} | {units:.1f} | {pinned:.1f} | " + " | ".join(cells) + f" | {100*contested:.0f}% |")


def ladder(rows, stages):
    """Win-rate points over moving every unit at random, step by step; same sides in each column."""
    print("Win-rate points over shuffled (all units move), 95% CI, sides with a bot brain:")
    print("| Stage | Sides | Pinned shuffle | Rule | Hard's own (rule + search 20 on scout) | Search 150 on scout | Search 150 on real board |")
    print("|---|---:|---:|---:|---:|---:|---:|")
    for name, lo, hi in stages:
        chosen = [r for r in rows if lo <= int(r["round"]) <= hi and float(r["rule"]) >= 0 and float(r["scouted"]) >= 0]
        if not chosen:
            continue
        cells = []
        for key in ("shuffled_free", "rule", "actual", "scouted", "best"):
            m, ci = mean_ci([float(r[key]) - float(r["shuffled_all"]) for r in chosen])
            cells.append(f"{100*m:+.1f} ±{100*ci:.1f}")
        print(f"| {name} | {len(chosen)} | " + " | ".join(cells) + " |")
    print()


if __name__ == "__main__":
    main(sys.argv[1:])
