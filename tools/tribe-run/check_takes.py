#!/usr/bin/env python3
"""Check rankings/takes--<seed>.json files against data-format.md.

Usage: check_takes.py RUN_DIR [SEED ...]
With no seeds, checks every takes file. Exit 1 and print each problem if any.
"""
import json, sys
from pathlib import Path

SLACK = 3
errs = []


def limit(where, what, s, n, least=1):
    k = len(str(s).split()) if isinstance(s, str) else 0
    if k < least:
        errs.append(f"{where}: {what} is empty or too short")
    elif k > n + SLACK:
        errs.append(f"{where}: {what} has {k} words (limit {n})")


def check(run_dir, seed):
    where = f"takes--{seed}.json"
    try:
        t = json.loads((run_dir / "rankings" / where).read_text())
    except Exception as e:  # noqa: BLE001
        errs.append(f"{where}: cannot read ({e})")
        return
    designs = sorted(p.name for p in (run_dir / "designs").glob(f"{seed}--*") if p.is_dir())
    rk = run_dir / "rankings" / f"seed--{seed}.json"
    order = json.loads(rk.read_text()).get("order", []) if rk.exists() else []
    if t.get("seed") != seed:
        errs.append(f"{where}: seed should be {seed}")
    limit(where, "shared", t.get("shared"), 18)
    limit(where, "differ", t.get("differ"), 18)
    got = [x.get("design") for x in t.get("takes", [])]
    if sorted(got) != designs:
        errs.append(f"{where}: takes must cover exactly {designs}")
    elif order and got != order:
        errs.append(f"{where}: takes should be in the seed ranking's order {order}")
    for x in t.get("takes", []):
        w = f"{where} {x.get('design')}"
        limit(w, "label", x.get("label"), 4)
        limit(w, "line", x.get("line"), 22)
        limit(w, "look_if", x.get("look_if"), 12)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    run_dir = Path(sys.argv[1])
    seeds = sys.argv[2:] or sorted(p.stem.split("--", 1)[1] for p in (run_dir / "rankings").glob("takes--*.json"))
    for s in seeds:
        check(run_dir, s)
    for e in errs:
        print(e)
    print(f"{len(seeds)} takes file(s) checked, {len(errs)} problem(s)")
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
