#!/usr/bin/env python3
"""Requested 1,000-game spread bar, with provisional progress and uncertainty.

Usage: python3 tools/sim/summarize_commit_spread.py build/sim/commit-b872a6b-spread
Read merged output after completion or flushed shard CSVs while the detached job runs.
The older summarize_bench.py keeps its separate 2,000-game standard unchanged.
"""

import csv
import json
import math
import os
import statistics
import sys
import time
from collections import defaultdict
from datetime import UTC, datetime, timedelta
from pathlib import Path


def save(path, text):
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temporary.write_text(text)
    temporary.replace(path)


def wilson(wins, total):
    z = 1.96
    rate = wins / total
    denominator = 1 + z * z / total
    center = (rate + z * z / (2 * total)) / denominator
    radius = z * math.sqrt(rate * (1 - rate) / total + z * z / (4 * total * total)) / denominator
    return [round(100 * (center - radius), 2), round(100 * (center + radius), 2)]


def diagnostic_tables(folder, complete):
    """Descriptive round/card cohorts; do not infer a fix before the spread is complete."""
    rounds = defaultdict(list)
    cards = defaultdict(lambda: defaultdict(set))
    for part in ["rounds", "cards"]:
        merged = folder / f"spread.{part}.csv"
        files = [merged] if merged.exists() else sorted(folder.glob(f"shard-*.{part}.csv"))
        for file in files:
            with file.open() as stream:
                for row in csv.DictReader(stream):
                    try:
                        seed = int(row["seed"])
                        if seed not in complete:
                            continue
                        strategy = row["strategy"]
                        if part == "rounds" and int(row["round"]) in [3, 5, 8, 10, 12, 15]:
                            values = {key: int(row[key]) for key in ["units", "attack", "health", "tier", "gold_left"]}
                            rounds[(strategy, int(row["round"]))].append(values)
                        elif part == "cards":
                            cards[strategy][row["card"]].add((seed, int(row["seat"])))
                    except (ValueError, TypeError, KeyError):
                        continue
    round_rows = []
    for (strategy, round_now), rows in sorted(rounds.items()):
        round_rows.append(
            {
                "strategy": strategy,
                "round": round_now,
                "seats_reaching_round": len(rows),
                "units": round(statistics.mean(r["units"] for r in rows), 3),
                "stats": round(statistics.mean(r["attack"] + r["health"] for r in rows), 3),
                "tier": round(statistics.mean(r["tier"] for r in rows), 3),
                "gold_left": round(statistics.mean(r["gold_left"] for r in rows), 3),
            }
        )
    card_rows = {
        strategy: [
            {"card": card, "final_seats": len(seats)}
            for card, seats in sorted(values.items(), key=lambda item: len(item[1]), reverse=True)[:10]
        ]
        for strategy, values in sorted(cards.items())
    }
    save(folder / "round-diagnostics.json", json.dumps(round_rows, indent=2) + "\n")
    save(folder / "card-diagnostics.json", json.dumps(card_rows, indent=2) + "\n")


