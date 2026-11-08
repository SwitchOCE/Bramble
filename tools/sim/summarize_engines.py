"""Summarize lean-arm ending measurements. All results are bot data."""

import argparse
import json
import statistics
from pathlib import Path


def summarize(rows):
    eligible = [row for row in rows if row["comeback_eligible"]]
    return {
        "evidence": "bot data; not a human-balance estimate",
        "arm": "lean",
        "games": len(rows),
        "seeds": sorted(row["seed"] for row in rows),
        "mean_rounds": statistics.mean(row["rounds"] for row in rows),
        "mean_last_four_rounds": statistics.mean(row["last_four_rounds"] for row in rows),
        "comeback_eligible_games": len(eligible),
        "comeback_games": sum(row["comeback"] for row in eligible),
        "comeback_pct": 100 * sum(row["comeback"] for row in eligible) / len(eligible) if eligible else None,
        "last_stands": sum(row["last_stands"] for row in rows),
        "early_last_stands": sum(row["early_last_stands"] for row in rows),
        "last_blows": sum(row["last_blows"] for row in rows),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--expected", type=int, default=200)
    args = parser.parse_args()
    rows = [
        json.loads(line[10:])
        for path in args.paths
        for line in path.read_text().splitlines()
        if line.startswith("eng_game: ")
    ]
    if len(rows) != args.expected or len({row["seed"] for row in rows}) != args.expected:
        parser.error(f"expected {args.expected} complete, distinct games; got {len(rows)}")
    print(json.dumps(summarize(rows), indent=2))


if __name__ == "__main__":
    main()
