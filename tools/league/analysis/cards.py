#!/usr/bin/env python3
"""Shop and Discover choices, within-shop ranks and final boards for every unit."""
import math
from collections import defaultdict

from match_data import BANDS, NONE, SCOPES, Match, Measures, Stat, band, parser, publish


def values(report):
    """One reported score per distinct offered identity. Conflicting copies have no rank."""
    offered = set(report["offered"])
    result = {}
    for card, value in report["values"]:
        if card in offered and isinstance(value, (int, float)) and math.isfinite(value):
            if card in result and result[card] != value:
                return {}
            result[card] = value
    return result


def cell_add(table, key, pair, place):
    cell = table[key].setdefault(pair, [0, 0])
    cell[0] += place
    cell[1] += 1


def adjusted_lift(strata, reference):
    """Difference from same final tribe/round baseline; positive is better placement."""
    count = total = 0
    influence = defaultdict(float)
    weights = defaultdict(int)
    for key, cells in strata.items():
        baseline = reference[key]
        n = sum(x[1] for x in cells.values())
        base_n = sum(x[1] for x in baseline.values())
        mean = sum(x[0] for x in baseline.values()) / base_n
        count += n
        for pair, (places, num) in cells.items():
            delta = mean * num - places
            total += delta
            influence[pair] += delta
            weights[pair] += num
        for pair, (places, num) in baseline.items():
            influence[pair] += n/base_n * (places - mean*num)
    mean = total / count if count else None
    k = len(influence)
    ci = None
    if len(weights) > 1:
        residual = sum((x - mean*weights.get(p, 0))**2 for p, x in influence.items())
        half = 1.96 * math.sqrt(k/(k-1)*residual) / count
        ci = [mean-half, mean+half]
    return {"mean": mean, "count": count, "pairs": len(weights), "ci95": ci}


def card_stats(match, scopes=SCOPES):
    measures = Measures()
    selected = {t: tuple(s for s in (t, "both") if s in scopes) for t in ("red", "blue")}
    for shop in match.rows("shops"):
        colour, tribe = match.seat(shop)
        eligible = {o["card"] for o in shop["offers"] if o["buyable"] and not o["spell"]}
        bought = {b["card"] for b in shop["bought"]}
        pair, stage = shop["game"] // 2, band(shop["round"])
        for scope in selected[colour]:
            for card in eligible:
                hit = card in bought
                prefix = (scope, card)
                for suffix in (("buy",), ("by_band", stage), ("by_final_tribe", tribe),
                               ("band_and_final_tribe", stage, tribe)):
                    measures.add(prefix + suffix, pair, hit, rate=True)
                if bought:
                    measures.add(prefix + ("among_buying_shops", tribe), pair, hit, rate=True)

    for row in match.rows("discovers"):
        colour, _ = match.seat(row)
        for card in set(row["options"]):
            if not match.library[card]["spell"]:
                for scope in selected[colour]:
                    measures.add((scope, card, "discover"), row["game"]//2, card == row["card"], rate=True)

    for row, shop in match.report_shops():
        colour, _ = match.seat(row)
        if row["kind"] != "shop":
            continue
        buyable = {o["card"] for o in shop["offers"] if o["buyable"]} if shop else set()
        scores = values(row)
        for card, score in scores.items():
            if not match.library[card]["spell"]:
                rank = 1 + sum(other > score for other in scores.values())
                for scope in selected[colour]:
                    measures.add((scope, card, "value_rank"), row["game"]//2, rank)
                    if card in buyable:
                        measures.add((scope, card, "value_rank_when_buyable"), row["game"]//2, rank)

    base = defaultdict(lambda: defaultdict(dict))
    present = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    for game in match.games():
        pair = game["game"]//2
        for seat in game["seats"]:
            key = (seat["main_tribe"] or NONE, seat["rounds"][-1]["round"])
            for scope in selected[seat["colour"]]:
                cell_add(base[scope], key, pair, seat["place"])
                seen = set()
                for unit in seat["final_board"]:
                    card = unit["card"]
                    measures.add((scope, card, "golden"), pair, unit["golden"], rate=True)
                    if card not in seen:
                        cell_add(present[scope][card], key, pair, seat["place"])
                        seen.add(card)

    result = measures.result()
    for scope in scopes:
        cards = result.setdefault(scope, {})
        for card in match.units:
            data = cards.setdefault(card, {})
            for metric in ("buy", "discover", "golden", "value_rank", "value_rank_when_buyable"):
                data.setdefault(metric, Stat().result(metric in ("buy", "discover", "golden")))
            for metric, keys in (("by_band", BANDS), ("by_final_tribe", match.tribes),
                                 ("among_buying_shops", match.tribes)):
                lookup = data.setdefault(metric, {})
                for key in keys:
                    lookup.setdefault(key, Stat().result(True))
            data.setdefault("band_and_final_tribe", {})
            data["lift_places"] = adjusted_lift(present[scope][card], base[scope])
            buy = data["buy"]["rate"]
            data["never_bought"] = buy < .02 if buy is not None else None
            for flag, source in (("always_bought", "by_final_tribe"),
                                 ("always_among_buying_shops", "among_buying_shops")):
                rates = [data[source][t]["rate"] for t in match.tribes]
                if any(r is not None and r <= .8 for r in rates):
                    data[flag] = False
                else:
                    data[flag] = True if rates and None not in rates else None
    return result


def main():
    args = parser(__doc__).parse_args()
    match = Match(args.match)
    data = card_stats(match)
    lines = ["# Card verdicts", "", "| Seats | Never bought | Always bought | Always among buying shops |",
             "|---|---|---|---|"]
    for scope, cards in data.items():
        cells = [", ".join(c for c in sorted(cards) if cards[c][flag]) or "—"
                 for flag in ("never_bought", "always_bought", "always_among_buying_shops")]
        lines.append("| " + " | ".join([scope, *cells]) + " |")
    lines += ["", "Counts, intervals and band-by-final-tribe choices for every unit are in `cards.json`."]
    publish(args.out_dir or args.match, "cards", data, "\n".join(lines))


if __name__ == "__main__":
    main()

