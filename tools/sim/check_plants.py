#!/usr/bin/env python3
"""Known answers: a zero-growth run is exact; a forced test engine creates a tail and dominates."""

import argparse
import csv
import json
import statistics
from pathlib import Path

from field import boards_from_capture


def check(control, null, broken, field):
    exact = {
        part: Path(f"{control}.{part}").read_bytes() == Path(f"{null}.{part}").read_bytes()
        for part in ["players.csv", "rounds.csv", "cards.csv", "fights.jsonl"]
    }
    with Path(f"{broken}.players.csv").open(newline="") as stream:
        planted = [row for row in csv.DictReader(stream) if row["seat"] == "0"]
    by_game = {}
    for board in boards_from_capture([Path(f"{broken}.fights.jsonl")]):
        if board["round"] == 6:
            by_game.setdefault(board["seed"], []).append(board)
    tails = []
    for boards in by_game.values():
        median = statistics.median(b["combat_start"]["active_stats"] for b in boards)
        tails.extend(b["combat_start"]["active_stats"] >= 2 * median for b in boards if b["line"] == "plant_engine")
    rates = [row["line_point_rates"]["plant_engine"] for row in field["rounds"].values()]
    win_rate = sum(int(row["place"]) == 1 for row in planted) / len(planted) if planted else 0
    return {
        "null_exact": exact,
        "broken_lobbies": len(planted),
        "broken_win_rate": win_rate,
        "round6_planted_boards": len(tails),
        "round6_tail_boards": sum(tails),
        "field_point_rates": rates,
        "passes": all(exact.values())
        and len(planted) >= 8
        and len(tails) == len(planted)
        and all(tails)
        and win_rate >= 0.75
        and bool(rates)
        and min(rates) >= 0.8,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ["control", "null", "broken"]:
        parser.add_argument(name, type=Path)
    parser.add_argument("--field", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    report = check(args.control, args.null, args.broken, json.loads(args.field.read_text()))
    args.out.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report["passes"] else 1)


if __name__ == "__main__":
    main()
