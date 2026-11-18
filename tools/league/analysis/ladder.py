#!/usr/bin/env python3
"""Strength-check, practice and official scores in the order supplied."""
import argparse
from pathlib import Path

from match_data import Match, publish


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("matches", nargs="+", type=Path)
    p.add_argument("--out-dir", type=Path, help="default: first match directory")
    p.add_argument("--trends", action="store_true", help="include per-match card buy rates and tribe metrics in JSON")
    args = p.parse_args()
    rows = []
    lines = ["# Strength ladder", "", "| Match | Red | Blue | Games / pairs | Red place | Blue place | Red − blue |",
             "|---|---|---|---|---|---|---|"]
    for directory in args.matches:
        match = Match(directory)
        s = match.score()
        row = {"match": directory.name, "red": match.summary["red_label"], "blue": match.summary["blue_label"], **s}
        rows.append(row)
        if args.trends:
            from cards import card_stats
            from tribes import tribe_stats
            row["buy_rates"] = {scope: {card: stats["buy"] for card, stats in cards.items()}
                                for scope, cards in card_stats(match).items()}
            row["tribes"] = tribe_stats(match)
        lines.append(f"| {directory.name} | {row['red']} | {row['blue']} | {s['games']} / {s['seed_pairs']} | "
                     f"{s['red_avg_place']:.3f} ± {s['red_ci95']:.3f} | {s['blue_avg_place']:.3f} ± {s['blue_ci95']:.3f} | "
                     f"{s['gap_red_minus_blue']:+.3f} ± {s['gap_ci95']:.3f} |")
    lines += ["", "Lower placement wins. Intervals are the harness's 95% half-widths over seed pairs."]
    publish(args.out_dir or args.matches[0], "ladder", rows, "\n".join(lines))


if __name__ == "__main__":
    main()

