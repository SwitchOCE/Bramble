#!/usr/bin/env python3
"""Analyze seat, shop, and board statistics from a Bramble match directory."""

import argparse
import gzip
import json
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path


BOARD_ROUNDS = (4, 8, 12)
PLACEMENT_BUCKETS = ("1-2", "3-4", "5-6", "7-8")
TRIBE_BUCKETS = ("0-1", "2-3", "4+")


def ratio(total, count):
    return total / count if count else None


@dataclass
class Mean:
    count: int = 0
    total: int = 0

    def add(self, value):
        if value is not None:
            self.count += 1
            self.total += value

    @property
    def value(self):
        return ratio(self.total, self.count)


@dataclass
class RoundStats:
    seats: int = 0
    tier_total: int = 0
    board_stats_total: int = 0
    gold_start: Mean = field(default_factory=Mean)
    gold_left_total: int = 0

    def add(self, entry):
        self.seats += 1
        self.tier_total += entry["tier"]
        self.board_stats_total += entry["board_attack"] + entry["board_health"]
        self.gold_start.add(entry["gold_start"])
        self.gold_left_total += entry["gold_left"]

    def as_dict(self):
        return {
            "seats": self.seats,
            "mean_tier": ratio(self.tier_total, self.seats),
            "mean_board_stats": ratio(self.board_stats_total, self.seats),
            "mean_gold_start": self.gold_start.value,
            "mean_gold_left": ratio(self.gold_left_total, self.seats),
        }


def read_jsonl(path):
    opener = gzip.open if path.suffix == ".gz" else open
    with opener(path, "rt", encoding="utf-8") as source:
        for line in source:
            yield json.loads(line)


def matches_filters(row, bot, colour):
    return (bot is None or row["bot"] == bot) and (
        colour is None or row["colour"] == colour
    )


def board_placement(places, overall_mean):
    mean_place = places.value
    return {
        "seats": places.count,
        "mean_place": mean_place,
        "placement_delta": None if mean_place is None else mean_place - overall_mean,
    }


