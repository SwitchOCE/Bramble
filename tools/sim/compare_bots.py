#!/usr/bin/env python3
"""Compare trace=on bench runs before/after a behavior-preserving optimization.

Usage: compare_bots.py <before-prefix> <after-prefix>
Timing must be collected with profile=off and comparable machine load. The JSON output
includes nearest-rank p95 and a 2,000-game cost extrapolated from observed full-game turns.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import sys
from pathlib import Path


def read_rows(prefix: str, part: str) -> list[dict[str, str]]:
    with Path(f"{prefix}.{part}.csv").open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))


def timing(prefix: str) -> dict:
    rows = read_rows(prefix, "turns")
    games = {(r["seed"], r.get("leg", "0")) for r in rows}
    values = sorted(int(r["usec"]) / 1000 for r in rows)
    if not values:
        raise ValueError("no bot turns")
    return {
        "games": len(games),
        "turns": len(values),
        "mean_ms": sum(values) / len(values),
        "p95_ms": values[math.ceil(0.95 * len(values)) - 1],
        "bot_seconds_per_game": sum(values) / 1000 / len(games),
        "spread_bot_core_hours": sum(values) / 1000 / len(games) * 2000 / 3600,
    }


def profile(prefix: str) -> dict:
    rows = read_rows(prefix, "profile")
    if not rows:
        return {}
    return {
        key: sum(int(row[key]) for row in rows) / len(rows) / 1000
        for key in ("eval", "lanes", "held", "setup", "fights", "other")
    }


def compare(before: str, after: str) -> dict:
    traces = []
    hashes = []
    for prefix in (before, after):
        raw = Path(f"{prefix}.trace.jsonl").read_bytes()
        traces.append([json.loads(line) for line in raw.splitlines()])
        hashes.append(hashlib.sha256(raw).hexdigest())
    if not traces[0] or traces[0] != traces[1]:
        raise ValueError("bot turn boards/state differ (or traces are empty)")
    for part in ("players", "rounds", "cards"):
        if read_rows(before, part) != read_rows(after, part):
            raise ValueError(f"{part} differ")
    fight_data = []
    fight_hashes = []
    for prefix in (before, after):
        path = Path(f"{prefix}.fights.jsonl")
        if path.exists():
            raw = path.read_bytes()
            fight_data.append([json.loads(line) for line in raw.splitlines()])
            fight_hashes.append(hashlib.sha256(raw).hexdigest())
    if fight_data and (len(fight_data) != 2 or not fight_data[0] or fight_data[0] != fight_data[1]):
        raise ValueError("full fight outcomes/carry/Last Stand differ (or traces are empty)")
    return {
        "identical_turn_boards": len(traces[0]),
        "trace_sha256": hashes,
        "identical_fights": len(fight_data[0]) if fight_data else None,
        "fight_trace_sha256": fight_hashes,
        "before": timing(before),
        "after": timing(after),
    }


if __name__ == "__main__":
    print(json.dumps(compare(sys.argv[1], sys.argv[2]), indent=2))
