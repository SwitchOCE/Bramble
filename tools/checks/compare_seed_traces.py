#!/usr/bin/env python3
"""Compare ordered per-fight results, including full event hashes, from two QA soaks."""

import argparse
import json
from pathlib import Path


def read_trace(path: Path) -> list[dict]:
    return [
        json.loads(line.removeprefix("seed_trace: "))
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.startswith("seed_trace: ")
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("before", type=Path)
    parser.add_argument("after", type=Path)
    args = parser.parse_args()
    before, after = read_trace(args.before), read_trace(args.after)
    if not before or len(before) != len(after):
        print(f"FAIL: fight counts differ or empty: {len(before)} before, {len(after)} after")
        return 1
    for index, (old, new) in enumerate(zip(before, after, strict=True)):
        if old != new:
            print(f"FAIL: fight {index}: seed {old['seed']} round {old['round']} players {old['players']}")
            print(f"before: {json.dumps(old, sort_keys=True)}")
            print(f"after:  {json.dumps(new, sort_keys=True)}")
            return 1
    seeds = sorted({entry["seed"] for entry in before})
    print(f"PASS: {len(before)} identical fight results and event hashes across {len(seeds)} seeds")
    print(f"seeds: {seeds[0]}-{seeds[-1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