def analyze(match_dir, bot, colour):
    with (match_dir / "library.json").open(encoding="utf-8") as source:
        library = json.load(source)
    if isinstance(library, dict):
        library = [dict(card, id=card_id) for card_id, card in library.items()]
    units = sorted(
        (card for card in library if not card["token"] and not card["spell"]),
        key=lambda card: (card["tier"], card["id"]),
    )
    tribes = {tribe for card in library for tribe in card["tribes"] if tribe != "All"}
    placement = Mean()
    deaths = Mean()
    histogram = dict.fromkeys(range(1, 9), 0)
    tribe_places = defaultdict(Mean)
    tribe_commits = defaultdict(Mean)
    board_places = defaultdict(Mean)
    round_stats = defaultdict(RoundStats)
    round_eight_places = Mean()
    tribe_buckets = defaultdict(Mean)

    for game in read_jsonl(match_dir / "games.jsonl"):
        for seat in game["seats"]:
            if not matches_filters(seat, bot, colour):
                continue
            place = seat["place"]
            placement.add(place)
            deaths.add(seat["died_round"])
            histogram[place] += 1
            main_tribe = seat["main_tribe"]
            tribe_places[main_tribe].add(place)
            tribe_commits[main_tribe].add(seat["commit_round"])

            for card_id in {unit["card"] for unit in seat["final_board"]}:
                board_places[card_id, "final"].add(place)
            placement_bucket = PLACEMENT_BUCKETS[(place - 1) // 2]
            for entry in seat["rounds"]:
                round_number = entry["round"]
                if 1 <= round_number <= 20:
                    round_stats[round_number, placement_bucket].add(entry)
                if round_number in BOARD_ROUNDS:
                    for card_id in {unit["card"] for unit in entry["board"]}:
                        board_places[card_id, round_number].add(place)
                if round_number == 8:
                    round_eight_places.add(place)
                    # The log already expands All units into each tribe's count.
                    for tribe, count in entry["tribes"].items():
                        if count >= 2:
                            bucket = "4+" if count >= 4 else "2-3"
                            tribe_buckets[tribe, bucket].add(place)

    shop_path = match_dir / "shops.jsonl.gz"
    if not shop_path.exists():
        shop_path = match_dir / "shops.jsonl"
    offered = Counter()
    buyable = Counter()
    bought = Counter()
    for shop in read_jsonl(shop_path):
        if not matches_filters(shop, bot, colour):
            continue
        for offer in shop["offers"]:
            card_id = offer["card"]
            offered[card_id] += 1
            if offer["buyable"]:
                buyable[card_id] += 1
        bought.update(purchase["card"] for purchase in shop["bought"])

    overall_mean = placement.value
    cards = []
    for card in units:
        card_id = card["id"]
        cards.append({
            "id": card_id,
            "name": card["name"],
            "tier": card["tier"],
            "offered": offered[card_id],
            "offered_while_buyable": buyable[card_id],
            "bought": bought[card_id],
            "buy_rate": ratio(bought[card_id], buyable[card_id]),
            "final_board": board_placement(board_places[card_id, "final"], overall_mean),
            "rounds": {
                number: board_placement(board_places[card_id, number], overall_mean)
                for number in BOARD_ROUNDS
            },
        })

    tribe_counts = {}
    for tribe in sorted(tribes):
        two_or_three = tribe_buckets[tribe, "2-3"]
        four_or_more = tribe_buckets[tribe, "4+"]
        # Every other seat with a round 8 snapshot had zero or one of this tribe.
        zero_or_one = Mean(
            count=round_eight_places.count - two_or_three.count - four_or_more.count,
            total=round_eight_places.total - two_or_three.total - four_or_more.total,
        )
        tribe_counts[tribe] = {
            bucket: {"seats": places.count, "mean_place": places.value}
            for bucket, places in zip(TRIBE_BUCKETS, (zero_or_one, two_or_three, four_or_more))
        }

    main_tribes = sorted(tribes | tribe_places.keys(), key=lambda t: (t is None, t or ""))
    return {
        "summary": {
            "seats": placement.count,
            "mean_place": overall_mean,
            "placement_histogram": histogram,
            "deaths": deaths.count,
            "mean_death_round": deaths.value,
            "main_tribes": [
                {
                    "tribe": tribe,
                    "seats": tribe_places[tribe].count,
                    "share": ratio(tribe_places[tribe].count, placement.count),
                    "mean_place": tribe_places[tribe].value,
                    "mean_commit_round": tribe_commits[tribe].value,
                }
                for tribe in main_tribes
            ],
        },
        "cards": cards,
        "rounds": {
            number: {
                bucket: round_stats[number, bucket].as_dict()
                for bucket in PLACEMENT_BUCKETS
            }
            for number in range(1, 21)
        },
        "tribe_counts_at_round_8": tribe_counts,
    }


def percent(value):
    return "-" if value is None else f"{value:.2%}"


def print_table(headers, rows):
    def format_cell(value):
        if value is None:
            return "-"
        return f"{value:.2f}" if isinstance(value, float) else str(value)

    lines = [headers] + [tuple(map(format_cell, row)) for row in rows]
    widths = [max(map(len, column)) for column in zip(*lines)]
    for line in lines:
        print("  ".join(cell.ljust(width) for cell, width in zip(line, widths)).rstrip())


def print_report(report):
    summary = report["summary"]
    print("Summary")
    print_table(
        ("Seats", "Mean place", "Deaths", "Mean death round"),
        [tuple(summary[key] for key in ("seats", "mean_place", "deaths", "mean_death_round"))],
    )
    print()
    print_table(
        ("Place", *(str(place) for place in summary["placement_histogram"])),
        [("Seats", *summary["placement_histogram"].values())],
    )
    print()
    print_table(
        ("Main tribe", "Seats", "Share", "Mean place", "Mean commit round"),
        (
            (row["tribe"] or "(none)", row["seats"], percent(row["share"]),
             row["mean_place"], row["mean_commit_round"])
            for row in summary["main_tribes"]
        ),
    )

    print("\nPer card (delta from overall mean placement)")
    boards = ("Final", *(f"R{number}" for number in BOARD_ROUNDS))
    print_table(
        ("Tier", "ID", "Name", "Offered", "Buyable", "Bought", "Buy rate",
         *(f"{board} {metric}" for board in boards for metric in ("seats", "place", "delta"))),
        (
            (card["tier"], card["id"], card["name"], card["offered"],
             card["offered_while_buyable"], card["bought"], percent(card["buy_rate"]),
             *(board[key] for board in (card["final_board"], *card["rounds"].values())
               for key in ("seats", "mean_place", "placement_delta")))
            for card in report["cards"]
        ),
    )

    print("\nPer round (means by final placement, board stats = attack + health)")
    print_table(
        ("Round", "Place", "Seats", "Tier", "Board stats", "Gold start", "Gold left"),
        (
            (number, bucket, stats["seats"], stats["mean_tier"], stats["mean_board_stats"],
             stats["mean_gold_start"], stats["mean_gold_left"])
            for number, buckets in report["rounds"].items()
            for bucket, stats in buckets.items()
        ),
    )

    print("\nTribe counts at round 8 vs final placement")
    print_table(
        ("Tribe",
         *(f"{bucket} {metric}" for bucket in TRIBE_BUCKETS for metric in ("seats", "place"))),
        (
            (tribe, *(stats[key] for stats in buckets.values() for key in ("seats", "mean_place")))
            for tribe, buckets in report["tribe_counts_at_round_8"].items()
        ),
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("match_dir", type=Path)
    parser.add_argument("--bot", help="Only include seats with this bot name")
    parser.add_argument("--colour", choices=("red", "blue"), help="Only include this colour")
    parser.add_argument("--out", type=Path, help="Also write the report as JSON")
    args = parser.parse_args()
    report = analyze(args.match_dir, args.bot, args.colour)
    print_report(report)
    if args.out is not None:
        with args.out.open("w", encoding="utf-8") as destination:
            json.dump(report, destination, indent=2, ensure_ascii=False, allow_nan=False)
            destination.write("\n")


if __name__ == "__main__":
    main()
