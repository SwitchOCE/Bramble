#!/usr/bin/env python3
"""Reproduce Ooze tail metrics and per-round source attribution from frozen sim captures."""

import argparse
import gzip
import importlib.util
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SPEC = importlib.util.spec_from_file_location("a35_metrics", ROOT / "docs/ideation/evidence/a35-run1/analyze.py")
METRICS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(METRICS)
LINES = ("line_oozes_engine", "line_oozes_tempo")


def summarize(folder, baseline):
    arm = METRICS.load(folder)
    result = METRICS.confirmation(arm, METRICS.load(baseline))
    return {line: result[line] for line in LINES}


def attribute(record, side):
    snapshot = record["combat_start"][side]
    groups = defaultdict(Counter)
    details = []
    for event in snapshot.get("recruit_events", []):
        kind, fields = event["type"], event["fields"]
        if kind == "eat" and "meal_attack" in fields:
            gain = fields["attack"] + fields["health"]
            groups["eat_by_source"][fields["source"]] += gain
            groups["eat_by_meal"][fields["target"]] += gain
            groups["eat_by_cause"][fields.get("cause", "digest")] += gain
            details.append(event)
        elif kind == "ooze_share":
            groups["elder_by_target"][fields["target"]] += fields["attack"] + fields["health"]
        elif kind == "buff" and fields["duration"] == "permanent":
            source = fields.get("source", "unknown")
            groups["other_permanent_requested"][source] += fields["attack"] + fields["health"]
            groups["other_permanent_visible"][source] += (
                fields["after_attack"] + fields["after_health"] - fields["before_attack"] - fields["before_health"]
            )
        elif kind in ("buy", "sell", "triple", "swallow"):
            groups[kind][fields.get("unit", "unknown")] += 1
    for gain in record["result"]["carry"]:
        if int(gain["side"]) == side and gain["op"] in ("buff", "pending_gain"):
            groups["combat_carry_after_this_snapshot"][gain.get("cause", "permanent combat buff")] += (
                gain["attack"] + gain["health"]
            )
    return {
        "seed": record["seed"],
        "seat": int(record["players"][side]),
        "round": int(record["round"]),
        "line": snapshot["assigned_line"],
        "active_stats": snapshot["active_stats"],
        "body_stats": [
            {"id": unit["def_id"], "stats": unit["attack"] + unit["health"], "golden": unit["golden"]}
            for unit in snapshot["units"]
            if unit["active"]
        ],
        "sources": {name: dict(counter) for name, counter in groups.items()},
        "meals": details,
    }


def trace(raw):
    rows = []
    for path in sorted(raw.rglob("*.fights.jsonl.gz")):
        with gzip.open(path, "rt") as stream:
            for line in stream:
                record = json.loads(line)
                for side, snapshot in enumerate(record["combat_start"]):
                    if snapshot.get("assigned_line") in LINES and int(record["players"][side]) >= 0:
                        rows.append(attribute(record, side))
    keys = [(r["seed"], r["seat"], r["round"]) for r in rows]
    assert len(keys) == len(set(keys)), "duplicate seat-round captures"
    assert any(row["meals"] for row in rows), "no recruitment trace present"
    selected = set()
    for line in LINES:
        for number in (12, 15):
            ranked = sorted(
                [row for row in rows if row["line"] == line and row["round"] == number],
                key=lambda row: row["active_stats"],
                reverse=True,
            )
            selected.update((row["seed"], row["seat"]) for row in ranked[:3])
    return {
        "counting": (
            "Eating and Elder fields report permanent grants, including transfers; they are not a conserved "
            "net-created ledger. Other permanent visible deltas use before/after displayed stats and separate "
            "requested amounts beyond the display cap. Combat carry lands after this snapshot or next turn."
        ),
        "top_seats": [list(key) for key in sorted(selected)],
        "top_seat_rounds": [row for row in rows if (row["seed"], row["seat"]) in selected and 5 <= row["round"] <= 15],
        "all_ooze_seat_rounds": rows,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--arm", action="append", default=[], help="name=sim-result-directory")
    parser.add_argument("--trace", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    result = {"arms": {"baseline": summarize(args.baseline, args.baseline)}}
    for spec in args.arm:
        name, folder = spec.split("=", 1)
        result["arms"][name] = summarize(Path(folder), args.baseline)
    if args.trace:
        result["attribution"] = trace(args.trace)
    args.out.write_text(json.dumps(result, indent=2) + "\n")
    for arm, lines in result["arms"].items():
        for line, data in lines.items():
            print(arm, line, data["r12"], "late", data["r15_div_r12"], "n", data["late_n"])


if __name__ == "__main__":
    main()
