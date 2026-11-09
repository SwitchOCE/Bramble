#!/usr/bin/env python3
"""Re-score recorded fights without Godot; alternate results use a fixed historical schedule."""

from __future__ import annotations

import argparse
import json
import math
from itertools import groupby
from pathlib import Path


def at(values, number):
    return values[min(max(0, number - 1), len(values) - 1)] if values else 0


def damage(record, variant, alive):
    config = {**record["input"]["config"], **variant}
    number, winner = int(record["round"]), int(record["outcome"]["winner"])
    if config["damage_mode"] == "v05":
        if winner < 0:
            return 0
        survivors = record["survivor_units"][winner]
        count = sum(u["own_starting_body"] and u["health"] > 0 for u in survivors)
        return int(at(config["base_damage_by_turn"], number)) + math.ceil(count * config.get("survivor_scale", 1))
    amount = 0
    if winner >= 0:
        tier = int(record["input"]["tiers"][winner])
        if record["outcome"]["last_blow"]:
            amount = max(4, tier)
        else:
            weights = config.get("tier_damage_by_tier", {})
            tiers = sum(
                weights.get(str(int(u["tier"])), u["tier"])
                for u in record["survivor_units"][winner]
                if u["def_id"] != "nest_egg"
            )
            amount = max(
                config["hero_damage_floor"], tier + math.ceil(tiers / max(1, config["survivor_damage_divisor"]))
            )
    if config.get("round_toll"):
        amount += max(1, number - 7)
    cap = at(config["damage_cap_by_turn"], number) if alive > config["damage_cap_off_at_alive"] else 0
    return min(amount, cap) if cap > 0 else amount


def take_loss(state, amount, against_hero, last_stand):
    saved = (
        against_hero
        and last_stand
        and not state["used"]
        and state["health"] >= 2
        and amount >= state["health"] + state["armor"]
    )
    absorbed = min(state["armor"], amount)
    state["armor"] -= absorbed
    state["health"] -= amount - absorbed
    if saved:
        state.update(health=1, used=True)
    return bool(saved)


def replay_game(records, variant):
    records = sorted(records, key=lambda r: int(r["round"]))
    state, logged_after = {}, {}
    eliminations, health_rounds = [], []
    divergence = coverage_lost = None
    checks = 0
    end_round = winner_seat = None
    for number, values in groupby(records, key=lambda r: int(r["round"])):
        fights = list(values)
        source_ids = {int(seat) for row in fights for seat in row["players"] if int(seat) >= 0}
        source_seats = [int(seat) for row in fights for seat in row["players"] if int(seat) >= 0]
        if len(source_seats) != len(source_ids) or any(
            row.get("alive_before", len(source_ids)) != len(source_ids) for row in fights
        ):
            raise ValueError("duplicate or incomplete round of fight results")
        for row in fights:
            for side, value in enumerate(row["players"]):
                seat = int(value)
                if seat < 0:
                    continue
                pre = row["combat_start"][side]
                if seat not in state:
                    delta = (
                        variant.get("starting_health", row["input"]["config"]["starting_health"])
                        - row["input"]["config"]["starting_health"]
                    )
                    state[seat] = {
                        "health": pre["health"] + delta,
                        "armor": pre["armor"],
                        "used": pre["last_stand_used"],
                        "alive": True,
                    }
                elif state[seat]["alive"]:
                    previous_health, previous_armor = logged_after[seat]
                    state[seat]["health"] += pre["health"] - previous_health
                    state[seat]["armor"] = max(0, state[seat]["armor"] + pre["armor"] - previous_armor)
        alive = {seat for seat, value in state.items() if value["alive"]}
        if alive - source_ids and coverage_lost is None:
            coverage_lost = number
        for row in fights:
            config = {**row["input"]["config"], **variant}
            amount = damage(row, variant, len(alive))
            original_damage = damage(row, {}, len(source_ids))
            if original_damage != row["outcome"]["damage"]:
                raise ValueError(f"logged damage cannot be reproduced at seed {row['seed']} round {number}")
            winner = int(row["outcome"]["winner"])
            for side, value in enumerate(row["players"]):
                seat = int(value)
                if seat < 0:
                    continue
                pre = row["combat_start"][side]
                # Preserve the recruit-phase deltas from the observed trajectory, including healing.
                logged = {"health": pre["health"], "armor": pre["armor"], "used": pre["last_stand_used"]}
                if winner != side:
                    take_loss(
                        logged,
                        original_damage,
                        int(row["players"][1 - side]) >= 0 and winner == 1 - side,
                        row["input"]["config"].get("last_stand", False) and len(source_ids) <= 4,
                    )
                if "health_after" in row:
                    if [logged["health"], logged["armor"]] != [row["health_after"][side], row["armor_after"][side]]:
                        raise ValueError("baseline Health/Armor replay differs from the live log")
                    checks += 1
                logged_after[seat] = (logged["health"], logged["armor"])
                if state[seat]["alive"] and winner != side:
                    opponent = int(row["players"][1 - side])
                    take_loss(
                        state[seat],
                        amount,
                        opponent in alive and winner == 1 - side,
                        config.get("last_stand", False) and len(alive) <= 4,
                    )
                if not variant and (state[seat]["health"], state[seat]["armor"]) != logged_after[seat]:
                    raise ValueError("baseline trajectory differs from logged Health/Armor")
        for seat in sorted(alive):
            if state[seat]["health"] <= 0:
                state[seat]["alive"] = False
                eliminations.append({"seat": seat, "round": number, "health": state[seat]["health"]})
        remaining = {seat for seat, value in state.items() if value["alive"]}
        original_remaining = {seat for seat in source_ids if logged_after[seat][0] > 0}
        if remaining != original_remaining and divergence is None:
            divergence = number
        health_rounds.append({"round": number, "players": {str(seat): dict(value) for seat, value in state.items()}})
        if len(remaining) <= 1:
            winner_seat = next(iter(remaining), None)
            end_round = number
            break
    return {
        "eliminations": eliminations,
        "rounds": health_rounds,
        "winner": winner_seat,
        "end_round": end_round,
        "first_elimination_divergence": divergence,
        "coverage_lost_round": coverage_lost,
        "unresolved_survivors": [seat for seat, value in state.items() if value["alive"]] if end_round is None else [],
        "live_post_state_checks": checks,
        "conditional_after_divergence": divergence is not None,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", type=Path, nargs="+")
    parser.add_argument("--variants", type=Path, help="JSON mapping names to config/damage/starting_health overrides")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    variants = {"original": {}, **(json.loads(args.variants.read_text()) if args.variants else {})}
    result = {
        "method": (
            "Fixed historical fight inputs/results and recruit deltas. After elimination divergence, "
            "matchups, buys and pool evolution are conditional, not a new simulated game."
        ),
        "variants": {},
    }
    for name, variant in variants.items():
        if variant.get("starting_health", 1) <= 0:
            raise ValueError("starting_health must be positive")
        result["variants"][name] = {}
    seen = set()
    for path in sorted(args.captures):
        with path.open() as stream:
            for (seed, leg), values in groupby(
                (json.loads(line) for line in stream), key=lambda row: (int(row["seed"]), int(row["leg"]))
            ):
                if (seed, leg) in seen:
                    raise ValueError("duplicate or split lobby capture")
                seen.add((seed, leg))
                records = list(values)
                for name, variant in variants.items():
                    result["variants"][name][f"{seed}:{leg}"] = replay_game(records, variant)
    args.out.write_text(json.dumps(result, indent=2) + "\n")


if __name__ == "__main__":
    main()
