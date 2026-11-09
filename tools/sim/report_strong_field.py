#!/usr/bin/env python3
"""Report the fixed 40-game field comparison, conditional on its captured library.

Seeds reproduce each arm, but shop RNG is not matched across modes. Intervals are
unpaired: independent-game standard errors with t(39)=2.02269. For a difference
between two n=40 means this is conservative relative to Welch's critical value.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import statistics
from pathlib import Path

T39 = 2.0226909200367605


def summary(rows, key):
    values = [row[key] for row in rows]
    mean = statistics.mean(values)
    variance = statistics.variance(values)
    half = T39 * math.sqrt(variance / len(values))
    return {"mean": mean, "ci95": [mean - half, mean + half], "variance": variance}


def compare(left, right):
    a, b = summary(left, "place"), summary(right, "place")
    effect = a["mean"] - b["mean"]
    half = T39 * math.sqrt(a["variance"] / len(left) + b["variance"] / len(right))
    return {"mean_place_difference": effect, "ci95": [effect - half, effect + half]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    arms = {}
    for arm in ("normal", "all", "top4"):
        path = args.directory / f"{arm}-40.jsonl"
        rows = [json.loads(line) for line in path.read_text().splitlines()]
        assert len(rows) == 40 and [row["seed"] for row in rows] == list(range(1000, 1040)), path
        assert all(1 <= row["place"] <= 8 for row in rows), path
        arms[arm] = rows
    report = {
        "games_per_arm": 40,
        "seeds": [1000, 1039],
        "library_sha256": hashlib.sha256(args.library.read_bytes()).hexdigest(),
        "interval": "independent seed-games; mean +/- t39 * SE; unpaired conservative difference intervals",
        "scope": "conditional on the fixed captured baseline library and rules; no matched-shop-RNG claim",
        "normal_source": "9af89c2 original archive, same baseline content and normal rules",
        "switch_scope": "complete lobby through all placements; rivals and independent ghost separately",
        "arms": {},
        "top4_minus_normal": compare(arms["top4"], arms["normal"]),
        "all_minus_normal": compare(arms["all"], arms["normal"]),
    }
    lines = [
        (
            "| Opponents | Games | Mean Hard place (95% CI) | Wins | "
            "Rival switches/game | Ghost switches/game | Total switches/game |"
        ),
        "| --- | ---: | --- | ---: | ---: | ---: | ---: |",
    ]
    for arm, rows in arms.items():
        result = {
            key: summary(rows, key)
            for key in ("place", "switches", "rival_switches", "ghost_switches", "switches_before_human_end")
        }
        result["wins"] = sum(row["place"] == 1 for row in rows)
        report["arms"][arm] = result
        place = result["place"]
        lo, hi = place["ci95"]
        lines.append(
            f"| {arm} | 40 | {place['mean']:.2f} [{lo:.2f}, {hi:.2f}] | {result['wins']} | "
            f"{result['rival_switches']['mean']:.2f} | {result['ghost_switches']['mean']:.2f} | "
            f"{result['switches']['mean']:.2f} |"
        )
    args.out.write_text(json.dumps(report, indent=2) + "\n")
    print("\n".join(lines))
    difference = report["top4_minus_normal"]
    print(f"top4 minus normal: {difference['mean_place_difference']:.3f}, 95% CI {difference['ci95']}")


if __name__ == "__main__":
    main()
