#!/usr/bin/env python3
"""Feel metrics in stats; outcome metrics in placements and repeated weighted field fights."""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
import statistics
from collections import defaultdict
from pathlib import Path

from field import boards_from_capture


def percentile(values, q):
    values = sorted(values)
    if not values:
        return None
    index = (len(values) - 1) * q
    low, high = math.floor(index), math.ceil(index)
    return values[low] + (values[high] - values[low]) * (index - low)


def distribution(values):
    return {"n": len(values), **{f"p{int(q * 100)}": percentile(values, q) for q in (0.5, 0.9, 0.99)}}


def clustered_rate(observations, replicates=2000):
    """(seed, numerator, denominator); resample whole seeds, never individual seats."""
    groups = defaultdict(lambda: [0, 0])
    for seed, numerator, denominator in observations:
        groups[seed][0] += numerator
        groups[seed][1] += denominator
    rows = list(groups.values())
    total = sum(row[1] for row in rows)
    if not total:
        return {"n": 0, "rate": None, "ci95": None}
    rng = random.Random(14507)
    estimates = []
    if len(rows) >= 2:
        for _ in range(replicates):
            chosen = rng.choices(rows, k=len(rows))
            denominator = sum(row[1] for row in chosen)
            if denominator:
                estimates.append(sum(row[0] for row in chosen) / denominator)
    return {
        "n": total,
        "seed_clusters": len(rows),
        "rate": sum(row[0] for row in rows) / total,
        "ci95": [percentile(estimates, 0.025), percentile(estimates, 0.975)] if estimates else None,
    }


def compact_boards(boards, catalog):
    previous, pending = {}, {}
    compact, arrivals = [], []
    for board in boards:
        key = (board["seed"], board["leg"], board["seat"])
        old = previous.get(key)
        snapshot = board["combat_start"]
        active = [unit for unit in snapshot["units"] if unit["active"]]
        stats = snapshot["active_stats"]
        median_unit = statistics.median([u["attack"] + u["health"] for u in active]) if active else 0
        ids = {unit.get("iid") for unit in board["board"] if unit is not None and unit.get("iid") is not None}
        row = {
            "seed": board["seed"],
            "leg": board["leg"],
            "seat": board["seat"],
            "round": board["round"],
            "tier": int(board["tier"]),
            "line": board["line"],
            "stats": stats,
            "health": snapshot["health"],
            "largest_share": snapshot["largest_share"],
            "stats_per_gold": stats / snapshot["gold_spent_game"] if snapshot["gold_spent_game"] else None,
            "growth_delta": stats - old["stats"] if old else None,
            "growth_ratio": stats / old["stats"] if old and old["stats"] else None,
            "median_unit": median_unit,
            "ids": ids,
        }
        row["growth_per_gold"] = (
            row["growth_delta"] / snapshot["gold_spent_turn"] if old and snapshot["gold_spent_turn"] else None
        )
        row["reserves"] = {
            location: sum(
                u["attack"] + u["health"] for u in snapshot["units"] if not u["active"] and u["location"] == location
            )
            for location in {u["location"] for u in snapshot["units"] if not u["active"]}
        }
        if old and old["median_unit"]:
            for tier in range(old["tier"] + 1, row["tier"] + 1):
                pending[key, tier] = old["median_unit"]
            for unit in active:
                spec = board["board"][unit["slot"]]
                tier = int(unit["tier"])
                if spec.get("iid") in old["ids"] or (key, tier) not in pending:
                    continue
                denominator = pending.pop((key, tier))
                definition = catalog.get(unit["def_id"])
                printed = (
                    (definition["attack"] + definition["health"]) * (2 if unit["golden"] else 1) if definition else None
                )
                arrivals.append(
                    {
                        "seed": row["seed"],
                        "round": row["round"],
                        "tier": tier,
                        "arrival_ratio": (unit["attack"] + unit["health"]) / denominator,
                        "printed_ratio": printed / denominator if printed is not None else None,
                    }
                )
        previous[key] = row
        compact.append(row)
    return compact, arrivals


def round_stats(rows):
    stats = [row["stats"] for row in rows]
    median = statistics.median(stats)
    return {
        "stats": distribution(stats),
        "share_2x_round_median": sum(value >= 2 * median for value in stats) / len(stats) if median else None,
        **{
            key: distribution([row[key] for row in rows if row[key] is not None])
            for key in ["growth_delta", "growth_ratio", "growth_per_gold", "stats_per_gold", "largest_share"]
        },
        "reserve_stats": {
            loc: distribution([row["reserves"].get(loc, 0) for row in rows])
            for loc in sorted({loc for row in rows for loc in row["reserves"]})
        },
    }


