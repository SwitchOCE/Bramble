#!/usr/bin/env python3
"""Summarises position test runs: average place with error bars, per arm and game stage.

Usage: summarize_position.py <dir with *.games.csv and *.fights.csv>
Prints markdown tables. "vs shuffled" pairs games by seed within a pool and rule set.
"""

from __future__ import annotations

import csv
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path

STAGES = (("early (rounds 1-4)", 1, 4), ("mid (rounds 5-8)", 5, 8), ("late (rounds 9+)", 9, 99))


def read_rows(folder: Path, part: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for path in sorted(folder.glob(f"*.{part}.csv")):
        with path.open(encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                row["run"] = path.name.split(".")[0]
                rows.append(row)
    return rows


def mean_se(values: list[float]) -> tuple[float, float]:
    if len(values) < 2:
        return (values[0] if values else math.nan, math.nan)
    return statistics.fmean(values), statistics.stdev(values) / math.sqrt(len(values))


def place_table(games: list[dict[str, str]]) -> None:
    by: dict[tuple[str, str, str], dict[int, int]] = defaultdict(dict)
    for row in games:
        by[(row["pool"], row["rules"], row["arm"])][int(row["seed"])] = int(row["place"])
    print("| Pool | Rules | Arm | Games | Avg place | SE | vs shuffled (95% CI) | Top 4 |")
    print("|---|---|---|---:|---:|---:|---:|---:|")
    for key in sorted(by):
        pool, rules, arm = key
        places = by[key]
        avg, se = mean_se([float(p) for p in places.values()])
        base = by.get((pool, rules, "shuffled"))
        gain = ""
        if base is not None and arm != "shuffled":
            diffs = [float(base[s] - places[s]) for s in places if s in base]
            d_avg, d_se = mean_se(diffs)
            gain = f"{d_avg:+.3f} ({d_avg - 1.96 * d_se:+.3f} to {d_avg + 1.96 * d_se:+.3f})"
        top4 = 100 * sum(1 for p in places.values() if p <= 4) / len(places)
        print(f"| {pool} | {rules or '-'} | {arm} | {len(places)} | {avg:.3f} | {se:.3f} | {gain} | {top4:.0f}% |")


def stage_table(fights: list[dict[str, str]]) -> None:
    by: dict[tuple[str, str, str, str], list[dict[str, str]]] = defaultdict(list)
    for row in fights:
        for name, low, high in STAGES:
            if low <= int(row["round"]) <= high:
                by[(row["pool"], row["rules"], name, row["arm"])].append(row)
    print("| Pool | Rules | Stage | Arm | Fights | Win rate (tie = half) | SE | Units | Full board | Pos. units |")
    print("|---|---|---|---|---:|---:|---:|---:|---:|---:|")
    for key in sorted(by):
        rows = by[key]
        scores = [{"win": 1.0, "tie": 0.5, "loss": 0.0}[r["result"]] for r in rows]
        avg, se = mean_se(scores)
        units = statistics.fmean(int(r["units"]) for r in rows)
        full = 100 * sum(1 for r in rows if int(r["units"]) == 7) / len(rows)
        position = statistics.fmean(int(r["position_units"]) for r in rows)
        pool, rules, stage, arm = key
        print(
            f"| {pool} | {rules or '-'} | {stage} | {arm} | {len(rows)} | {100 * avg:.1f}% | {100 * se:.1f} "
            f"| {units:.1f} | {full:.0f}% | {position:.1f} |"
        )


def probe_table(probes: list[dict[str, str]]) -> None:
    if not probes:
        return
    groups: dict[tuple[str, str, str], list[dict[str, str]]] = defaultdict(list)
    for row in probes:
        for name, low, high in STAGES:
            if low <= int(row["round"]) <= high:
                groups[(row["pool"], row["rules"], name)].append(row)
        groups[(row["pool"], row["rules"], "units = 7" if row["units"] == "7" else "units < 7")].append(row)
    print(
        "| Pool | Rules | Slice | Boards | Random layout | Worst of 10 | Best of 10 | Heuristic | "
        "Search (old boards) | Search (scouted) | Search (real board) | Contested |"
    )
    print("|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
    for (pool, rules, name), rows in sorted(groups.items()):
        cells = [
            statistics.fmean(float(r.get(column) or "nan") for r in rows)
            for column in (
                "random_mean",
                "random_worst",
                "random_best",
                "heuristic",
                "search_stale",
                "search_scout",
                "search_real",
            )
        ]
        contested = 100 * sum(1 for r in rows if 0.1 <= float(r["random_mean"]) <= 0.9) / len(rows)
        text = " | ".join(f"{100 * c:.1f}%" for c in cells)
        print(f"| {pool} | {rules or '-'} | {name} | {len(rows)} | {text} | {contested:.0f}% |")


def main(argv: list[str]) -> int:
    folder = Path(argv[1])
    games = [r for r in read_rows(folder, "games") if not r["run"].endswith("_probe")]
    fights = [r for r in read_rows(folder, "fights") if not r["run"].endswith("_probe")]
    print("## Average place\n")
    place_table(games)
    print("\n## Fights by stage\n")
    stage_table(fights)
    probes = read_rows(folder, "probes")
    if probes:
        print("\n## Same board, real opponent: win rate of each way of arranging it\n")
        probe_table(probes)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
