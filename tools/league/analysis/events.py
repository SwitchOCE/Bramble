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
SALE_GROUPS = ("fed", "unfed")
GROWTH_SIDES = ("live", "ghost")
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
    food = Counter()
    gains_by_round = defaultdict(list)
    growth = defaultdict(Counter)
    slot_totals = defaultdict(Counter)
    sale_ages = defaultdict(Counter)
    for event in events:
        seat = event["seat"]
        if seat not in seats:
            continue
        ghost = event.get("ghost", False)
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
                gain = stats(event["gain"])
                eats[round_no, seat, unit["card"], unit["uid"]].append(gain)
                gains_by_round[round_no].append(gain)
                eaten = event["eaten"]
                food[eaten["tier"], eaten["card"]] += 1
            case "sale":
                group = "fed" if event["fed"] else "unfed"
                sale_ages[group]["rounds"] += event["rounds_on_board"]
                sale_ages[group]["sales"] += 1
            case "slot_growth":
                unit = event["source"]
                amount = event["amount"]
                totals = slot_totals[unit["card"], "ghost" if ghost else "live"]
                totals.update(stats(amount))
                totals["events"] += 1
                if ghost:
                    continue
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
    sales = sum(group["sales"] for group in sale_ages.values())
    measures.add((scope, "fed_sales"), pair, sale_ages["fed"]["sales"], n=sales, rate=True)
    eat_stats(measures, (scope,), pair, eat_totals)
    for round_no in range(1, rounds + 1):
        eat_stats(measures, (scope, "by_round", round_no), pair, gains_by_round[round_no])
    for group in SALE_GROUPS:
        age = sale_ages[group]
        measures.add((scope, "rounds_on_board_before_sale", group), pair, age["rounds"], n=age["sales"])
    for (card, side), totals in slot_totals.items():
        for stat in STATS:
            measures.add((scope, "slot_growth_by_source", card, side, stat),
                         pair, totals[stat], n=totals["events"])

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
    return food


def slot_stats(measures, key, pair, rows):
    for stat in STATS:
        direct = sum(row["direct", stat] for row in rows)
        amplified = sum(row["amplified", stat] for row in rows)
        measures.add((*key, "direct", stat), pair, direct, n=len(rows))
        measures.add((*key, "amplified", stat), pair, amplified, n=len(rows))
        measures.add((*key, "combined", stat), pair, direct + amplified, n=len(rows))


def diet_stats(measures, diets):
    card_tiers = {}
    for counts in diets.values():
        for tier, card in counts:
            if card_tiers.setdefault(card, tier) != tier:
                raise ValueError(f"inconsistent eaten tier for {card}")
    tiers = sorted(set(card_tiers.values()))
    cards = sorted(card_tiers.items())
    for (scope, pair), counts in sorted(diets.items()):
        total = counts.total()
        by_tier = Counter()
        for (tier, _), count in counts.items():
            by_tier[tier] += count
        key = (scope, "eaten")
        for tier in tiers:
            measures.add((*key, "by_tier", tier), pair, by_tier[tier], n=total, rate=True)
        for card, tier in cards:
            measures.add((*key, "by_card", card), pair, counts[tier, card], n=total, rate=True)
    return card_tiers


def analyze(match):
    measures = Measures()
    diets = defaultdict(Counter)
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
            pair = index // 2
            diets[scope, pair].update(scope_measures(measures, pair, scope, rounds, events, seats))
    if current:
        raise ValueError("events contain a game outside the match")

    card_tiers = diet_stats(measures, diets)
    out = {}
    for (key, rate), stat in measures.stats.items():
        result = stat.result(rate)
        if not rate:
            result["total"] = stat.sx + stat.x
        nest(out, key, result)
    for scope in SCOPES:
        diet = out[scope].setdefault("eaten", {"by_tier": {}, "by_card": {}})
        for card, share in diet["by_card"].items():
            share["tier"] = card_tiers[card]
            share["name"] = match.library.get(card, {}).get("name", card)
        ranked = sorted(diet["by_card"].items(), key=lambda item: (-item[1]["hits"], item[0]))
        diet["top_15_cards"] = [card for card, share in ranked[:15] if share["hits"]]
        out[scope].setdefault("slot_growth_by_source", {})
    return {
        "games": match.summary["games"],
        "seed_pairs": (match.summary["games"] + 1) // 2,
        "scopes": out,
    }


