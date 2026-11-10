#!/usr/bin/env python3
"""Summarize wave2b_lines .line-metrics.jsonl without running gameplay.

Growth uses survivor medians, plus an explicitly matched R14-survivor cohort.
Shopping is all-round unique-offer accounting from hard:varied seats only.
"""

import argparse
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

METRICS = ("active_stats", "including_bellies")
ROUNDS = range(8, 15)
TRIBE = "Hedgerow folk"


def ratio(numerator, denominator):
    return numerator / denominator if numerator is not None and denominator else None


def median(values):
    return statistics.median(values) if values else None


def growth(start, end):
    value = ratio(end, start)
    return value ** (1 / 6) if value is not None else None


def _insert(rows, key, row):
    if key in rows and rows[key] != row:
        raise ValueError(f"conflicting duplicate {key}")
    rows[key] = row


def _number(value, label):
    if isinstance(value, bool) or not isinstance(value, (float, int)) or not math.isfinite(value) or value < 0:
        raise ValueError(f"{label} must be a finite nonnegative number")
    return value


def load_records(paths):
    records = []
    for path in paths:
        with Path(path).open(encoding="utf-8") as source:
            for line_number, line in enumerate(source, 1):
                if line.strip():
                    try:
                        records.append(json.loads(line))
                    except json.JSONDecodeError as error:
                        raise ValueError(f"{path}:{line_number}: {error}") from error
    return records


def load_strategies(directory):
    return {
        entry["id"]: entry for path in sorted(Path(directory).glob("*.json")) if (entry := json.loads(path.read_text()))
    }


def primary_tribes(strategy):
    weights = strategy.get("tribes", {})
    if not weights:
        return []
    highest = max(weights.values())
    return sorted(tribe for tribe, weight in weights.items() if weight == highest)


def _shopping_report(shopping, strategies, tribe):
    groups = {name: {"seats": 0, "buys": 0, "unique_offers": 0} for name in ("own_build", "off_build", "unknown_build")}
    raw = []
    for (seed, seat), row in sorted(shopping.items()):
        if row.get("assigned_line") != "hard:varied":
            continue
        build = row.get("build", "")
        primary = primary_tribes(strategies.get(build, {}))
        group = "unknown_build" if build not in strategies else "own_build" if tribe in primary else "off_build"
        buys = _number(row.get("buys_by_tribe", {}).get(tribe, 0), "shopping buys")
        offers = _number(row.get("offers_by_tribe", {}).get(tribe, 0), "shopping offers")
        groups[group]["seats"] += 1
        groups[group]["buys"] += buys
        groups[group]["unique_offers"] += offers
        raw.append(
            {
                "seed": seed,
                "seat": seat,
                "build": build,
                "primary_tribes": primary,
                "group": group,
                "buys": buys,
                "unique_offers": offers,
            }
        )
    for group in groups.values():
        group["buys_per_unique_offer"] = ratio(group["buys"], group["unique_offers"])
    return {
        "tribe": tribe,
        "scope": (
            "All rounds; hard:varied only; committed-line seats and their food purchases excluded. "
            "Unique offers are counted by the harness per seat and unit iid. Grouping uses the final "
            "build's highest declared tribe weights; ties retain every primary tribe. "
            "Known neutral builds count as off-build; missing strategy definitions are separate."
        ),
        "groups": groups,
        "off_vs_own_buy_rate_ratio": ratio(
            groups["off_build"]["buys_per_unique_offer"], groups["own_build"]["buys_per_unique_offer"]
        ),
        "raw_seats": raw,
    }


