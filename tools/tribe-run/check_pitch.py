#!/usr/bin/env python3
"""Check pitch.json files against data-format.md.

Usage: check_pitch.py RUN_DIR [DESIGN_ID ...]
With no ids, checks every design that has a pitch.json. Exit 1 and print each problem if any.
"""
import json, sys
from pathlib import Path

SHAPES = {"tall", "wide", "economy", "burst", "slow-burn", "in-fight", "mixed"}
ROLES = {"body", "engine", "buff", "economy", "multiplier", "payoff", "utility"}
SLACK = 3  # word limits are "about": allow a few over
errs = []


def words(s):
    return len(str(s).split())


def limit(where, what, s, n):
    if not isinstance(s, str) or not s.strip():
        errs.append(f"{where}: {what} is empty")
    elif words(s) > n + SLACK:
        errs.append(f"{where}: {what} has {words(s)} words (limit {n})")


def check(run_dir, did):
    ddir = run_dir / "designs" / did
    where = f"{did}/pitch.json"
    try:
        p = json.loads((ddir / "pitch.json").read_text())
        idx = json.loads((ddir / "design.json").read_text())
        ver = json.loads((ddir / f"v{p.get('v')}.json").read_text())
    except Exception as e:  # noqa: BLE001
        errs.append(f"{where}: cannot read the pitch, design.json or its version file ({e})")
        return
    if p.get("design_id") != did:
        errs.append(f"{where}: design_id should be {did}")
    if idx.get("final_version") and p.get("v") != idx["final_version"]:
        errs.append(f"{where}: v should be the final version, {idx['final_version']}")
    uids = {c["uid"] for c in ver.get("units", []) + ver.get("extras", [])}
    limit(where, "hook", p.get("hook"), 20)
    limit(where, "verdict", p.get("verdict"), 18)
    if any(ch.isdigit() for ch in str(p.get("verdict", ""))):
        errs.append(f"{where}: verdict should carry no ratings, rank or other numbers (the page shows those)")
    loop = p.get("loop", [])
    if len(loop) != 3:
        errs.append(f"{where}: loop needs exactly 3 steps")
    for i, s in enumerate(loop):
        limit(where, f"loop[{i}]", s, 12)
    g = p.get("growth", {})
    if g.get("shape") not in SHAPES:
        errs.append(f"{where}: growth.shape {g.get('shape')!r} is not one of {sorted(SHAPES)}")
    limit(where, "growth.line", g.get("line"), 18)
    for k in ("early", "mid", "late"):
        limit(where, f"feel.{k}", p.get("feel", {}).get(k), 10)
    stars = p.get("stars", [])
    if len(stars) != 3:
        errs.append(f"{where}: stars needs exactly 3 cards")
    for s in stars:
        if s.get("uid") not in uids:
            errs.append(f"{where}: star {s.get('uid')} is not a card in v{p.get('v')}")
        limit(where, f"star {s.get('uid')} why", s.get("why"), 12)
    for name, vocab in (("roles", ROLES), ("card_short", None)):
        d = p.get(name, {})
        if set(d) != uids:
            errs.append(f"{where}: {name} must have exactly one entry per card; missing {sorted(uids - set(d))}, extra {sorted(set(d) - uids)}")
        for uid, val in d.items():
            if vocab and val not in vocab:
                errs.append(f"{where}: role of {uid} is {val!r}, not one of {sorted(vocab)}")
            if not vocab:
                limit(where, f"card_short {uid}", val, 10)
    for name, most, n in (("builds", 3, 12), ("liked", 2, 14), ("worries", 2, 14), ("changed", 3, 14)):
        items = p.get(name)
        if not isinstance(items, list) or len(items) > most:
            errs.append(f"{where}: {name} must be a list of at most {most}")
            continue
        for i, x in enumerate(items):
            limit(where, f"{name}[{i}]", x.get("line") if name == "builds" and isinstance(x, dict) else x, n)
            if name == "builds" and not (isinstance(x, dict) and x.get("name")):
                errs.append(f"{where}: builds[{i}] needs a name")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    run_dir = Path(sys.argv[1])
    ids = sys.argv[2:] or sorted(p.parent.name for p in (run_dir / "designs").glob("*/pitch.json"))
    for did in ids:
        check(run_dir, did)
    for e in errs:
        print(e)
    print(f"{len(ids)} pitch(es) checked, {len(errs)} problem(s)")
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