def markdown(data, library):
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
    scopes = data["scopes"]
    pooled = scopes["both"]
    lines.extend(["", "### What gets eaten by tier", "",
                  "| Tier | Red | Blue | Pooled |", "| --- | ---: | ---: | ---: |"])
    for tier in sorted(pooled["eaten"]["by_tier"], key=int):
        values = [show(scopes[scope]["eaten"]["by_tier"][tier]) for scope in SCOPES]
        lines.append("| " + " | ".join([tier, *values]) + " |")

    lines.extend(["", "### Most eaten cards", "",
                  "| Card | Tier | Red | Blue | Pooled |", "| --- | ---: | ---: | ---: | ---: |"])
    for card in pooled["eaten"]["top_15_cards"]:
        food = pooled["eaten"]["by_card"][card]
        values = [show(scopes[scope]["eaten"]["by_card"][card]) for scope in SCOPES]
        lines.append("| " + " | ".join([food["name"], str(food["tier"]), *values]) + " |")

    lines.extend(["", "### Mean stats gained per eat by round", "",
                  "| Round | Stat | Red | Blue | Pooled |", "| ---: | --- | ---: | ---: | ---: |"])
    for round_no, row in sorted(pooled["by_round"].items(), key=lambda item: int(item[0])):
        if not row["stats_per_eat"]["attack"]["count"]:
            continue
        for stat in ("attack", "health"):
            values = [show(scopes[scope]["by_round"][round_no]["stats_per_eat"][stat])
                      for scope in SCOPES]
            lines.append("| " + " | ".join([round_no, stat.title(), *values]) + " |")

    lines.extend(["", "### Rounds on board before sale", "",
                  "| Sale | Red | Blue | Pooled |", "| --- | ---: | ---: | ---: |"])
    for group, label in (("fed", "Fed"), ("unfed", "Did not feed")):
        values = [show(scopes[scope]["rounds_on_board_before_sale"][group]) for scope in SCOPES]
        lines.append("| " + " | ".join([label, *values]) + " |")

    lines.extend(["", "### Slot growth by source card", "",
                  "Cells show total Attack / Health and the number of changes. Ghosts are grouped by their owner's team.",
                  "", "| Source | Board | Red | Blue | Pooled |", "| --- | --- | ---: | ---: | ---: |"])
    for card, groups in sorted(pooled["slot_growth_by_source"].items()):
        name = library.get(card, {}).get("name", card)
        for side in GROWTH_SIDES:
            if side in groups:
                values = [show_slot_totals(scopes[scope]["slot_growth_by_source"].get(card, {}).get(side))
                          for scope in SCOPES]
                lines.append("| " + " | ".join([name, side.title(), *values]) + " |")
    lines.extend(["", "Brackets show 95% intervals over seed pairs. Parentheses show counts."])
    return "\n".join(lines)


def show_slot_totals(totals):
    if not totals:
        return "— (0)"
    attack = totals["attack"]["total"]
    health = totals["health"]["total"]
    return f"{attack} / {health} ({totals['attack']['count']})"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("match", type=Path)
    args = parser.parse_args(argv)
    match = Match(args.match)
    data = analyze(match)
    with atomic_file(args.match / "events.json") as output:
        json.dump(data, output, allow_nan=False, indent=2)
        output.write("\n")
    print(markdown(data, match.library))


if __name__ == "__main__":
    main()
