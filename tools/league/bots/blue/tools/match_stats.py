#!/usr/bin/env python3
"""Summarise placements, rounds, and purchases for one bot in a match."""

import argparse
import gzip
import json
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


@dataclass
class RoundStats:
    alive: int = 0
    tier: int = 0
    gold_start: int = 0
    gold_start_count: int = 0
    gold_left: int = 0
    board_units: int = 0
    triples: int = 0

    def add(self, turn):
        self.alive += 1
        self.tier += turn["tier"]
        if turn["gold_start"] is not None:
            self.gold_start += turn["gold_start"]
            self.gold_start_count += 1
        self.gold_left += turn["gold_left"]
        self.board_units += len(turn["board"])
        self.triples += turn["triple"]


@dataclass
class CardStats:
    offered: int = 0
    buyable: int = 0
    bought: int = 0
    bought_rounds: int = 0
    final_boards: int = 0
    placements: int = 0


def json_lines(path):
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8") as source:
        for line in source:
            yield json.loads(line)


def selected(record, args):
    return record["bot"] == args.bot and (
        args.colour is None or record["colour"] == args.colour
    )


def read_games(args, cards):
    placements = Counter()
    tribes = defaultdict(Counter)
    rounds = {number: RoundStats() for number in range(1, 19)}
    games = 0
    for game in json_lines(args.match_dir / "games.jsonl"):
        games += 1
        for seat in game["seats"]:
            if not selected(seat, args):
                continue
            place = seat["place"]
            placements[place] += 1
            tribes[seat["main_tribe"]][place] += 1
            for turn in seat["rounds"]:
                if turn["round"] in rounds:
                    rounds[turn["round"]].add(turn)
            for card in {unit["card"] for unit in seat["final_board"]}:
                cards[card].final_boards += 1
                cards[card].placements += place
    return games, placements, tribes, rounds


def read_shops(args, cards):
    spells = defaultdict(Counter)
    path = args.match_dir / "shops.jsonl.gz"
    if not path.exists():
        path = args.match_dir / "shops.jsonl"
    for shop in json_lines(path):
        if not selected(shop, args):
            continue
        for offer in shop["offers"]:
            stats = cards[offer["card"]]
            stats.offered += 1
            stats.buyable += offer["buyable"]
        for purchase in shop["bought"]:
            card = purchase["card"]
            if purchase["spell"]:
                spells[card][(shop["tier"] - 1) // 2] += 1
            else:
                cards[card].bought += 1
                cards[card].bought_rounds += shop["round"]
    return spells


def ratio(total, count):
    return total / count if count else None


def mean_place(placements):
    total = sum(place * count for place, count in placements.items())
    return ratio(total, sum(placements.values()))


def number(value):
    return "-" if value is None else f"{value:.2f}"


def percent(value):
    return "-" if value is None else f"{value:.2%}"


def table(headers, rows):
    lines = [headers, *(tuple(map(str, row)) for row in rows)]
    widths = [max(map(len, column)) for column in zip(*lines)]
    for first, *rest in lines:
        columns = [first.ljust(widths[0])]
        columns.extend(value.rjust(width) for value, width in zip(rest, widths[1:]))
        print("  ".join(columns))


def print_seats(games, placements, tribes, rounds):
    seats = sum(placements.values())
    print(f"Games: {games}\nSeats selected: {seats}")
    print(f"Average placement: {number(mean_place(placements))}")
    table(("Placement", *(str(place) for place in range(1, 9))), [
        ("Seats", *(placements[place] for place in range(1, 9))),
    ])

    print("\nPlacement by main tribe")
    tribe_rows = []
    for tribe, places in tribes.items():
        count = sum(places.values())
        tribe_rows.append((tribe or "(none)", count, percent(ratio(count, seats)),
                           number(mean_place(places))))
    tribe_rows.sort(key=lambda row: (-row[1], row[0]))
    table(("Tribe", "Seats", "Share", "Avg place"), tribe_rows)

    print("\nBy round (shares of all selected seats)")
    table(("Round", "Avg tier", "Avg gold start", "Avg gold left", "Avg board units",
           "Alive before fights", "Tripled"), (
        (turn, number(ratio(stats.tier, stats.alive)),
         number(ratio(stats.gold_start, stats.gold_start_count)),
         number(ratio(stats.gold_left, stats.alive)),
         number(ratio(stats.board_units, stats.alive)),
         percent(ratio(stats.alive, seats)), percent(ratio(stats.triples, seats)))
        for turn, stats in rounds.items()
    ))


def card_rows(library, cards, overall):
    rows = []
    for info in sorted(library, key=lambda card: (card["tier"], card["id"])):
        stats = cards[info["id"]]
        if info["spell"] or (info["token"] and not stats.bought):
            continue
        placement = ratio(stats.placements, stats.final_boards)
        rows.append({
            "id": info["id"],
            "name": info["name"],
            "tier": info["tier"],
            "offered": stats.offered,
            "offered_while_buyable": stats.buyable,
            "bought": stats.bought,
            "buy_rate": ratio(stats.bought, stats.buyable),
            "average_round_bought": ratio(stats.bought_rounds, stats.bought),
            "final_boards": stats.final_boards,
            "average_placement": placement,
            "lift": placement - overall if placement is not None else None,
        })
    return rows


def print_cards(rows, top):
    eligible = [row for row in rows if row["final_boards"] >= 20]
    print("\nCards by placement lift (at least 20 final boards)")
    for title, direction in (("Top", 1), ("Bottom", -1)):
        ranked = sorted(eligible, key=lambda row: direction * row["lift"])
        print(f"{title} {top} by lift")
        table(("Card id", "Tier", "Offered", "Buyable", "Bought", "Buy rate",
               "Avg buy round", "Final boards", "Avg place", "Lift"), (
            (row["id"], row["tier"], row["offered"], row["offered_while_buyable"],
             row["bought"], percent(row["buy_rate"]), number(row["average_round_bought"]),
             row["final_boards"], number(row["average_placement"]), number(row["lift"]))
            for row in ranked[:top]
        ))


def write_cards(path, rows):
    rounded_rows = [
        {key: round(value, 2) if isinstance(value, float) else value
         for key, value in row.items()}
        for row in rows
    ]
    with path.open("w", encoding="utf-8") as output:
        json.dump(rounded_rows, output, indent=2)
        output.write("\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("match_dir", type=Path)
    parser.add_argument("--bot", required=True)
    parser.add_argument("--colour", choices=("red", "blue"))
    parser.add_argument("--top", type=int, default=25)
    parser.add_argument("--json", type=Path, metavar="OUT")
    args = parser.parse_args()
    if args.top < 0:
        parser.error("--top must be non-negative")

    with (args.match_dir / "library.json").open(encoding="utf-8") as source:
        library = json.load(source)
    cards = defaultdict(CardStats)
    games, placements, tribes, rounds = read_games(args, cards)
    spells = read_shops(args, cards)

    print_seats(games, placements, tribes, rounds)
    rows = card_rows(library, cards, mean_place(placements))
    print_cards(rows, args.top)
    if args.json is not None:
        write_cards(args.json, rows)

    print("\nSpells bought by buyer tier")
    table(("Spell id", "Tier 1-2", "Tier 3-4", "Tier 5-6"), (
        (card, *(spells[card][band] for band in range(3))) for card in sorted(spells)
    ))


if __name__ == "__main__":
    main()
