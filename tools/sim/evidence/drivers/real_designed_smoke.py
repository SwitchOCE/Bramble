#!/usr/bin/env python3
"""Prepare/report the small current-library smoke; no Godot subprocesses or gameplay bars."""

import argparse
import gzip
import hashlib
import json
import sys
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / "tools/sim"))
from designed_report import interval  # noqa: E402
from designed_setups import real_field  # noqa: E402
from evidence_io import read_json, write_json  # noqa: E402
from field import load_designed  # noqa: E402


def prepare(source, output):
    load_designed(source)
    write_json(output, real_field(read_json(source)))


def report(field_path, pairs_path, output, reps=8):
    field = read_json(field_path)
    expected = {
        (int(number), a["id"], b["id"]): {}
        for number, data in field["rounds"].items()
        for a, b in combinations(data["boards"], 2)
    }
    pairs_file = Path(pairs_path)
    pairs_text = (
        gzip.decompress(pairs_file.read_bytes()).decode() if pairs_file.suffix == ".gz" else pairs_file.read_text()
    )
    for raw in pairs_text.splitlines():
        row = json.loads(raw)
        key = row["round"], row["a"], row["b"]
        if key not in expected or row["replicate"] in expected[key]:
            raise ValueError("unexpected or duplicate pair/replicate")
        if row["trials"] != 2 or sum(row[k] for k in ("wins_a", "wins_b", "draws")) != 2:
            raise ValueError("each seed must contain both orientations")
        expected[key][row["replicate"]] = row
    pairs = []
    for (number, a, b), observations in expected.items():
        if set(observations) != set(range(reps)) or len({r["seed"] for r in observations.values()}) != reps:
            raise ValueError("incomplete independent paired-seed round robin")
        counts = {k: sum(r[k] for r in observations.values()) for k in ("wins_a", "wins_b", "draws")}
        rate = counts["wins_a"] / (2 * reps)
        pairs.append({"round": number, "a": a, "b": b, **counts, "win_rate_a": rate, "ci95": interval(rate, reps)})
    write_json(
        output,
        {
            "label": "CURRENT WAVE-1 COMBAT: constructed real-card smoke, not a strength estimate",
            "boards_by_round": {n: len(d["boards"]) for n, d in field["rounds"].items()},
            "pairs": pairs,
            "fights": len(pairs) * 2 * reps,
            "independent_seeds_per_pair": reps,
            "interval_method": (
                "95% Hoeffding bounds on paired-orientation seed clusters; conditional on fixed boards/layouts"
            ),
            "limitations": (
                "Small integration smoke only; authored histories and budgets do not establish shop attainability "
                "or typical player strength. No pass/fail gameplay bars."
            ),
            "sha256": {str(p): hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in (field_path, pairs_path)},
        },
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    prep = sub.add_parser("prepare")
    prep.add_argument("source")
    prep.add_argument("output")
    result = sub.add_parser("report")
    result.add_argument("field")
    result.add_argument("pairs")
    result.add_argument("output")
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args.source, args.output)
    else:
        report(args.field, args.pairs, args.output)
