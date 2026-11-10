#!/usr/bin/env python3
"""Deterministic percentile bootstrap intervals from raw wave2b line metrics.

Examples: python3 -m tools.checks.growth_intervals metrics.jsonl --out ci.json
Or repeat --dataset control=PATH --dataset A=PATH to keep arms independent.
No gameplay runs; only the two endpoint observations enter the growth estimates.
"""

import argparse
import hashlib
import json
import math
import random
import statistics
from collections import defaultdict
from pathlib import Path

METRICS = ("active_stats", "including_bellies")


def median(values):
    return statistics.median(values) if values else None


def growth(start, end):
    return (end / start) ** (1 / 6) if start and end is not None else None


def percentile(values, probability):
    """Linear interpolation at (n-1)*p (the common type-7 sample quantile)."""
    values = sorted(values)
    if not values:
        return None
    at = (len(values) - 1) * probability
    lower = math.floor(at)
    upper = math.ceil(at)
    return values[lower] + (values[upper] - values[lower]) * (at - lower)


def interval(estimate, samples, **counts):
    valid = [value for value in samples if value is not None]
    return {
        "estimate": estimate,
        "ci90": [percentile(valid, 0.05), percentile(valid, 0.95)],
        "valid_bootstrap_draws": len(valid),
        **counts,
    }


def _rng(seed, label):
    digest = hashlib.sha256(f"{seed}:{label}".encode()).digest()
    return random.Random(int.from_bytes(digest, "big"))


def _insert(target, key, row):
    if key in target and target[key] != row:
        raise ValueError(f"conflicting duplicate {key}")
    target[key] = row


def _validate(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
        raise ValueError("stats must be finite nonnegative numbers")


def summarize(records, draws=20000, seed=20261110):
    if draws < 1:
        raise ValueError("draws must be positive")
    rows, rounds, seeds = {}, {}, set()
    for record in records:
        lobby = int(record["seed"])
        seeds.add(lobby)
        if "rounds" in record:
            _insert(rounds, lobby, int(record["rounds"]))
        for row in record.get("pre_start", []):
            _insert(rows, (lobby, int(row["seat"]), int(row["round"])), row)
    by_line = defaultdict(dict)
    for key, row in rows.items():
        if row["assigned_line"] == "hard:varied":
            continue
        for metric in METRICS:
            _validate(row[metric])
        by_line[row["assigned_line"]][key] = row
    result = {}
    for line, values in sorted(by_line.items()):
        pairs = [
            (values[(lobby, seat, 8)], row)
            for (lobby, seat, round_id), row in sorted(values.items())
            if round_id == 14 and (lobby, seat, 8) in values
        ]
        endpoints = {
            round_id: [row for (_, _, current), row in values.items() if current == round_id]
            for round_id in (8, 12, 14)
        }
        clusters = {
            lobby: {
                round_id: [
                    row
                    for (current_seed, _, current_round), row in values.items()
                    if current_seed == lobby and current_round == round_id
                ]
                for round_id in (8, 14)
            }
            for lobby in sorted(seeds)
        }
        paired_samples = {metric: {"matched": [], "individual": []} for metric in METRICS}
        survivor_samples = {metric: [] for metric in METRICS}
        paired_rng, cluster_rng = _rng(seed, line + ":pairs"), _rng(seed, line + ":lobbies")
        lobby_ids = sorted(seeds)
        for _draw in range(draws):
            selected_pairs = [pairs[paired_rng.randrange(len(pairs))] for _ in pairs]
            selected_lobbies = [lobby_ids[cluster_rng.randrange(len(lobby_ids))] for _ in lobby_ids]
            selected_early = [row for lobby in selected_lobbies for row in clusters[lobby][8]]
            selected_late = [row for lobby in selected_lobbies for row in clusters[lobby][14]]
            for metric in METRICS:
                starts = [first[metric] for first, _last in selected_pairs]
                ends = [last[metric] for _first, last in selected_pairs]
                individual = [
                    growth(first[metric], last[metric]) for first, last in selected_pairs if first[metric] > 0
                ]
                paired_samples[metric]["matched"].append(growth(median(starts), median(ends)))
                paired_samples[metric]["individual"].append(median(individual))
                survivor_samples[metric].append(
                    growth(
                        median([row[metric] for row in selected_early]), median([row[metric] for row in selected_late])
                    )
                )
        estimates = {}
        for metric in METRICS:
            starts, ends = [first[metric] for first, _last in pairs], [last[metric] for _first, last in pairs]
            individual = [growth(first[metric], last[metric]) for first, last in pairs if first[metric] > 0]
            counts = {"r8_n": len(starts), "r14_n": len(ends), "cohort_n": len(pairs)}
            estimates[metric] = {
                "matched_medians_primary": interval(
                    growth(median(starts), median(ends)), paired_samples[metric]["matched"], **counts
                ),
                "individual_median_diagnostic": interval(
                    median(individual),
                    paired_samples[metric]["individual"],
                    eligible_positive_start_n=len(individual),
                    **counts,
                ),
                "changing_survivor_medians": interval(
                    growth(
                        median([row[metric] for row in endpoints[8]]), median([row[metric] for row in endpoints[14]])
                    ),
                    survivor_samples[metric],
                    r8_n=len(endpoints[8]),
                    r14_n=len(endpoints[14]),
                    lobby_seed_n=len(seeds),
                ),
            }
        result[line] = {
            "endpoint_counts": {f"r{round_id}": len(endpoints[round_id]) for round_id in (8, 12, 14)},
            "paired_cohort_n": len(pairs),
            "lobby_seed_n": len(seeds),
            "metrics": estimates,
        }
    return {
        "method": (
            "90% percentile intervals (5th/95th, linear type-7 quantiles), sampling with replacement. "
            "Primary and individual diagnostic resample matched (seed, seat) R8/R14 pairs together, "
            "using the same sampled pairs for both metrics and estimates. These are seats observed alive "
            "entering R14, not inferred final winners. Changing-survivor estimates resample whole lobby seeds "
            "with both endpoints, preserving within-lobby observations and missing/eliminated seats. "
            "All recorded lobby seeds participate, including early-ended lobbies. No absent seats become zeros. "
            "Null/zero starting medians produce undefined draws; intervals use valid draws only and disclose "
            "their count. Individual growth omits zero-start pairs. No cross-arm difference interval is implied."
        ),
        "draws": draws,
        "seed": seed,
        "lobby_seed_n": len(seeds),
        "lobbies_ending_before_r14": sum(value < 14 for value in rounds.values()),
        "missing_lobby_round_counts": len(seeds - rounds.keys()),
        "lines": result,
    }


def load_records(paths):
    return [json.loads(line) for path in paths for line in Path(path).read_text().splitlines() if line.strip()]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--dataset", action="append", default=[], metavar="NAME=PATH")
    parser.add_argument("--draws", type=int, default=20000)
    parser.add_argument("--seed", type=int, default=20261110)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    groups = defaultdict(list)
    if args.paths:
        groups["default"].extend(args.paths)
    try:
        for declaration in args.dataset:
            name, path = declaration.split("=", 1)
            if not name or not path:
                raise ValueError("--dataset requires NAME=PATH")
            groups[name].append(Path(path))
        if not groups:
            raise ValueError("supply raw JSONL paths or --dataset NAME=PATH")
        report = {name: summarize(load_records(paths), args.draws, args.seed) for name, paths in groups.items()}
    except (ValueError, KeyError, OSError, TypeError) as error:
        parser.error(str(error))
    rendered = json.dumps(report, indent=2, allow_nan=False) + "\n"
    if args.out:
        args.out.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
