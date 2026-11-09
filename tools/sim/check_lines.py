#!/usr/bin/env python3
"""Known-answer check for a line in the existing head_to_head suite.

The swapped legs are seat controls, not paired shop RNG. Cluster the two legs by
independent seed and require a positive lower 95% Student-t bound on place gain.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

from summarize_bench import paired_margin, t95


def head_to_head(path: Path, plan: dict | None = None) -> dict:
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
    if plan is not None and (
        candidate != plan["candidate"]
        or incumbent != plan["incumbent"]
        or len(gains) != plan["independent_seeds"]
        or sorted(groups) != list(range(plan["seed_range"][0], plan["seed_range"][1] + 1))
    ):
        raise ValueError("comparison or completed seed set differs from the declared plan")
    return {
        "candidate": candidate,
        "incumbent": incumbent,
        "independent_seeds": len(gains),
        "lobbies": 2 * len(gains),
        "seed_range": [min(groups), max(groups)],
        "shop_comparisons": "unpaired; two seat-swapped legs clustered by seed",
        "mean_place_gain": mean,
        "seed_sd": statistics.stdev(gains) if len(gains) >= 2 else None,
        "ci95": [mean - margin, mean + margin],
        "wins": wins,
        "passes": len(gains) >= 2 and mean - margin > 0,
        "plan_validated": plan is not None,
    }


def line_breakdown(path: Path, profiles: dict) -> dict:
    """Exploratory seat-controlled gains, clustered by seed; not extra promotion tests."""
    head_to_head(path)
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream))
    indexed = {(int(row["seed"]), int(row["leg"]), int(row["seat"])): row for row in rows}
    groups = defaultdict(lambda: defaultdict(list))
    for row in rows:
        if row["side"] != "candidate":
            continue
        profile_id = row["strategy"]
        if profile_id not in profiles:
            raise ValueError(f"candidate profile absent from table: {profile_id}")
        other = indexed[int(row["seed"]), 1 - int(row["leg"]), int(row["seat"])]
        difference = float(other["place"]) - float(row["place"])
        tribe = profiles[profile_id]["tribe"] or "Shared"
        for key in (f"tribe:{tribe}", f"line:{profile_id}"):
            groups[key][int(row["seed"])].append(difference)
    report = {}
    for key, clusters in sorted(groups.items()):
        count = sum(len(values) for values in clusters.values())
        mean = sum(sum(values) for values in clusters.values()) / count
        n = len(clusters)
        if n >= 2:
            residual = sum((sum(values) - mean * len(values)) ** 2 for values in clusters.values())
            margin = t95(n - 1) * math.sqrt(n / (n - 1) * residual) / count
            interval = [mean - margin, mean + margin]
        else:
            interval = None
        report[key] = {"candidate_seats": count, "seed_clusters": n, "mean_place_gain": mean, "ci95": interval}
    return {
        "method": "exploratory seat-controlled gains; seed-cluster robust ratio SE; unadjusted intervals",
        "groups": report,
    }


def line_outcome_rates(path: Path) -> dict:
    """Descriptive first/top-four rates; resample complete seed clusters, including both legs."""
    from metrics import clustered_rate

    comparison = head_to_head(path)
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream))
    groups = defaultdict(list)
    for row in rows:
        line = row["strategy"] if row["side"] == "candidate" else comparison["incumbent"]
        groups[line].append(row)
    result = {}
    for line, values in sorted(groups.items()):
        result[line] = {
            "side": values[0]["side"],
            "seats": len(values),
            "first_place": clustered_rate([(int(r["seed"]), int(r["place"]) == 1, 1) for r in values]),
            "top_four": clustered_rate([(int(r["seed"]), int(r["place"]) <= 4, 1) for r in values]),
        }
    return {
        "method": "observed seat rates; 2000 fixed bootstrap draws of whole independent seeds, both legs together",
        "scope": "descriptive line breakdown, not additional superiority tests or matched shop comparisons",
        "boundary_note": "empirical bootstrap intervals can collapse at zero/one; "
        "not proof of a zero/one population rate",
        "lines": result,
    }


def validate_profiles(path: Path, plan: dict) -> None:
    if hashlib.sha256(path.read_bytes()).hexdigest() != plan["profiles_sha256"]:
        raise ValueError("profile table differs from the frozen plan")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("players", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--plan", type=Path, help="require the complete predeclared comparison and seeds")
    parser.add_argument("--profiles", type=Path, help="include exploratory per-line and per-tribe diagnostics")
    args = parser.parse_args()
    plan = json.loads(args.plan.read_text()) if args.plan else None
    report = head_to_head(args.players, plan)
    if args.profiles:
        if plan and "profiles_sha256" in plan:
            validate_profiles(args.profiles, plan)
            report["profiles_validated"] = True
        report["breakdown"] = line_breakdown(args.players, json.loads(args.profiles.read_text()))
    rendered = json.dumps(report, indent=2) + "\n"
    if args.out:
        args.out.write_text(rendered)
    print(rendered, end="")
    raise SystemExit(0 if report["passes"] else 1)


if __name__ == "__main__":
    main()
