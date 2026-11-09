#!/usr/bin/env python3
"""Known-answer check for a line in the existing head_to_head suite.

The swapped legs are seat controls, not paired shop RNG. Cluster the two legs by
independent seed and require a positive lower 95% Student-t bound on place gain.
"""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path

from summarize_bench import paired_margin


def head_to_head(path: Path) -> dict:
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream))
    groups = defaultdict(list)
    labels = {(row["candidate"], row["incumbent"]) for row in rows}
    if len(labels) != 1:
        raise ValueError("expected one comparison")
    for row in rows:
        groups[int(row["seed"])].append(row)
    gains = []
    wins = {"candidate": 0, "incumbent": 0}
    for seed, group in sorted(groups.items()):
        indexed = {(int(row["leg"]), int(row["seat"])): row for row in group}
        if len(group) != 16 or len(indexed) != 16:
            raise ValueError(f"seed {seed}: incomplete or duplicate legs")
        differences = []
        for leg in range(2):
            game = [indexed[leg, seat] for seat in range(8)]
            sides = {side: [row for row in game if row["side"] == side] for side in wins}
            if any(len(side) != 4 for side in sides.values()):
                raise ValueError(f"seed {seed}: expected four seats per side")
            for seat in range(8):
                if indexed[0, seat]["side"] == indexed[1, seat]["side"]:
                    raise ValueError(f"seed {seed}: labels did not swap")
            differences.append(
                sum(float(row["place"]) for row in sides["incumbent"]) / 4
                - sum(float(row["place"]) for row in sides["candidate"]) / 4
            )
            for side, side_rows in sides.items():
                wins[side] += sum(int(row["place"]) == 1 for row in side_rows)
        gains.append(sum(differences) / 2)
    mean, margin = paired_margin(gains)
    candidate, incumbent = labels.pop()
    return {
        "candidate": candidate,
        "incumbent": incumbent,
        "independent_seeds": len(gains),
        "lobbies": 2 * len(gains),
        "seed_range": [min(groups), max(groups)],
        "shop_comparisons": "unpaired; two seat-swapped legs clustered by seed",
        "mean_place_gain": mean,
        "ci95": [mean - margin, mean + margin],
        "wins": wins,
        "passes": len(gains) >= 2 and mean - margin > 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("players", type=Path)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    report = head_to_head(args.players)
    rendered = json.dumps(report, indent=2) + "\n"
    if args.out:
        args.out.write_text(rendered)
    print(rendered, end="")
    raise SystemExit(0 if report["passes"] else 1)


if __name__ == "__main__":
    main()
