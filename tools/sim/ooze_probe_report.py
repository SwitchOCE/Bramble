#!/usr/bin/env python3
"""Describe the three frozen Ooze arms; reconcile every seat-round's eating ledger."""

from __future__ import annotations

import argparse
import csv
import gzip
import json
import statistics as stats
from collections import Counter, defaultdict
from pathlib import Path

LINES = ("line_oozes_engine", "line_oozes_tempo")


def median(values):
    return stats.median(values) if values else None


def load(path):
    with gzip.open(path, "rt") as stream:
        return json.load(stream)


def inspect_seat(rows):
    gross = recycled = sold = destroyed = 0
    out = []
    for row in sorted(rows, key=lambda row: row["round"]):
        probe = row["ooze_probe"]
        direct = shared = consumed = sales = attempted = 0
        buys, meals, swallows = Counter(), Counter(), Counter()
        offers = {}
        for event in probe["events"]:
            fields, kind = event["fields"], event["type"]
            if kind == "eat" and "recycled_credit" in fields:
                direct += fields.get("accepted", fields["attack"] + fields["health"])
                consumed += fields["recycled_credit"]
                meals[fields["target"]] += 1
            elif kind == "ooze_share":
                shared += fields["accepted"]
                attempted += fields["attack"] + fields["health"]
            elif kind == "sell":
                sales += fields.get("eat_credit", 0)
            elif kind == "buy":
                buys[fields["unit"]] += 1
            elif kind == "swallow":
                swallows[f"{fields['from']}:{fields['unit']}->{fields['by']}"] += 1
            elif kind == "shop":
                for unit in fields["offers"]:
                    offers[unit["iid"]] = unit["id"]
        gross += direct + shared
        recycled += consumed
        sold += sales
        stock, visible_stock = Counter(), Counter()
        cap_excess = 0
        for unit in probe["inventory"]:
            if unit["attack"] < 0 or unit["health"] <= 0 or unit["credit"] < 0:
                raise ValueError(f"invalid recruit body: {row['seed']}/{row['seat']}/{row['round']}: {unit}")
            stock[unit["location"]] += unit["credit"]
            visible = min(unit["credit"], max(0, unit["attack"]) + max(0, unit["health"]))
            visible_stock[unit["location"]] += visible
            cap_excess += unit["credit"] - visible
        # Destroy logs identify the operation and card, but omit the destroyed iid.
        # The stock ledger identifies its lost credit, including same-turn meals.
        destroyed_turn = gross - recycled - sold - destroyed - sum(stock.values())
        has_destroy = any(event["type"] == "destroyed" for event in probe["events"])
        if destroyed_turn > 0 and has_destroy:
            destroyed += destroyed_turn
        else:
            destroyed_turn = 0
        residual = gross - recycled - sold - destroyed - sum(stock.values())
        if residual:
            raise ValueError(f"unreconciled eating credit: {row['seed']}/{row['seat']}/{row['round']}: {residual}")
        out.append(
            {
                "seed": row["seed"],
                "seat": row["seat"],
                "round": row["round"],
                "line": row["line"],
                "active_stats": row["stats"],
                "belly_stats": row["belly_stats"],
                "health_after": row["health_after"],
                "eaten_gain": direct,
                "elder_gain": shared,
                "elder_refused": attempted - shared,
                "recycled_credit": consumed,
                "sold_credit_turn": sales,
                "net_generated_cumulative": gross - recycled,
                "sold_credit_cumulative": sold,
                "destroyed_credit_turn": destroyed_turn,
                "destroyed_credit_cumulative": destroyed,
                "active_credit": visible_stock["board"],
                "belly_credit": visible_stock["belly"],
                "reserve_credit": sum(v for k, v in visible_stock.items() if k not in ("board", "belly")),
                "cap_excess_credit": cap_excess,
                "ledger_residual": residual,
                "rolls": probe["rolls"],
                "buys": dict(buys),
                "eaten_bodies": dict(meals),
                "swallowed_bodies": dict(swallows),
                "offers": dict(Counter(offers.values())),
                "gold_left": probe["gold_left"],
                "spent": probe["spent"],
                "digest_room": probe["digest_room"],
                "cards": [u["id"] for u in probe["inventory"] if u["location"] == "board"],
                "belly_bodies": [u["id"] for u in probe["inventory"] if u["location"] == "belly"],
            }
        )
    return out


def matched_growth(rows, cohort=None):
    by_round = {r: {row["seed"]: row for row in rows if row["round"] == r} for r in (8, 14)}
    paired = set(by_round[8]) & set(by_round[14])
    if cohort is not None:
        paired &= cohort
    before = median([by_round[8][seed]["active_stats"] for seed in paired])
    after = median([by_round[14][seed]["active_stats"] for seed in paired])
    return {
        "n": len(paired),
        "seeds": sorted(paired),
        "r8": before,
        "r14": after,
        "factor": after / before if before else None,
        "per_round": (after / before) ** (1 / 6) if before else None,
        "median_individual_per_round": median(
            [(by_round[14][seed]["active_stats"] / by_round[8][seed]["active_stats"]) ** (1 / 6) for seed in paired]
        ),
    }


