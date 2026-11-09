#!/usr/bin/env python3
"""Read frozen lever-build superiority tests without running Godot.

Usage: strength_gate.py summarize PLAN --inputs DIR --out gate.json
PLAN version 1 has source_commit, source_fingerprint, profiles_sha256 (hex),
profiles (path), and builds=[{id: g25|g50, overrides: {...}, comparisons:
[{id: best|mixture, candidate: line_hedgerow_tempo|tribal_mixture,
incumbent: hard_field, independent_seeds: 80, first_seed: N}]}]. All four seed
ranges must be disjoint. No selection/tuning is performed by this reader.

DIR contains BUILD-COMPARISON.players.csv and BUILD-COMPARISON.run.json.
Each run metadata object must have completed=true, plan_sha256=digest(PLAN),
source_commit/source_fingerprint/profiles_sha256 equal to PLAN,
config_sha256=digest(build.overrides), and players_sha256=file_sha(CSV).
The writer must record those values from the actual invocation; matching hashes
verify artifact consistency, not the truth of a remote execution. Caps-screen
results and source gate provenance remain separate prerequisites.

Both best-line intervals must exclude zero positively to open the primary gate.
Mixture results are independent diagnostic comparisons and never replaced by a
maximum that includes Hard. Each interval is two-sided 95%, not family adjusted.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path

from check_lines import head_to_head, line_outcome_rates
from lever_sweep import atomic_json, digest, file_sha


def validate_plan(plan):
    if plan.get("version") != 1:
        raise ValueError("expected strength plan version 1")
    for key, length in (("source_commit", 40), ("source_fingerprint", 64), ("profiles_sha256", 64)):
        if not re.fullmatch(f"[0-9a-f]{{{length}}}", str(plan.get(key, ""))):
            raise ValueError(f"invalid frozen {key}")
    if not isinstance(plan.get("profiles"), str) or not plan["profiles"]:
        raise ValueError("missing frozen profiles path")
    builds = plan.get("builds", [])
    if len(builds) != 2 or {build.get("id") for build in builds} != {"g25", "g50"}:
        raise ValueError("require exactly the frozen g25 and g50 builds")
    seen = set()
    for build in builds:
        if not isinstance(build.get("overrides"), dict) or not build["overrides"]:
            raise ValueError("missing full build overrides")
        comparisons = build.get("comparisons", [])
        if len(comparisons) != 2 or {item.get("id") for item in comparisons} != {"best", "mixture"}:
            raise ValueError("require both best and mixture comparisons for each build")
        for comparison in comparisons:
            expected = "line_hedgerow_tempo" if comparison["id"] == "best" else "tribal_mixture"
            if comparison.get("candidate") != expected or comparison.get("incumbent") != "hard_field":
                raise ValueError("candidate/incumbent differs from the frozen blind comparison")
            first = comparison.get("first_seed")
            if type(first) is not int or first < 0 or comparison.get("independent_seeds") != 80:
                raise ValueError("require a predeclared nonnegative seed range of exactly 80 independent seeds")
            seeds = set(range(first, first + 80))
            if seen & seeds:
                raise ValueError("strength comparison seed ranges overlap")
            seen.update(seeds)
    return plan


def validate_metadata(plan, build, metadata, players):
    expected = {
        "completed": True,
        "plan_sha256": digest(plan),
        "source_commit": plan["source_commit"],
        "source_fingerprint": plan["source_fingerprint"],
        "profiles_sha256": plan["profiles_sha256"],
        "config_sha256": digest(build["overrides"]),
        "players_sha256": file_sha(players),
    }
    for key, value in expected.items():
        if metadata.get(key) != value or (key == "completed" and metadata.get(key) is not True):
            raise ValueError(f"run provenance mismatch: {key}")
    return expected


def validate_placements(players):
    groups = {}
    with players.open(newline="") as stream:
        for row in csv.DictReader(stream):
            groups.setdefault((int(row["seed"]), int(row["leg"])), []).append(int(row["place"]))
    if any(sorted(places) != list(range(1, 9)) for places in groups.values()):
        raise ValueError("each lobby must contain all eight unique placements")


def summarize(plan, inputs):
    validate_plan(plan)
    inputs = Path(inputs)
    builds = {}
    for build in plan["builds"]:
        results = {}
        for comparison in build["comparisons"]:
            name = f"{build['id']}-{comparison['id']}"
            players = inputs / f"{name}.players.csv"
            metadata_path = inputs / f"{name}.run.json"
            metadata = json.loads(metadata_path.read_text())
            provenance = validate_metadata(plan, build, metadata, players)
            validate_placements(players)
            declared = {
                **comparison,
                "seed_range": [comparison["first_seed"], comparison["first_seed"] + 79],
            }
            result = head_to_head(players, declared)
            result["line_outcome_rates"] = line_outcome_rates(players)
            result["provenance"] = {**provenance, "metadata_sha256": file_sha(metadata_path)}
            results[comparison["id"]] = result
        builds[build["id"]] = {
            "overrides": build["overrides"],
            "config_sha256": digest(build["overrides"]),
            "comparisons": results,
            "passes": results["best"]["passes"],
        }
    return {
        "version": 1,
        "passes": all(build["passes"] for build in builds.values()),
        "primary_rule": "best predeclared line has positive lower two-sided 95% seed-cluster bound on both builds",
        "mixture_role": "separate fixed diagnostic; no maximum including Hard, no sample extension or selection",
        "interval_scope": "per-comparison 95%; not simultaneous family-adjusted intervals",
        "shop_comparisons": "unpaired; two seat-swapped legs clustered by independent seed",
        "plan_sha256": digest(plan),
        "source_commit": plan["source_commit"],
        "source_fingerprint": plan["source_fingerprint"],
        "profiles_sha256": plan["profiles_sha256"],
        "builds": builds,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["summarize"])
    parser.add_argument("plan", type=Path)
    parser.add_argument("--inputs", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    report = summarize(json.loads(args.plan.read_text()), args.inputs)
    atomic_json(args.out, report)
    print(json.dumps({"passes": report["passes"], "out": str(args.out)}))
    return 0 if report["passes"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
