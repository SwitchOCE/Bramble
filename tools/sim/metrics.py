#!/usr/bin/env python3
"""Feel metrics in stats; outcome metrics in placements and repeated weighted field fights."""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
import statistics
from collections import Counter, defaultdict
from itertools import pairwise
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
        before = board["combat_start"]
        after = board.get("after_start_effects")
        snapshot = {**before, **after} if after is not None else before
        if after is not None:
            snapshot["units"] = after["units"] + [u for u in before["units"] if not u["active"]]
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
            "pre_start_stats": before["active_stats"],
            "start_effect_delta": stats - before["active_stats"],
            "stats_phase": "after_start_effects" if after is not None else "pre_start_fallback",
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
                if not isinstance(spec, dict) or spec.get("def_id", unit["def_id"]) != unit["def_id"]:
                    continue
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
            for key in [
                "growth_delta",
                "growth_ratio",
                "growth_per_gold",
                "stats_per_gold",
                "largest_share",
                "pre_start_stats",
                "start_effect_delta",
            ]
        },
        "reserve_stats": {
            loc: distribution([row["reserves"].get(loc, 0) for row in rows])
            for loc in sorted({loc for row in rows for loc in row["reserves"]})
        },
    }


def curvature_check(medians):
    """Fixed descriptive curvature tolerances; a 15%-per-round positive control must fail flatness."""
    result = {
        "round_range": [6, 16],
        "rounds": len(medians),
        "linear_r2": None,
        "slope": None,
        "linear_relative_rmse": None,
        "late_early_growth_ratio": None,
        "relative_rmse_limit": 0.05,
        "growth_ratio_tolerance": 0.25,
        "flat": None,
    }
    if len(medians) < 6:
        return result
    xs, ys = zip(*medians, strict=True)
    mx, my = statistics.mean(xs), statistics.mean(ys)
    slope = sum((x - mx) * (y - my) for x, y in medians) / sum((x - mx) ** 2 for x in xs)
    residual = sum((y - my - slope * (x - mx)) ** 2 for x, y in medians)
    total = sum((y - my) ** 2 for y in ys)
    increments = [(b[1] - a[1]) / (b[0] - a[0]) for a, b in pairwise(medians)]
    width = max(2, len(increments) // 3)
    early, late = statistics.mean(increments[:width]), statistics.mean(increments[-width:])
    ratio = late / early if early > 0 else (1.0 if late == early else None)
    relative = math.sqrt(residual / len(medians)) / abs(my) if my else (0.0 if residual == 0 else None)
    result.update(
        linear_r2=1 - residual / total if total else 1.0,
        slope=slope,
        linear_relative_rmse=relative,
        late_early_growth_ratio=ratio,
        flat=relative is not None and relative <= 0.05 and ratio is not None and abs(ratio - 1) <= 0.25,
    )
    return result


def curvature_with_intervals(rows, replicates=2000, bootstrap_seed=14519):
    """Resample entire independent seeds, retaining their seats, legs and surviving rounds.

    This estimates uncertainty in the observed survivor median curve. It cannot
    remove the change in the population caused by eliminations at later rounds.
    """
    if type(replicates) is not int or replicates < 1:
        raise ValueError("curvature bootstrap requires a positive fixed replicate budget")
    groups = defaultdict(lambda: defaultdict(Counter))
    for row in rows:
        number = int(row["round"])
        if 6 <= number <= 16:
            groups[int(row["seed"])][number][row["stats"]] += 1
    rounds = sorted({number for group in groups.values() for number in group})
    values = {
        number: sorted({value for group in groups.values() for value in group.get(number, {})}) for number in rounds
    }

    def medians(weights):
        totals = {number: Counter() for number in rounds}
        for seed, weight in weights.items():
            for number, counts in groups[seed].items():
                target = totals[number]
                for value, count in counts.items():
                    target[value] += weight * count
        output = []
        for number in rounds:
            counts = totals[number]
            size = sum(counts.values())
            if not size:
                return None  # Do not silently fit a different round grid in this draw.
            lower, upper = (size - 1) // 2, size // 2
            seen = 0
            middle = []
            for value in values[number]:
                count = counts[value]
                if seen <= lower < seen + count:
                    middle.append(value)
                if seen <= upper < seen + count:
                    middle.append(value)
                    break
                seen += count
            output.append((number, sum(middle) / 2))
        return output

    result = curvature_check(medians(dict.fromkeys(groups, 1)) or [])
    estimates = {key: [] for key in ("linear_relative_rmse", "late_early_growth_ratio")}
    supported = 0
    if len(groups) >= 2 and result["flat"] is not None:
        rng = random.Random(bootstrap_seed)
        seeds = sorted(groups)
        for _ in range(replicates):
            sample = medians(Counter(rng.choices(seeds, k=len(seeds))))
            if sample is None:
                continue
            supported += 1
            draw = curvature_check(sample)
            for key in estimates:
                if draw[key] is not None:
                    estimates[key].append(draw[key])
    for key, draws in estimates.items():
        result[f"{key}_ci95"] = [percentile(draws, 0.025), percentile(draws, 0.975)] if draws else None
    result["uncertainty"] = {
        "method": "percentile bootstrap of whole independent seeds, all seats/legs/rounds together",
        "seed_clusters": len(groups),
        "replicates": replicates,
        "bootstrap_seed": bootstrap_seed,
        "supported_round_grid_draws": supported,
        "valid_draws": {key: len(draws) for key, draws in estimates.items()},
        "scope": "uncertainty in the pooled observed survivor-median curve, not within-player compounding",
        "limitations": "late medians contain survivors only; bootstrap does not remove elimination selection",
    }
    return result


def checkpoint_growth(rows, replicates=2000, bootstrap_seed=14531):
    """R8–R14 survivor-median growth; pre-start is the deciding measurement.

    Sample whole independent seeds, retaining their seats, legs and surviving
    rounds together. Post-start fallbacks are not post-start observations.
    """
    if type(replicates) is not int or replicates < 1:
        raise ValueError("growth bootstrap requires a positive fixed replicate budget")
    phases = ("pre_start", "post_start")
    groups = defaultdict(lambda: {phase: defaultdict(Counter) for phase in phases})
    for row in rows:
        number = int(row["round"])
        if 8 <= number <= 14:
            group = groups[int(row["seed"])]
            group["pre_start"][number][row["pre_start_stats"]] += 1
            if row["stats_phase"] == "after_start_effects":
                group["post_start"][number][row["stats"]] += 1

    def median(phase, number, weights):
        counts = Counter()
        for seed, weight in weights.items():
            for value, count in groups[seed][phase].get(number, {}).items():
                counts[value] += weight * count
        size = sum(counts.values())
        if not size:
            return None, 0
        lower, upper, seen = (size - 1) // 2, size // 2, 0
        middle = []
        for value, count in sorted(counts.items()):
            if seen <= lower < seen + count:
                middle.append(value)
            if seen <= upper < seen + count:
                middle.append(value)
                break
            seen += count
        return sum(middle) / 2, size

    def factor(start, end):
        for number, value in ((8, start), (14, end)):
            if value is None:
                return None, f"missing_round_{number}"
            if not math.isfinite(value) or value <= 0:
                return None, f"nonpositive_or_nonfinite_round_{number}_median"
        return (end / start) ** (1 / 6), None

    result = {
        "round_range": [8, 14],
        "formula": "(median_R14 / median_R8) ** (1 / 6)",
        "deciding_phase": "pre_start",
        "population": "pooled observed boards at each round; late rounds contain survivors only",
    }
    original = dict.fromkeys(groups, 1)
    for phase in phases:
        series = {str(number): median(phase, number, original) for number in range(8, 15)}
        estimate, reason = factor(series["8"][0], series["14"][0])
        result[phase] = {
            "median_by_round": {number: value[0] for number, value in series.items()},
            "boards_by_round": {number: value[1] for number, value in series.items()},
            "per_round_factor": estimate,
            "unsupported_reason": reason,
        }
    draws = {phase: [] for phase in phases}
    if len(groups) >= 2:
        rng = random.Random(bootstrap_seed)
        seeds = sorted(groups)
        for _ in range(replicates):
            weights = Counter(rng.choices(seeds, k=len(seeds)))
            for phase in phases:
                if result[phase]["per_round_factor"] is None:
                    continue
                estimate, _ = factor(median(phase, 8, weights)[0], median(phase, 14, weights)[0])
                if estimate is not None:
                    draws[phase].append(estimate)
    for phase in phases:
        values = draws[phase]
        result[phase]["ci95"] = [percentile(values, 0.025), percentile(values, 0.975)] if values else None
        result[phase]["interval_unsupported_reason"] = (
            result[phase]["unsupported_reason"]
            or ("fewer_than_two_independent_seeds" if len(groups) < 2 else None)
            or ("no_supported_bootstrap_draws" if not values else None)
        )
    result["uncertainty"] = {
        "method": "percentile bootstrap of whole independent seeds, all seats/legs/rounds together",
        "seed_clusters": len(groups),
        "replicates": replicates,
        "bootstrap_seed": bootstrap_seed,
        "valid_draws": {phase: len(values) for phase, values in draws.items()},
        "limitations": (
            "uncertainty in the survivor median, not within-player compounding; elimination selection remains"
        ),
    }
    return result


def placement_ranking(players):
    observations = defaultdict(list)
    for row in players:
        label = "hard" if str(row.get("bot", "")).startswith("hard_field") else row["strategy"]
        observations[label].append((int(row["seed"]), float(row["place"]), 1))
    result = []
    for line, values in observations.items():
        estimate = clustered_rate(values)
        result.append(
            {
                "line": line,
                "seats": estimate["n"],
                "seed_clusters": estimate["seed_clusters"],
                "mean_place": estimate["rate"],
                "ci95": estimate["ci95"],
            }
        )
    return sorted(result, key=lambda r: (r["mean_place"], r["line"]))


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
        "curvature_check": curvature_with_intervals(rows),
        "checkpoint_1_growth": checkpoint_growth(rows),
        "stats_phase_counts": dict(Counter(row["stats_phase"] for row in rows)),
        "line_placement_ranking": placement_ranking(players) if players and "strategy" in players[0] else [],
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

        def fmt(value):
            return f"{value:.3f}" if value is not None else "n/a"

        lines = [
            "# Harness measurements\n",
            "Stats describe feel; field win rates rank boards. Round summaries include survivors only.\n",
            "Checkpoint 1 growth is (R14 median / R8 median)^(1/6); the pre-start point estimate decides. "
            "Intervals resample whole independent seeds.\n",
            "| Growth phase | R8 median | R14 median | Per-round factor | Seed-bootstrap 95% interval |",
            "|---|---:|---:|---:|---|",
        ]
        for phase in ("pre_start", "post_start"):
            growth = result["checkpoint_1_growth"][phase]
            interval = growth["ci95"]
            interval_text = (
                f"[{fmt(interval[0])}, {fmt(interval[1])}]" if interval else growth["interval_unsupported_reason"]
            )
            lines.append(
                f"| {phase} | {fmt(growth['median_by_round']['8'])} | {fmt(growth['median_by_round']['14'])} "
                f"| {fmt(growth['per_round_factor'])} | {interval_text} |"
            )
        lines.extend(
            [
                "\n| Round | Pre-start median | Post-start median |",
                "|---|---:|---:|",
            ]
        )
        for number in map(str, range(8, 15)):
            pre = result["checkpoint_1_growth"]["pre_start"]["median_by_round"][number]
            post = result["checkpoint_1_growth"]["post_start"]["median_by_round"][number]
            lines.append(f"| {number} | {fmt(pre)} | {fmt(post)} |")
        lines.extend(
            [
                "\nPost-start board measurements:\n",
                "| Round | Boards | p50 | p90 | p99 | Share >=2x | Own growth | Growth ratio | Stats/gold "
                "| Largest share |",
                "|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|",
            ]
        )
        for r, value in result["rounds"].items():
            d = value["stats"]
            cells = [r, str(d["n"]), fmt(d["p50"]), fmt(d["p90"]), fmt(d["p99"]), fmt(value["share_2x_round_median"])]
            cells.extend(
                fmt(value[key]["p50"]) for key in ["growth_delta", "growth_ratio", "stats_per_gold", "largest_share"]
            )
            lines.append("| " + " | ".join(cells) + " |")
        lines.extend(
            [
                "\nTier arrivals relative to the owner's previous median unit:\n",
                "| Tier | Arrivals | Post-aura ratio p50 | Printed ratio p50 |",
                "|---|---:|---:|---:|",
            ]
        )
        for tier, values in result["tier_arrivals"].items():
            lines.append(
                f"| {tier} | {values['arrival_ratio']['n']} | {fmt(values['arrival_ratio']['p50'])} "
                f"| {fmt(values['printed_ratio']['p50'])} |"
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
