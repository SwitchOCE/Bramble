#!/usr/bin/env python3
"""Summarize observer-only R1-R6 Soup exposure and exact realized-pool draw hazards."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import random
from collections import Counter
from math import prod
from pathlib import Path
from statistics import mean


def report(probe: dict, metrics: list[dict], rounds: list[dict] | None = None) -> dict:
    seeds = {int(row["seed"]) for row in metrics}
    if len(seeds) != 32 or len(metrics) != 32:
        raise ValueError("exactly 32 distinct source lobbies required")
    seats = {
        int(row["seed"]): next(s for s in row["shopping"] if s["assigned_line"] == "line_oozes_engine")
        for row in metrics
    }
    rows = []
    for seed in sorted(seeds):
        offers = [r for r in probe["offers"] if int(r["seed"]) == seed and r["engine"]]
        draws = [r for r in probe["draws"] if int(r["seed"]) == seed and r["engine"]]
        events = [r for r in probe["events"] if int(r["seed"]) == seed]
        if not draws:
            raise ValueError("missing engine draws")
        soup_offers = [r for r in offers if r["card"] == "stone_soup"]
        soup_buys = [r for r in events if r["type"] == "buy" and r["fields"].get("unit") == "stone_soup"]
        first = min((int(r["round"]) for r in soup_offers), default=None)
        missed = bool(soup_offers) and not soup_buys
        alternatives = [
            r
            for r in events
            if r["type"] in ("buy", "play", "sell", "swallow") and first is not None and int(r["round"]) >= first
        ]
        first_soup = seats[seed]["first_soup_fielded_round"]
        route = [
            r
            for r in (rounds or [])
            if int(r["seed"]) == seed and int(r["seat"]) == int(seats[seed]["seat"]) and int(r["round"]) <= 6
        ]
        first_arrival_hazard = 0.0
        for draw in draws:
            first_arrival_hazard += draw["hazard"]
            if draw.get("drawn") == "stone_soup":
                break
        rows.append(
            {
                "actual_round_route": [
                    {
                        "round": int(r["round"]),
                        "end_tier": int(r["tier"]),
                        "paid_refreshes": int(r["paid_refreshes"]),
                        "gold_left": int(r["gold_left"]),
                    }
                    for r in route
                ],
                "paid_refreshes_by_r6": sum(int(r["paid_refreshes"]) for r in route),
                "seed": seed,
                "seat": int(seats[seed]["seat"]),
                "soup_seen_by_r6": bool(soup_offers),
                "soup_bought_by_r6": bool(soup_buys),
                "soup_fielded_by_r6": first_soup is not None and int(first_soup) <= 6,
                "first_offer_round": first,
                "soup_offers": len(soup_offers),
                "soup_buys": len(soup_buys),
                "unique_offers": len(offers),
                "actual_draws_by_shop_tier": dict(sorted(Counter(str(r["shop_tier"]) for r in draws).items())),
                "actual_conditional_hazard_range": [min(r["hazard"] for r in draws), max(r["hazard"] for r in draws)],
                "soup_copies_left_range": [min(r["soup_left"] for r in draws), max(r["soup_left"] for r in draws)],
                "tier1_copies_left_range": [min(r["tier1_left"] for r in draws), max(r["tier1_left"] for r in draws)],
                "other_seat_owned_soup_max": max(r["other_seats_owned_soup_copies"] for r in draws),
                "first_arrival_hazard": first_arrival_hazard,
                "realized_pool_route_reference": 1 - prod(1 - r["hazard"] for r in draws),
                "undepleted_19_card_route_reference": 1 - prod(1 - r["tier1_weight"] / 19 for r in draws),
                "missed_offer_details": soup_offers if missed else [],
                "actions_after_missed_offer": alternatives if missed else [],
            }
        )
    first_arrival_values = [row["first_arrival_hazard"] for row in rows]
    rng = random.Random(51052)
    bootstrap = sorted(mean(rng.choices(first_arrival_values, k=32)) for _ in range(10000))
    seen = sum(r["soup_seen_by_r6"] for r in rows)
    bought = sum(r["soup_bought_by_r6"] for r in rows)
    fielded = sum(r["soup_fielded_by_r6"] for r in rows)
    return {
        "version": 1,
        "lobbies": 32,
        "engine_paid_refreshes_by_r6": sum(r["paid_refreshes_by_r6"] for r in rows),
        "parity_boards_checked": probe["parity_boards_checked"],
        "source_seed_list": sorted(seeds),
        "soup_seen_by_r6": seen,
        "soup_bought_by_r6": bought,
        "soup_fielded_by_r6": fielded,
        "seen_rate": seen / 32,
        "bought_rate": bought / 32,
        "fielded_rate": fielded / 32,
        "bar": {"minimum": 20, "denominator": 32, "fraction": 20 / 32},
        "availability_cap_on_this_logged_route": seen,
        "bar_attainable_by_buy_selection_only_on_this_route": seen >= 20,
        "opportunity_shortfall": max(0, 20 - seen),
        "observed_selection_gap": seen - bought,
        "first_arrival_probability_estimate": mean(first_arrival_values),
        "first_arrival_bootstrap_90": [bootstrap[500], bootstrap[9499]],
        "first_arrival_method": (
            "Average the sum of predictable native draw hazards while the seat has not yet seen Soup, "
            "including its first-hit draw. The stopped counting-process compensator estimates first-arrival "
            "probability under the actual policy. Bootstrap 10000 complete lobby routes, seed 51052; "
            "this is an estimate, not a universal cap or an exact ex-ante enumeration."
        ),
        "mean_realized_pool_route_reference": mean(r["realized_pool_route_reference"] for r in rows),
        "mean_undepleted_route_reference": mean(r["undepleted_19_card_route_reference"] for r in rows),
        "pool_rules": {
            "tier1_definitions_per_lobby": 19,
            "copies_per_definition": 15,
            "initial_tier1_copies": 285,
            "initial_soup_copies": 15,
            "base_shop_slots_t1_t3": 4,
        },
        "method": (
            "Each logged shop draw hazard is q(T1 among nonempty tier weights) * actual Soup copies left / "
            "actual T1 copies left, immediately before the unchanged native draw. Pool subclass delegates to "
            "the original draw and uses no extra random draws. Captured R1-R6 active stats and ordered card "
            "IDs must equal the original route for every seat."
        ),
        "qualification": (
            "Seen/bought/fielded are exact observations for these seeds. Products of realized-pool hazards "
            "along the observed route are descriptive path references, not ex-ante counterfactual policy "
            "probabilities: earlier hits change buys, freezes, climbs and the shared pool. Missing Soup "
            "opportunities cannot be repaired solely by choosing a different purchase on this fixed trace. "
            "This does not prove a universal mathematical impossibility or that another route cannot reach "
            "the bar."
        ),
        "seats": rows,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("probe", type=Path)
    parser.add_argument("--metrics", type=Path, default=Path("build/neutrals/soup-confirm.line-metrics.jsonl"))
    parser.add_argument("--rounds", type=Path, default=Path("build/neutrals/soup-confirm.rounds.csv"))
    parser.add_argument("--out", type=Path, default=Path("build/neutrals/soup-odds-report.json"))
    args = parser.parse_args()
    metrics = [json.loads(line) for line in args.metrics.read_text().splitlines() if line.strip()]
    with args.rounds.open(newline="") as stream:
        rounds = list(csv.DictReader(stream))
    result = report(json.loads(args.probe.read_text()), metrics, rounds)
    result["sources"] = {
        str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in (args.probe, args.metrics, args.rounds)
    }
    args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps({k: v for k, v in result.items() if k not in ("seats", "source_seed_list", "sources")}, indent=2))


if __name__ == "__main__":
    main()