def summarize(folder):
    manifest = json.loads((folder / "manifest.json").read_text())
    merged = folder / "spread.players.csv"
    files = [merged] if merged.exists() else sorted(folder.glob("shard-*.players.csv"))
    games = defaultdict(dict)
    for file in files:
        with file.open() as stream:
            for row in csv.DictReader(stream):
                try:
                    seed, seat, place = int(row["seed"]), int(row["seat"]), int(row["place"])
                except (ValueError, TypeError, KeyError):
                    continue
                if 0 <= seat < 8 and 1 <= place <= 8:
                    games[seed][seat] = row
    complete = {seed: seats for seed, seats in games.items() if len(seats) == 8}
    groups = defaultdict(list)
    for seats in complete.values():
        for row in seats.values():
            groups[row["strategy"]].append(row)
    table = []
    for strategy, rows in sorted(groups.items()):
        places = [int(row["place"]) for row in rows]
        wins = places.count(1)
        table.append(
            {
                "strategy": strategy,
                "seats": len(rows),
                "wins": wins,
                "win_percent": round(100 * wins / len(rows), 3),
                "win_interval_95": wilson(wins, len(rows)),
                "place": round(statistics.mean(places), 3),
                "pick_percent": round(100 * len(rows) / (8 * len(complete)), 3),
                "place_interval_95": [
                    round(statistics.mean(places) - 1.96 * statistics.stdev(places) / math.sqrt(len(places)), 3),
                    round(statistics.mean(places) + 1.96 * statistics.stdev(places) / math.sqrt(len(places)), 3),
                ]
                if len(places) > 1
                else [None, None],
                "top4_percent": round(100 * sum(p <= 4 for p in places) / len(rows), 3),
                "tier6_percent": round(100 * sum(int(r["tier6_turn"]) > 0 for r in rows) / len(rows), 3),
                "final_units": round(statistics.mean(int(r["final_units"]) for r in rows), 3),
                "final_stats": round(statistics.mean(int(r["final_attack"]) + int(r["final_health"]) for r in rows), 3),
            }
        )
    qualifying = [r["strategy"] for r in table if 6 <= r["win_percent"] <= 25]
    dominant = [r["strategy"] for r in table if r["win_percent"] > 25]
    ordered = sorted(table, key=lambda r: r["place"], reverse=True)
    bird_rows = [r for r in ordered if r["strategy"].startswith("birds_")]
    weakest = ordered[0] if ordered else None
    clearly_weakest_bird = bool(
        len(complete) == manifest["games"]
        and len(ordered) > 1
        and weakest["strategy"].startswith("birds_")
        and weakest["place_interval_95"][0] is not None
        and ordered[1]["place_interval_95"][1] is not None
        and weakest["place_interval_95"][0] > ordered[1]["place_interval_95"][1]
    )
    started = datetime.fromisoformat((folder / "started.utc").read_text().strip().replace("Z", "+00:00"))
    finished = folder / "finished.utc"
    now = (
        datetime.fromisoformat(finished.read_text().strip().replace("Z", "+00:00"))
        if finished.exists()
        else datetime.now(UTC)
    )
    elapsed = (now - started).total_seconds()
    eta = started + timedelta(seconds=elapsed * manifest["games"] / len(complete)) if complete else None
    clearly_weakest_among_birds = bool(
        len(complete) == manifest["games"]
        and len(bird_rows) > 1
        and bird_rows[0]["place_interval_95"][0] is not None
        and bird_rows[1]["place_interval_95"][1] is not None
        and bird_rows[0]["place_interval_95"][0] > bird_rows[1]["place_interval_95"][1]
    )
    result = {
        "gameplay_head": manifest["gameplay_head"],
        "games": len(complete),
        "requested_games": manifest["games"],
        "elapsed_seconds": round(elapsed, 1),
        "eta_utc": eta.isoformat() if eta else None,
        "hard_deadline_utc": (started + timedelta(seconds=manifest["timeout_seconds"])).isoformat(),
        "qualifying_strategies": qualifying,
        "over_25_percent": dominant,
        "bar_meets_on_current_sample": len(qualifying) >= 5 and not dominant,
        "final_pass": len(complete) == manifest["games"] and len(qualifying) >= 5 and not dominant,
        "strategies": table,
        "weakest_strategy": weakest["strategy"] if weakest else None,
        "weakest_bird_strategy": bird_rows[0]["strategy"] if bird_rows else None,
        "clearly_weakest_bird_by_place_intervals": clearly_weakest_bird,
        "clearly_weakest_among_birds_by_place_intervals": clearly_weakest_among_birds,
        "final_verdict": ("PASS" if len(qualifying) >= 5 and not dominant else "FAIL")
        if len(complete) == manifest["games"]
        else "PENDING",
    }
    diagnostic_tables(folder, complete)
    save(folder / "progress.json", json.dumps(result, indent=2) + "\n")
    lines = [
        "# Pinned strategy spread on b872a6b",
        "",
        f"Complete games: {len(complete)}/{manifest['games']}. Gameplay head: `{manifest['gameplay_head']}`.",
        "",
        "Five tribes per lobby; every pin is eligible for that seed's actual lobby. "
        "No gameplay or strategy weights changed.",
        "",
        "Requested bar: at least five strategies win 6-25% of their seats; no strategy exceeds 25%. "
        "The 95% Wilson intervals are context, not relaxed thresholds.",
        "",
        f"Qualifying: {len(qualifying)}. Above 25%: {', '.join(dominant) or 'none'}. "
        f"Final pass: {result['final_pass']}.",
        "",
        f"ETA UTC: {result['eta_utc']}; hard deadline: {result['hard_deadline_utc']}.",
        "",
        "| Strategy | Seats | Wins | Win % (95% interval) | Place | Top 4 % | "
        "Reached T6 % | Final units | Final stats |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in sorted(table, key=lambda r: r["place"]):
        low, high = row["win_interval_95"]
        lines.append(
            f"| {row['strategy']} | {row['seats']} | {row['wins']} | "
            f"{row['win_percent']:.2f} ({low:.2f}-{high:.2f}) | {row['place']:.3f} | "
            f"{row['top4_percent']:.2f} | {row['tier6_percent']:.2f} | "
            f"{row['final_units']:.2f} | {row['final_stats']:.2f} |"
        )
    lines += [
        "",
        "Partial results are provisional. A weakest Bird build or a dominant strategy is not established "
        "from a small interim sample. No Bird or Nest rule is changed by this run.",
        "",
        f"Requested 1,000-game verdict: **{result['final_verdict']}**.",
        f"Weakest strategy: {result['weakest_strategy']}; weakest Bird: {result['weakest_bird_strategy']}.",
        f"Clearly weakest Bird (complete run, nonoverlapping 95% place intervals): {clearly_weakest_bird}.",
    ]
    save(folder / "requested-report.md", "\n".join(lines) + "\n")
    print(
        json.dumps(
            {
                key: result[key]
                for key in [
                    "games",
                    "requested_games",
                    "eta_utc",
                    "qualifying_strategies",
                    "over_25_percent",
                    "final_pass",
                ]
            }
        )
    )
    return result


if __name__ == "__main__":
    folder = Path(sys.argv[1])
    if len(sys.argv) > 2 and sys.argv[2] == "--watch":
        while True:
            result = summarize(folder)
            if (folder / "status").read_text().strip() != "running":
                summarize(folder)
                break
            if datetime.now(UTC) >= datetime.fromisoformat(result["hard_deadline_utc"]):
                break
            time.sleep(60)
    else:
        summarize(folder)
