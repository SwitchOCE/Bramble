#!/usr/bin/env python3
"""Summarise tools/sim/place_probe.gd CSVs: what a layout is worth per fight.

Usage: python3 tools/sim/summarize_probe.py <csv> [<csv> ...]

Every column is a win rate (ties count half) of the same board against the real enemy board, on
the same fight seeds. Gains are in win-rate points over `shuffled_all` (every unit moved at
random), with 95% CIs paired by fight side.
"""

import csv
import math
import sys
from collections import Counter
from pathlib import Path

LADDER = [
    ("shuffled_free", "Shuffled, pinned units kept"),
    ("rule", "Rule"),
    ("actual", "Hard (rule + 20 fights on the scout)"),
    ("generic", "150 fights vs another board"),
    ("scouted", "150 fights vs the scout"),
    ("best", "150 fights vs the real board"),
]
STAGES = [("Rounds 1-4", 1, 4), ("Rounds 5-8", 5, 8), ("Rounds 9+", 9, 99), ("All", 1, 99)]


def mean_ci(values: list[float]) -> tuple[float, float]:
    n = len(values)
    if n < 2:
        return (values[0] if values else 0.0), 0.0
    mean = sum(values) / n
    var = sum((v - mean) ** 2 for v in values) / (n - 1)
    return mean, 1.96 * math.sqrt(var / n)


def cell(values: list[float]) -> str:
    mean, ci = mean_ci(values)
    return f"{100 * mean:+.1f} ±{100 * ci:.1f}"


def has(row: dict[str, str], key: str) -> bool:
    return key in row and row[key] not in ("", "-1", "-1.0000") and float(row[key]) >= 0


def ladder(rows: list[dict[str, str]]) -> None:
    keys = [k for k, _ in LADDER if all(has(r, k) for r in rows[:1])]
    chosen = [r for r in rows if all(has(r, k) for k in keys)]
    print(f"Win-rate points over shuffling every unit; {len(chosen)} fight sides with every column.")
    print("| Stage | Sides | " + " | ".join(name for k, name in LADDER if k in keys) + " |")
    print("|---|---:|" + "---:|" * len(keys))
    for name, low, high in STAGES:
        stage = [r for r in chosen if low <= int(r["round"]) <= high]
        if len(stage) < 2:
            continue
        cells = [cell([float(r[k]) - float(r["shuffled_all"]) for r in stage]) for k in keys]
        print(f"| {name} | {len(stage)} | " + " | ".join(cells) + " |")
    print()
    pairs = [("actual", "rule"), ("scouted", "generic")]
    for a, b in pairs:
        if a in keys and b in keys:
            print(f"- {a} minus {b}: {cell([float(r[a]) - float(r[b]) for r in chosen])}")
    if "scout_same" in rows[0]:
        same = [float(r["scout_same"]) for r in rows if has(r, "scout_same")]
        if same:
            print(f"- Scouted units standing in the same slot at the fight: {100 * sum(same) / len(same):.0f}%")
    contested = [r for r in rows if 0.1 < float(r["shuffled_all"]) < 0.9]
    print(f"- Contested fights (shuffled wins 10-90%): {100 * len(contested) / len(rows):.0f}%")
    if contested:
        print(f"- Real-board ceiling in contested fights: {cell([gain(r) for r in contested])}")
    print()


def gain(row: dict[str, str]) -> float:
    return float(row["best"]) - float(row["shuffled_all"])


def cards(rows: list[dict[str, str]], top: int = 8) -> None:
    """Real-board ceiling in contested fights with a card on either side against without it."""
    if "mine" not in rows[0]:
        return
    contested = [r for r in rows if 0.1 < float(r["shuffled_all"]) < 0.9]
    boards = Counter()
    for r in rows:
        boards.update(set(r["mine"].split(";")) - {"-"})
    seen = Counter()
    for r in contested:
        seen.update(set(r["mine"].split(";") + r["theirs"].split(";")) - {"-"})
    out = []
    for card, count in seen.items():
        if count < 25:
            continue
        inside = [gain(r) for r in contested if card in r["mine"].split(";") + r["theirs"].split(";")]
        outside = [gain(r) for r in contested if card not in r["mine"].split(";") + r["theirs"].split(";")]
        if len(outside) < 2:
            continue
        out.append((mean_ci(inside)[0] - mean_ci(outside)[0], card, count, boards[card] / len(rows)))
    out.sort(reverse=True)
    print("| Card | Contested fights | Share of boards | Ceiling with it minus without |")
    print("|---|---:|---:|---:|")
    for diff, card, count, share in out[:top]:
        print(f"| {card} | {count} | {100 * share:.0f}% | {100 * diff:+.1f} |")
    print()


def main(paths: list[str]) -> None:
    rows: list[dict[str, str]] = []
    for path in paths:
        with Path(path).open(newline="") as handle:
            rows += list(csv.DictReader(handle))
    print(f"{len(rows)} fight sides from {len(paths)} file(s)\n")
    ladder(rows)
    cards(rows)


if __name__ == "__main__":
    main(sys.argv[1:])
