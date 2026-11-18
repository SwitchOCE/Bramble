#!/usr/bin/env python3
"""The win-weighted score: points by placement with one extra point for first.

The league is decided on average placement. This is a second score shown beside it, at the
owner's ask (18 Nov 2026): "just give first an extra point ... and see if it changes whose
bot is doing better". Points for 1st to 8th are 9, 7, 6, 5, 4, 3, 2, 1: the usual 8 down
to 1, plus 1 for a win. Higher is better. A team's score is the average over its seats; the
two teams' scores always add up to 9.25.

usage: winscore.py <match-dir> [<match-dir> ...]
"""
import json
import math
import sys
from pathlib import Path

POINTS = {1: 9, 2: 7, 3: 6, 4: 5, 5: 4, 6: 3, 7: 2, 8: 1}


def score(games):
    """games: iterable of game rows from games.jsonl. Returns the two averages, the gap
    (red minus blue) and its 95% half-width over seed pairs, which are the independent unit:
    the two games of a pair share a seed with the colours swapped."""
    pairs, totals, seats = {}, {"red": 0, "blue": 0}, {"red": 0, "blue": 0}
    for g in games:
        by = {"red": [], "blue": []}
        for s in g["seats"]:
            by[s["colour"]].append(POINTS[s["place"]])
        for c in by:
            totals[c] += sum(by[c])
            seats[c] += len(by[c])
        gap = sum(by["red"]) / len(by["red"]) - sum(by["blue"]) / len(by["blue"])
        pairs.setdefault(g["game"] // 2, []).append(gap)
    gaps = [sum(v) / len(v) for v in pairs.values()]
    n = len(gaps)
    mean = sum(gaps) / n
    half = 1.96 * math.sqrt(sum((x - mean) ** 2 for x in gaps) / (n - 1) / n) if n > 1 else float("nan")
    return {"red": totals["red"] / seats["red"], "blue": totals["blue"] / seats["blue"],
            "gap_red_minus_blue": mean, "gap_ci95": half, "seed_pairs": n}


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    print("| Match | Red | Blue | Red − blue (win-weighted, higher is better) | Seed pairs |")
    print("|---|---|---|---|---|")
    for d in map(Path, sys.argv[1:]):
        with open(d / "games.jsonl") as f:
            s = score(json.loads(line) for line in f if line.strip())
        labels = json.load(open(d / "summary.json"))
        print(f"| {d.name} | {labels['red_label']} {s['red']:.3f} | {labels['blue_label']} {s['blue']:.3f} | "
              f"{s['gap_red_minus_blue']:+.3f} ± {s['gap_ci95']:.3f} | {s['seed_pairs']} |")


if __name__ == "__main__":
    main()
