#!/usr/bin/env python3
"""Summarise tools/sim/reveal_probe.gd CSVs (evidence/reveal.md).

Usage: python3 tools/sim/summarize_reveal.py <csv> [<csv> ...]

Values are win-rate points (ties half) over standing still, against the enemy board as it
fought, on the same 32 fight seeds, with 95% CIs. Sides with fewer than 2 units are left out.
"""

import csv
import math
import sys
from pathlib import Path


def cell(values: list[float]) -> str:
    n = len(values)
    mean = sum(values) / n
    sd = math.sqrt(sum((v - mean) ** 2 for v in values) / (n - 1)) if n > 1 else 0.0
    return f"{100 * mean:+.1f} ±{100 * 1.96 * sd / math.sqrt(n):.1f}"


def gain(rows: list[dict[str, str]], key: str) -> str:
    return cell([float(r[key]) - float(r["still"]) for r in rows])


def main(paths: list[str]) -> None:
    rows: list[dict[str, str]] = []
    for path in paths:
        with Path(path).open(newline="") as handle:
            rows += list(csv.DictReader(handle))
    sides = [r for r in rows if int(r["units"]) >= 2]
    replayed = sum(int(r["replay_ok"]) for r in rows) / len(rows)
    print(f"{len(sides)} fight sides with 2+ units; real fight replayed exactly: {100 * replayed:.0f}%")
    for key in ("random", "chosen", "best"):
        print(f"- {key} over standing still: {gain(sides, key)}")
    contested = [r for r in sides if 0.1 < float(r["still"]) < 0.9]
    share = 100 * len(contested) / len(sides)
    print(f"- contested ({share:.0f}%): chosen {gain(contested, 'chosen')}, best {gain(contested, 'best')}")
    swapped = sum(int(r["swaps_made"]) > 0 for r in sides) / len(sides)
    print(f"- sides that swapped: {100 * swapped:.0f}%")
    changed = [r for r in sides if r["changed"] == "1"]
    better = sum(float(r["won"]) > float(r["won_still"]) for r in changed)
    worse = sum(float(r["won"]) < float(r["won_still"]) for r in changed)
    print(f"- result changed: {100 * len(changed) / len(sides):.0f}% ({better} better, {worse} worse)")
    ceiling = [float(r["best"]) - float(r["still"]) for r in sides]
    small = 100 * sum(v <= 0.03 for v in ceiling) / len(sides)
    print(f"- fights where the best board gains 3 points or less: {small:.0f}%")
    usec = sorted(int(r["usec"]) for r in sides)
    print(f"- reveal time: mean {sum(usec) / len(usec) / 1000:.0f} ms, p95 {usec[int(0.95 * len(usec))] / 1000:.0f} ms")
    for low, high in ((1, 2), (3, 4), (5, 8), (9, 99)):
        stage = [r for r in sides if low <= int(r["round"]) <= high]
        if len(stage) > 1:
            moved = sum(int(r["changed"]) for r in stage) / len(stage)
            print(
                f"  rounds {low}-{high}: {len(stage)} sides, chosen {gain(stage, 'chosen')},"
                f" best {gain(stage, 'best')}, result changed {100 * moved:.0f}%"
            )


if __name__ == "__main__":
    main(sys.argv[1:])