def summarize_line(rows, seeds, common):
    r12 = [row for row in rows if row["round"] == 12]
    upto12 = [row for row in rows if row["round"] <= 12]
    latest = {}
    for row in upto12:
        if row["seed"] not in latest or row["round"] > latest[row["seed"]]["round"]:
            latest[row["seed"]] = row
    ledger = Counter()
    for row in latest.values():
        ledger["generated"] += row["net_generated_cumulative"]
        ledger["sold"] += row["sold_credit_cumulative"]
        ledger["destroyed"] += row["destroyed_credit_cumulative"]
        if row["round"] == 12:
            for key in ("active", "belly", "reserve"):
                ledger[key] += row[f"{key}_credit"]
            ledger["cap_excess"] += row["cap_excess_credit"]
        else:
            ledger["eliminated"] += sum(row[f"{key}_credit"] for key in ("active", "belly", "reserve"))
            ledger["eliminated"] += row["cap_excess_credit"]
    assert ledger["generated"] == sum(
        ledger[k] for k in ("sold", "active", "belly", "reserve", "eliminated", "destroyed", "cap_excess")
    )
    totals = {key: sum(row[key] for row in upto12) for key in ("rolls", "eaten_gain", "elder_gain", "elder_refused")}
    bodies = {}
    for key in ("buys", "eaten_bodies", "swallowed_bodies"):
        counter = Counter()
        for row in upto12:
            counter.update(row[key])
        bodies[key] = dict(counter.most_common())
    presence = {}
    for card in ("stone_soup", "dishwater_nell", "aunt_aspic", "elder_ooze", "cut_and_come_again"):
        presence[card] = {
            "active_r12": sum(card in row["cards"] for row in r12),
            "seen_active_by_r12": len({row["seed"] for row in upto12 if card in row["cards"]}),
        }
    feeding = [row for row in upto12 if 8 <= row["round"] <= 12]
    return {
        "r12_active": median([row["active_stats"] for row in r12]),
        "r12_including_bellies": median([row["active_stats"] + row["belly_stats"] for row in r12]),
        "r12_alive": len(r12),
        "r12_alive_share": len(r12) / len(seeds),
        "growth_matched_within_arm": matched_growth(rows),
        "growth_common_across_arms": matched_growth(rows, common),
        "r12_credit_ledger_all_starting_seats": dict(ledger),
        "r12_survivor_credit_medians": {
            key: median([row[key] for row in r12])
            for key in (
                "active_credit",
                "belly_credit",
                "reserve_credit",
                "cap_excess_credit",
                "net_generated_cumulative",
                "sold_credit_cumulative",
                "destroyed_credit_cumulative",
            )
        },
        "r1_r12_telemetry": {
            "seat_rounds": len(upto12),
            **totals,
            "rolls_per_seat_round": totals["rolls"] / len(upto12),
            **bodies,
        },
        "presence": presence,
        "r8_r12": {
            "seat_rounds": len(feeding),
            "empty_digest_room_seat_rounds": sum(row["digest_room"] > 0 for row in feeding),
            "gold_left_median": median([row["gold_left"] for row in feeding]),
            "second_stomach_seat_rounds": sum(
                row["cards"].count("little_dollop") > 0
                and any(c in row["cards"] for c in ("bubble_and_squeak", "frumenty"))
                for row in feeding
            ),
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--arm", action="append", required=True, help="label=path/to/B.lobbies.json.gz")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    arms = {}
    for item in args.arm:
        arm, path = item.split("=", 1)
        games = load(path)
        seeds = sorted(game["seed"] for game in games)
        grouped = defaultdict(list)
        for game in games:
            for row in game["rounds"]:
                if row["line"] in LINES:
                    grouped[row["seed"], row["seat"]].append(row)
        rows = [row for group in grouped.values() for row in inspect_seat(group)]
        arms[arm] = {"source": path, "seeds": seeds, "rows": rows}
    assert len({tuple(arm["seeds"]) for arm in arms.values()}) == 1, "unmatched seeds"
    common = {
        line: set.intersection(
            *[
                {row["seed"] for row in arm["rows"] if row["line"] == line and row["round"] == 14}
                for arm in arms.values()
            ]
        )
        for line in LINES
    }
    output = {
        "counting": (
            "Pre-start Attack+Health; Belly sum is recursive and excludes hand. Alive means seated before R12 combat."
        ),
        "growth": (
            "R14 survivors matched to R8, also a common seed cohort surviving R14 in every arm; no zero imputation."
        ),
        "ledger": (
            "Direct eating plus accepted Elder shares, minus recycled already-attributed meals. "
            "Sales remove own credit only; contents release. Eliminated is permanent inventory loss "
            "before R12. Destroyed credit is inferred from the stock deficit only in turns with explicit "
            "recruit destroyed events. Combat deaths do not destroy recruit stats."
            " Visible credit is bounded by the body's displayed A+H (an upper bound, because other gains coexist); "
            "stored attributed credit beyond that is reported separately as cap_excess."
        ),
        "arms": {},
    }
    args.out.mkdir(parents=True, exist_ok=True)
    all_rows = []
    for name, arm in arms.items():
        output["arms"][name] = {
            "source": arm["source"],
            "seeds": arm["seeds"],
            "lines": {
                line: summarize_line([row for row in arm["rows"] if row["line"] == line], arm["seeds"], common[line])
                for line in LINES
            },
        }
        all_rows += [{"arm": name, **row} for row in arm["rows"]]
    (args.out / "analysis.json").write_text(json.dumps(output, indent=2) + "\n")
    (args.out / "seat-rounds.json").write_text(json.dumps(all_rows, indent=2) + "\n")
    with (args.out / "seat-rounds.csv").open("w") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(all_rows[0]))
        writer.writeheader()
        for row in all_rows:
            writer.writerow({k: json.dumps(v) if isinstance(v, (dict, list)) else v for k, v in row.items()})
    for arm, arm_result in output["arms"].items():
        for line, result in arm_result["lines"].items():
            print(
                arm,
                line,
                result["r12_active"],
                result["r12_including_bellies"],
                result["r12_alive"],
                result["growth_common_across_arms"],
            )


if __name__ == "__main__":
    main()