def summarize(boards, players, catalog=None, field=None):
    rows, arrivals = compact_boards(boards, catalog or {})
    by_round, by_line, games = defaultdict(list), defaultdict(list), defaultdict(list)
    for row in rows:
        by_round[row["round"]].append(row)
        by_line[row["line"], row["round"]].append(row)
        if row["round"] == 8:
            games[row["seed"], row["leg"]].append(row)
    places = {(int(r["seed"]), int(r.get("leg", 0)), int(r["seat"])): int(r["place"]) for r in players}
    leader, health_leader, below, below_local = [], [], [], []
    pooled_median = statistics.median([r["stats"] for r in by_round[8]]) if by_round[8] else None
    for (seed, leg), game in games.items():
        for metric, output in [("stats", leader), ("health", health_leader)]:
            maximum = max(r[metric] for r in game)
            leaders = [r for r in game if r[metric] == maximum]
            output.append((seed, sum(places[seed, leg, r["seat"]] == 1 for r in leaders) / len(leaders), 1))
        local_median = statistics.median([r["stats"] for r in game])
        for row in game:
            top2 = places[seed, leg, row["seat"]] <= 2
            if row["stats"] < pooled_median:
                below.append((seed, top2, 1))
            if row["stats"] < local_median:
                below_local.append((seed, top2, 1))
    medians = [
        (r, statistics.median([x["stats"] for x in values]))
        for r, values in sorted(by_round.items())
        if 6 <= r <= 16 and values
    ]
    flat = {"round_range": [6, 16], "linear_r2": None, "slope": None, "two_x_boards": 0}
    if len(medians) >= 3:
        xs, ys = zip(*medians, strict=True)
        mx, my = statistics.mean(xs), statistics.mean(ys)
        slope = sum((x - mx) * (y - my) for x, y in medians) / sum((x - mx) ** 2 for x in xs)
        error = sum((y - my - slope * (x - mx)) ** 2 for x, y in medians)
        total = sum((y - my) ** 2 for y in ys)
        flat.update(linear_r2=1 - error / total if total else 1.0, slope=slope)
        flat["two_x_boards"] = sum(
            sum(row["stats"] >= 2 * statistics.median([x["stats"] for x in values]) for row in values)
            for number, values in by_round.items()
            if 6 <= number <= 16 and values
        )
    flat["matches_historical_flat_shape"] = (
        flat["linear_r2"] is not None and flat["linear_r2"] >= 0.95 and flat["two_x_boards"] == 0
    )
    outcomes = {
        "r8_stat_leader_wins": clustered_rate(leader),
        "r8_health_leader_wins": clustered_rate(health_leader),
        "r8_below_pooled_median_top2": clustered_rate(below),
        "r8_below_lobby_median_top2": clustered_rate(below_local),
        "winner_final_round": distribution([int(p["rounds"]) for p in players if int(p["place"]) == 1]),
    }
    if field:
        pairs = [p for p in field["pairs"] if 10 <= int(p["round"]) <= 14]
        uncertain = [p for p in pairs if p["p_win_a"] is not None and 0.2 <= p["p_win_a"] <= 0.8]
        mass = sum(p["pair_weight"] for p in pairs)
        outcomes["field_uncertainty_r10_14"] = {
            "pairs": len(pairs),
            "share_20_80": len(uncertain) / len(pairs) if pairs else None,
            "weighted_share_20_80": sum(p["pair_weight"] for p in uncertain) / mass if mass else None,
            "all_draw_pair_share": sum(p["p_win_a"] is None for p in pairs) / len(pairs) if pairs else None,
            "share_ci_wholly_20_80": sum(
                p["p_win_a_ci95"] is not None and p["p_win_a_ci95"][0] >= 0.2 and p["p_win_a_ci95"][1] <= 0.8
                for p in pairs
            )
            / len(pairs)
            if pairs
            else None,
        }
    return {
        "rounds": {str(r): round_stats(values) for r, values in sorted(by_round.items()) if values},
        "within_line": {
            line: {str(r): round_stats(values) for (name, r), values in sorted(by_line.items()) if name == line}
            for line in sorted({line for line, _ in by_line})
        },
        "tier_arrivals": {
            str(tier): {
                key: distribution([r[key] for r in arrivals if r["tier"] == tier and r[key] is not None])
                for key in ["arrival_ratio", "printed_ratio"]
            }
            for tier in range(2, 7)
        },
        "outcomes": outcomes,
        "historical_flat_shape_check": flat,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", type=Path, nargs="+")
    parser.add_argument("--players", type=Path, nargs="+", required=True)
    parser.add_argument("--field", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--markdown", type=Path)
    args = parser.parse_args()
    players = []
    for path in args.players:
        with path.open(newline="") as stream:
            players.extend(csv.DictReader(stream))
    catalog = {
        data["id"]: data for path in Path("content/units").glob("*.json") if (data := json.loads(path.read_text()))
    }
    result = summarize(
        boards_from_capture(args.captures, require_blind=False),
        players,
        catalog,
        json.loads(args.field.read_text()) if args.field else None,
    )
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    if args.markdown:
        lines = [
            "# Harness measurements\n",
            "Stats describe feel; field win rates rank boards. Round summaries include survivors only.\n",
            "| Round | Boards | p50 | p90 | p99 | Share >=2x median |",
            "|---|---:|---:|---:|---:|---:|",
        ]
        for r, value in result["rounds"].items():
            d = value["stats"]
            share = value["share_2x_round_median"]
            lines.append(
                f"| {r} | {d['n']} | {d['p50']:.1f} | {d['p90']:.1f} | {d['p99']:.1f} | {share:.3f} |"
                if share is not None
                else f"| {r} | {d['n']} | 0 | 0 | 0 | undefined |"
            )
        lines.extend(
            [
                "\nOutcome metrics (bootstrap whole seed clusters; ties split leader credit):\n",
                "```json",
                json.dumps(result["outcomes"], indent=2),
                "```",
                "\nComplete feel, per-line, tier-arrival and concentration metrics are in the accompanying JSON.",
            ]
        )
        args.markdown.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
