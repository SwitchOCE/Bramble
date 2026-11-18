#!/usr/bin/env python3
"""Summarize replayed league events with seed-pair confidence intervals."""

import argparse
from collections import Counter, defaultdict
from itertools import groupby
import json
from operator import itemgetter
from pathlib import Path

from match_data import Match, Measures, SCOPES, atomic_file, nest, show

EATERS = ("gorger", "granary-glutton")
SERGEANTS = ("colour-sergeant", "regimental-sergeant-major")
STATS = ("attack", "health", "total")
CARD_NAMES = {
    "gorger": "Gorger",
    "granary-glutton": "Granary Glutton",
    "colour-sergeant": "Colour Sergeant",
    "regimental-sergeant-major": "Sergeant Major",
}


def stats(amount):
    return {**amount, "total": amount["attack"] + amount["health"]}


def eat_stats(measures, key, pair, eats):
    count = len(eats)
    for stat in STATS:
        measures.add((*key, "stats_per_eat", stat), pair, sum(g[stat] for g in eats), n=count)


def scope_measures(measures, pair, scope, rounds, events, seats):
    exposed = set()
    eats = defaultdict(list)
    growth = defaultdict(Counter)
    fed = sales = 0
    for event in events:
        seat = event["seat"]
        if event.get("ghost") or seat not in seats:
            continue
        round_no = event["round"]
        match event["type"]:
            case "unit_round":
                unit = event["unit"]
                key = (round_no, seat, unit["card"], unit["uid"])
                if key in exposed:
                    raise ValueError(f"duplicate unit-round observation {key}")
                exposed.add(key)
            case "eat":
                unit = event["eater"]
                eats[round_no, seat, unit["card"], unit["uid"]].append(stats(event["gain"]))
            case "sale":
                sales += 1
                fed += bool(event["fed"])
            case "slot_growth":
                unit = event["source"]
                amount = event["amount"]
                amplification = event.get("amplification")
                if amplification:
                    amount = {k: amount[k] - amplification["amount"][k] for k in ("attack", "health")}
                    sources = amplification["sources"]
                    for source in sources:
                        key = (round_no, seat, source["card"], source["uid"])
                        for stat, value in stats(amplification["amount"]).items():
                            growth[key]["amplified", stat] += value / len(sources)
                if unit["card"] in SERGEANTS:
                    key = (round_no, seat, unit["card"], unit["uid"])
                    for stat, value in stats(amount).items():
                        growth[key]["direct", stat] += value
            case _:
                raise ValueError(f"unknown replay event {event['type']!r}")

    if (eats.keys() | growth.keys()) - exposed:
        raise ValueError("eat or Sergeant growth is missing a unit-round observation")

    exposed = sorted(exposed)
    eat_totals = [gain for values in eats.values() for gain in values]
    measures.add((scope, "eats_per_game"), pair, len(eat_totals))
    measures.add((scope, "fed_sales"), pair, fed, n=sales, rate=True)
    eat_stats(measures, (scope,), pair, eat_totals)

    for card in EATERS:
        by_round = defaultdict(list)
        for key in exposed:
            if key[2] == card:
                by_round[key[0]].append(eats[key])
        count = sum(map(len, by_round.values()))
        card_eats = [gain for units in by_round.values() for gains in units for gain in gains]
        key = (scope, "eaters", card)
        measures.add((*key, "eats_per_game"), pair, len(card_eats))
        measures.add((*key, "eats_per_unit_round"), pair, len(card_eats), n=count)
        eat_stats(measures, key, pair, card_eats)
        for round_no in range(1, rounds + 1):
            units = by_round[round_no]
            gains = [gain for per_unit in units for gain in per_unit]
            at_round = (*key, "by_round", round_no)
            measures.add((*at_round, "eats_per_game"), pair, len(gains))
            measures.add((*at_round, "eats_per_unit_round"), pair, len(gains), n=len(units))
            eat_stats(measures, at_round, pair, gains)

    for card in SERGEANTS:
        by_round = defaultdict(list)
        for key in exposed:
            if key[2] == card:
                by_round[key[0]].append(growth[key])
        key = (scope, "sergeants", card)
        card_rounds = [row for units in by_round.values() for row in units]
        slot_stats(measures, (*key, "growth_per_fight_round"), pair, card_rounds)
        for round_no in range(1, rounds + 1):
            slot_stats(measures, (*key, "by_round", round_no), pair, by_round[round_no])


def slot_stats(measures, key, pair, rows):
    for stat in STATS:
        direct = sum(row["direct", stat] for row in rows)
        amplified = sum(row["amplified", stat] for row in rows)
        measures.add((*key, "direct", stat), pair, direct, n=len(rows))
        measures.add((*key, "amplified", stat), pair, amplified, n=len(rows))
        measures.add((*key, "combined", stat), pair, direct + amplified, n=len(rows))


def analyze(match):
    measures = Measures()
    grouped = iter(groupby(match.rows("events"), key=itemgetter("game")))
    current = next(grouped, None)
    for game in match.games():
        index = game["game"]
        events = []
        if current and current[0] < index:
            raise ValueError("events out of game order")
        if current and current[0] == index:
            events = list(current[1])
            current = next(grouped, None)
        rounds = game["rounds"]
        for row in events:
            if row["seat"] not in range(8) or row["round"] not in range(1, rounds + 1):
                raise ValueError(f"game {index}: invalid event round or seat")
        for scope in SCOPES:
            seats = {seat["seat"] for seat in game["seats"] if scope in ("both", seat["colour"])}
            scope_measures(measures, index // 2, scope, rounds, events, seats)
    if current:
        raise ValueError("events contain a game outside the match")

    out = {}
    for (key, rate), stat in measures.stats.items():
        result = stat.result(rate)
        if not rate:
            result["total"] = stat.sx + stat.x
        nest(out, key, result)
    return {
        "games": match.summary["games"],
        "seed_pairs": (match.summary["games"] + 1) // 2,
        "scopes": out,
    }


def markdown(data):
    lines = [
        "| Team | Eats per game | Eats per Gorger-round | Eats per Glutton-round | Attack per eat | Health per eat | Fed sales |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for scope in SCOPES:
        s = data["scopes"][scope]
        stats_to_show = [
            s["eats_per_game"],
            *(s["eaters"][card]["eats_per_unit_round"] for card in EATERS),
            s["stats_per_eat"]["attack"],
            s["stats_per_eat"]["health"],
            s["fed_sales"],
        ]
        lines.append("| " + " | ".join([scope, *map(show, stats_to_show)]) + " |")
    lines.extend([
        "",
        "| Team | Sergeant | Direct stats per fight-round | Extra stats from amplification |",
        "| --- | --- | ---: | ---: |",
    ])
    for scope in SCOPES:
        for card in SERGEANTS:
            growth = data["scopes"][scope]["sergeants"][card]["growth_per_fight_round"]
            lines.append(f"| {scope} | {CARD_NAMES[card]} | {show(growth['direct']['total'])} | "
                         f"{show(growth['amplified']['total'])} |")
    lines.extend(["", "Brackets show 95% intervals over seed pairs. Parentheses show counts."])
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("match", type=Path)
    args = parser.parse_args(argv)
    data = analyze(Match(args.match))
    with atomic_file(args.match / "events.json") as output:
        json.dump(data, output, allow_nan=False, indent=2)
        output.write("\n")
    print(markdown(data))


if __name__ == "__main__":
    main()
