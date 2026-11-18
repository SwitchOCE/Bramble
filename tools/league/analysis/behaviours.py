#!/usr/bin/env python3
"""Observed play relevant to the balance pass, grouped by seat colour."""
from collections import Counter, defaultdict
import json

from match_data import Match, Measures, SCOPES, parser, publish, show, sides

SERGEANTS = ("colour-sergeant", "regimental-sergeant-major")


def officers(cards):
    return "+".join(c for c in SERGEANTS if c in cards) or "neither"


def record_slots(match, game, m):
    path = match.path / "records" / f"game-{game['game']:05}.jsonl"
    seats = {s["seat"]: s for s in game["seats"]}
    alive = {seat: {r["round"] for r in s["rounds"]} for seat, s in seats.items()}
    previous = defaultdict(int)
    pair = game["game"]//2
    with path.open("rb") as f:
        for line in f:
            if b'"fight_boards"' not in line:
                continue
            row = json.loads(line)
            if row["op"] != "fight_boards":
                continue
            for p in row["players"]:
                seat = p["id"]
                if seat < 0 or row["turn"] not in alive[seat]:
                    continue
                total = sum(s["attack"] + s["health"] for s in p["slots"])
                board = [u for u in p["board"] if u]
                group = officers({u["def"] for u in board})
                for scope in (seats[seat]["colour"], "both"):
                    m.add((scope, "slot_stat_change_by_sergeants", group), pair, total-previous[seat])
                    for u in board:
                        if u["def"] == "gorger":
                            m.add((scope, "surviving_gorgers_marked_ate"), pair,
                                  u.get("turn_counters", {}).get("locust_ate", 0) > 0, rate=True)
                previous[seat] = total


def sale_counts(match):
    counts = defaultdict(Counter)
    for row in match.rows("decisions"):
        colour, _ = match.seat(row)
        action = row["legal"][row["chosen"]]
        if row["result"] or action["type"] != "sell":
            continue
        counter = counts[row["game"], colour]
        counter["sells"] += 1
        if row["board_n"] == 7:
            counter["full_board_sells"] += 1
        others = {a["card"] for a in row["legal"] if a["type"] == "sell" and a["slot"] != action["slot"]}
        tribes = match.library[action["card"]]["tribes"]
        if "gorger" in others:
            counter["sales_with_gorger"] += 1
        if "granary-glutton" in others and ("Locust" in tribes or "All" in tribes):
            counter["locust_sales_with_glutton"] += 1
    return counts


def behaviour_stats(match):
    m = Measures()
    decisions = any((match.path / n).exists() for n in ("decisions.jsonl.gz", "decisions.jsonl"))
    counts = sale_counts(match) if decisions else {}
    records = (match.path / "records").is_dir()
    for g in match.games():
        pair = g["game"]//2
        if records:
            record_slots(match, g, m)
        if decisions:
            for scope in SCOPES:
                colours = ("red", "blue") if scope == "both" else (scope,)
                seats = sum(s["colour"] in colours for s in g["seats"])
                for name in ("sells", "full_board_sells", "sales_with_gorger", "locust_sales_with_glutton"):
                    total = sum(counts.get((g["game"], c), {}).get(name, 0) for c in colours)
                    m.add((scope, "per_game", name), pair, total)
                    m.add((scope, "per_seat_game", name), pair, total, n=seats)
        for seat in g["seats"]:
            for r in seat["rounds"]:
                compost = r["heaps"].get("thorn_compost", 0)
                group = officers({u["card"] for u in r["board"]})
                for scope in (seat["colour"], "both"):
                    m.add((scope, "any_slot_change_by_sergeants", group), pair, r["slot_buff"], rate=True)
                    if match.main(r) == "Briar":
                        m.add((scope, "briar_compost_by_round", r["round"]), pair, compost)
        for seat, r, _, f, side in sides(g):
            cards = Counter(u["card"] for u in r["board"])
            won = f["winner"] == seat["seat"]
            t = match.main(r)
            for scope in (seat["colour"], "both"):
                if cards["the-colonel"]:
                    hand = r["hand"]
                    num = sum(not match.library[c]["spell"] for c in hand)
                    m.add((scope, "colonel_hand_cards"), pair, len(hand))
                    m.add((scope, "colonel_hand_units"), pair, num)
                    m.add((scope, "colonel_win_by_hand_cards", len(hand)), pair, won, rate=True)
                    m.add((scope, "colonel_win_by_hand_units", num), pair, won, rate=True)
                for group in (("gleaners", "locust_gleaners") if t == "Locust" else ("gleaners",)):
                    key = (scope, group, cards["gleaner"])
                    m.add(key + ("friendly_deaths",), pair, f["result"]["deaths"][side])
                    m.add(key + ("fight_win",), pair, won, rate=True)
                if t == "Briar":
                    compost = r["heaps"].get("thorn_compost", 0)
                    m.add((scope, "briar_win_by_compost", compost), pair, won, rate=True)
                if t == "Badger":
                    n = f["result"]["outnumbered_by"][side]
                    m.add((scope, "outnumbered_by"), pair, n)
                    m.add((scope, "badger_win_by_outnumbered", n), pair, won, rate=True)
    result = m.result()
    result["coverage"] = {"decisions": decisions, "replay_snapshots": records}
    return result


def main():
    args = parser(__doc__).parse_args()
    data = behaviour_stats(Match(args.match))
    lines = ["# Behaviour checks", "", "| Observation | Red | Blue | Pooled |", "|---|---|---|---|"]
    for label, path in (("Colonel reserve units at fights", ("colonel_hand_units",)),
                        ("Outnumbered at Badger fights", ("outnumbered_by",)),
                        ("Sells per seat-game", ("per_seat_game", "sells")),
                        ("Locust sales with Glutton per seat-game", ("per_seat_game", "locust_sales_with_glutton")),
                        ("Surviving Gorgers marked as having eaten", ("surviving_gorgers_marked_ate",))):
        row = [label]
        for scope in SCOPES:
            value = data.get(scope, {})
            for k in path:
                value = value.get(k, {})
            row.append(show(value))
        lines.append("| " + " | ".join(row) + " |")
    publish(args.out_dir or args.match, "behaviours", data, "\n".join(lines))


if __name__ == "__main__":
    main()