def summarize(records, strategies, paper_r12=None):
    records = list(records)
    tribes = {record["tribe"] for record in records if "tribe" in record}
    if len(tribes) > 1:
        raise ValueError("mixed measured tribes in one report")
    tribe = next(iter(tribes), TRIBE)
    rows, shopping, lobby_rounds = {}, {}, {}
    for record in records:
        seed = int(record["seed"])
        if "rounds" in record:
            _insert(lobby_rounds, seed, int(record["rounds"]))
        for row in record.get("pre_start", []):
            _insert(rows, (seed, int(row["seat"]), int(row["round"])), row)
        for row in record.get("shopping", []):
            _insert(shopping, (seed, int(row["seat"])), row)
    by_line = defaultdict(dict)
    for key, row in rows.items():
        line = row["assigned_line"]
        if line == "hard:varied":
            continue
        for metric in METRICS:
            _number(row[metric], metric)
        by_line[line][key] = row
    output = {}
    for line, line_rows in sorted(by_line.items()):
        snapshots = {}
        for round_number in ROUNDS:
            current = [row for (_, _, round_id), row in line_rows.items() if round_id == round_number]
            snapshots[str(round_number)] = {
                "survivors": len(current),
                **{metric: median([row[metric] for row in current]) for metric in METRICS},
            }
        cohort = []
        for (seed, seat, round_number), row in sorted(line_rows.items()):
            if round_number != 14:
                continue
            early = line_rows.get((seed, seat, 8))
            if early is not None:
                cohort.append(
                    {
                        "seed": seed,
                        "seat": seat,
                        **{
                            metric: {
                                "r8": early[metric],
                                "r14": row[metric],
                                "growth": growth(early[metric], row[metric]),
                            }
                            for metric in METRICS
                        },
                    }
                )
        reference = paper_r12.get(line) if isinstance(paper_r12, dict) else paper_r12
        if reference is not None:
            _number(reference, "paper R12")
            if reference == 0:
                raise ValueError("paper R12 must be positive")
        output[line] = {
            "rounds": snapshots,
            "survivor_counts": {f"r{number}": snapshots[str(number)]["survivors"] for number in (8, 12, 14)},
            "endpoint_growth": {metric: growth(snapshots["8"][metric], snapshots["14"][metric]) for metric in METRICS},
            "r12_accounting": {
                metric: {
                    "median_divided_by_900": ratio(snapshots["12"][metric], 900),
                    "paper_reference": reference,
                    "median_divided_by_paper": ratio(snapshots["12"][metric], reference),
                }
                for metric in METRICS
            },
            "paired_r14_survivors": {
                "count": len(cohort),
                "metrics": {
                    metric: {
                        "r8_median": median([row[metric]["r8"] for row in cohort]),
                        "r14_median": median([row[metric]["r14"] for row in cohort]),
                        "matched_medians_growth": growth(
                            median([row[metric]["r8"] for row in cohort]),
                            median([row[metric]["r14"] for row in cohort]),
                        ),
                        "median_individual_growth": median(
                            [row[metric]["growth"] for row in cohort if row[metric]["growth"] is not None]
                        ),
                        "individual_growth_samples": sum(row[metric]["growth"] is not None for row in cohort),
                    }
                    for metric in METRICS
                },
                "raw_rows": cohort,
            },
        }
    return {
        "counting": (
            "One row per (seed, seat, round); identical duplicates removed, conflicts rejected. "
            "R8-R14 endpoint growth spans six rounds. Counts are real seats observed at that pre-start bell. "
            "Paired cohort means seats alive entering R14, observed at both R8 and R14; a lone winner in "
            "a lobby ending earlier is absent, not zero. Zero denominators and absent rounds yield null; "
            "zero-start seats stay in raw paired rows but are excluded from individual-growth medians."
        ),
        "seeds": sorted({int(record["seed"]) for record in records}),
        "lobbies_ending_before_r14": {
            "count": sum(rounds < 14 for rounds in lobby_rounds.values()),
            "seeds": sorted(seed for seed, rounds in lobby_rounds.items() if rounds < 14),
            "known_round_counts": len(lobby_rounds),
            "missing_round_counts": len({int(record["seed"]) for record in records} - lobby_rounds.keys()),
        },
        "unique_pre_start_rows": len(rows),
        "lines": output,
        "splash": _shopping_report(shopping, strategies, tribe),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument(
        "--strategies-dir", type=Path, default=Path(__file__).resolve().parents[2] / "content/bots/strategies"
    )
    parser.add_argument("--paper-r12", help="Positive scalar or JSON object mapping assigned line ids to references")
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    try:
        paper = json.loads(args.paper_r12) if args.paper_r12 is not None else None
        if paper is not None and not isinstance(paper, (int, float, dict)):
            raise ValueError("--paper-r12 must be a number or line-to-number JSON object")
        result = summarize(load_records(args.paths), load_strategies(args.strategies_dir), paper)
    except (ValueError, KeyError, TypeError) as error:
        parser.error(str(error))
    rendered = json.dumps(result, indent=2, allow_nan=False) + "\n"
    if args.out:
        args.out.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")


if __name__ == "__main__":
    main()
