#!/usr/bin/env python3
"""Summarize commit_probe's real Hard lobbies; keep raw logs beside the JSON report.

Usage: python3 tools/sim/summarize_commit.py build/commit/before.log
Tribe picks mean the final selected strategy, not units purchased. Own-tribe stats
include same-tribe unit grants plus the explicit standing bonus (reported
separately as tribe_bonus); neutral spell
stats stay separate. Attribution via the optional observer is approximate.
"""

import collections
import json
import statistics
import sys
from pathlib import Path

TRIBES = ["Hedgerow folk", "Fairies", "Oozes", "Birds", "Bog folk", "Hunters"]


def average(values):
    return round(statistics.mean(values), 3) if values else None


def summarize(path):
    rows = []
    for line in Path(path).read_text().splitlines():
        if line.startswith("commit_row: "):
            rows.append(json.loads(line.removeprefix("commit_row: ")))
    strategies = {}
    for file in Path("content/bots/strategies").glob("*.json"):
        entry = json.loads(file.read_text())
        strategies[entry["id"]] = entry.get("needs_tribes", [])
    final = [r for r in rows if r["round"] == "final"]
    if not final:
        raise ValueError("No completed lobbies in " + path)

    def counts(row):
        return collections.Counter(t for u in row["board"] for t in u["tribes"])

    def main(row):
        return max(counts(row).values(), default=0)

    committed = [r["place"] for r in final if main(r) >= 6]
    mixed = [r["place"] for r in final if main(r) <= 4]
    result = {
        "lobbies": len({r["seed"] for r in final}),
        "seats": len(final),
        "committed_6plus": {"n": len(committed), "place": average(committed)},
        "mixed_4minus": {"n": len(mixed), "place": average(mixed)},
        "tribes": {},
        "rounds": {},
        "cards": {},
    }
    for card in [
        "seven_whistlers",
        "fairy_monarch",
        "elder_ooze",
        "moss_ooze",
        "laird_of_sett",
        "queen_of_elfland",
        "charcoal_burner",
    ]:
        holders = [r for r in final if any(u["id"] == card for u in r["board"])]
        result["cards"][card] = {"final_boards": len(holders), "place": average([r["place"] for r in holders])}
    for tribe in TRIBES:
        picks = [r for r in final if tribe in strategies.get(r["build"], [])]
        dominant = [r for r in final if counts(r)[tribe] == main(r) and main(r) > 0]
        result["tribes"][tribe] = {
            "picks": len(picks),
            "pick_percent": round(100 * len(picks) / len(final), 2),
            "pick_place": average([r["place"] for r in picks]),
            "main_board_place": average([r["place"] for r in dominant]),
        }
    for rnd in sorted({r["round"] for r in rows if isinstance(r["round"], int)}):
        sample = [r for r in rows if r["round"] == rnd and r["board"]]
        totals, largest, shares = [], [], []
        sources = collections.Counter()
        for row in sample:
            stats = [u["attack"] + u["health"] for u in row["board"]]
            totals.append(sum(stats))
            largest.append(max(stats))
            shares.append(100 * max(stats) / max(1, sum(stats)))
            for unit in row["board"]:
                for key, value in unit.get("parts", {}).items():
                    sources[key.split("|")[0].split(":")[0]] += value
        total = sum(totals)
        fight = [r["fight_biggest"] for r in sample if "fight_biggest" in r]
        result["rounds"][rnd] = {
            "boards": len(sample),
            "fight_largest_stats": average([v["stats"] for v in fight]),
            "fight_largest_percent": average([v["share"] for v in fight]),
            "fight_largest_max": max([v["stats"] for v in fight], default=0),
            "largest_stats": average(largest),
            "largest_board_percent": average(shares),
            "board_stats": average(totals),
            "largest_max": max(largest, default=0),
            "largest_peak_unit": max(
                (u for row in sample for u in row["board"]),
                key=lambda u: u["attack"] + u["health"],
                default={"id": ""},
            )["id"],
            "source_percent": {k: round(100 * v / max(1, total), 3) for k, v in sources.items()},
        }
    r15 = result["rounds"].get(15, {}).get("source_percent", {})
    result["passes"] = {
        "commitment": bool(committed and mixed and average(committed) < average(mixed)),
        "own_tribe_above_2": r15.get("own_tribe", 0) + r15.get("tribe_bonus", 0) > 2,
        "direct_bonus_above_2": r15.get("tribe_bonus", 0) > 2,
        "oozes_above_5": result["tribes"]["Oozes"]["pick_percent"] > 5,
        "birds_above_5": result["tribes"]["Birds"]["pick_percent"] > 5,
    }
    return result


if __name__ == "__main__":
    print(json.dumps(summarize(sys.argv[1]), indent=2))
