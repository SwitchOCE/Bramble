#!/usr/bin/env python3
"""Summarize per-seat Ring access, growth, economy and bodies from opt-in captures."""

import argparse
import gzip
import json
import statistics
from collections import Counter
from pathlib import Path

FAIRIES = ("line_fairies_ring", "line_fairies_court")
CARDS = ("old_moth_annis", "cluricaun", "lob_lie_by_the_fire", "silky", "fairy_monarch", "cradle_fetch", "sally_spore")


def records(folder):
    for path in sorted(folder.rglob("*.fights.jsonl*")):
        opener = gzip.open if path.suffix == ".gz" else open
        with opener(path, "rt") as stream:
            for line in stream:
                yield json.loads(line)


def inspect(folder):
    rows = []
    for record in records(folder):
        for side, snapshot in enumerate(record["combat_start"]):
            line = snapshot.get("assigned_line")
            if line not in FAIRIES or record["players"][side] < 0:
                continue
            slots = record["input"]["slots"][side]
            counts = [sum(r.get("count", 0) for r in effects if r.get("name") == "Ring") for effects in slots]
            bodies = [u for u in snapshot["units"] if u["active"]]
            kinds = Counter()
            sources = Counter()
            for event in snapshot.get("recruit_events", []):
                fields = event["fields"]
                kinds[event["type"]] += 1
                if event["type"] == "trigger":
                    sources[fields.get("source", "")] += 1
            rows.append(
                {
                    "seed": record["seed"],
                    "seat": record["players"][side],
                    "round": record["round"],
                    "line": line,
                    "active_stats": snapshot["active_stats"],
                    "post_start_stats": record["after_start_effects"][side]["active_stats"],
                    "ring_size": record["input"]["fight_rules"][side]["ring_size"],
                    "rings": counts,
                    "covered": sum(c > 0 for c in counts),
                    "recruit_occupied": sum(u["location"] == "board" for u in snapshot["recruit_units"]),
                    "cards": {card: sum(u["def_id"] == card for u in bodies) for card in CARDS},
                    "bodies": [
                        {"id": u["def_id"], "slot": u["slot"], "stats": u["attack"] + u["health"]} for u in bodies
                    ],
                    "events": dict(kinds),
                    "trigger_sources": dict(sources),
                }
            )
    summary = {}
    for line in FAIRIES:
        summary[line] = {}
        for number in (3, 6, 9, 12):
            selected = [r for r in rows if r["line"] == line and r["round"] == number]
            if not selected:
                continue
            with_cluricaun = [r for r in selected if r["cards"]["cluricaun"]]
            summary[line][str(number)] = {
                "n": len(selected),
                "median_stats": statistics.median(r["active_stats"] for r in selected),
                "median_post_start": statistics.median(r["post_start_stats"] for r in selected),
                "median_covered": statistics.median(r["covered"] for r in selected),
                "median_rings": statistics.median(sum(r["rings"]) for r in selected),
                "median_size": statistics.median(r["ring_size"] for r in selected),
                "full_rainbow": sum(r["covered"] == 7 for r in selected),
                "cluricaun": len(with_cluricaun),
                "cluricaun_blocked": sum(r["covered"] < 7 for r in with_cluricaun),
                "sally_full_board": sum(r["cards"]["sally_spore"] > 0 and r["recruit_occupied"] == 7 for r in selected),
                "card_seats": {card: sum(r["cards"][card] > 0 for r in selected) for card in CARDS},
            }
    return {"summary": summary, "seat_rounds": rows}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("captures", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    result = inspect(args.captures)
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result["summary"], indent=2))


if __name__ == "__main__":
    main()
