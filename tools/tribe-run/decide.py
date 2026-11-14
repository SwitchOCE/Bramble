#!/usr/bin/env python3
"""Work out each design's next step from the files present, and record votes and ratings.

Usage: decide.py RUN_DIR [DESIGN_ID ...] [--write]
Prints one JSON line per design: {"design", "next", "v", "missing"}.
next is one of: design, extract, review, revise, settled, capped, failed.
With --write, rebuilds design.json's versions, ratings, votes and status from the files.
Statuses come only from files, so a run stopped by a usage limit resumes cleanly:
a missing file means that step still has to run, never that it failed.
"""
import json, sys
from pathlib import Path


def mean(xs):
    return round(sum(xs) / len(xs), 1) if xs else None


def decide(run_dir, did, run, write):
    ddir = run_dir / "designs" / did
    seed, _, route = did.partition("--")
    idxp = ddir / "design.json"
    idx = json.loads(idxp.read_text()) if idxp.exists() else {"id": did, "seed": seed, "route": route}
    members = [m["id"] for m in run["committee"]]
    lo, hi = run.get("min_versions", 1), run.get("max_versions", 3)
    out = {"design": did, "next": None, "v": None, "missing": []}
    if idx.get("status") == "failed":
        out["next"] = "failed"
        return out
    if not (ddir / "v1.md").exists():
        out.update(next="design", v=1)
        return out
    if not (ddir / "v1.json").exists():
        out.update(next="extract", v=1)
        return out
    n = 1
    while (ddir / f"v{n + 1}.json").exists():
        n += 1
    old = {v.get("v"): v for v in idx.get("versions", [])}
    versions = []
    for v in range(1, n + 1):
        revs = [json.loads(p.read_text()) for m in members if (p := ddir / "reviews" / f"v{v}--{m}.json").exists()]
        entry = dict(old.get(v, {}), v=v, author="designer" if v == 1 else "reviser",
                     reviews=[r["id"] for r in revs],
                     ratings={c["id"]: mean([r["ratings"][c["id"]] for r in revs if c["id"] in r.get("ratings", {})]) for c in run["criteria"]},
                     votes={"settle": sum(r.get("verdict") == "settle" for r in revs), "iterate": sum(r.get("verdict") == "iterate" for r in revs)})
        try:
            vj = json.loads((ddir / f"v{v}.json").read_text())
            idx["tribe_name"] = vj.get("identity", {}).get("tribe_name") or idx.get("tribe_name")
        except ValueError:
            pass
        versions.append(entry)
    idx["versions"] = versions
    have = {r.split("--", 1)[1] for r in versions[-1]["reviews"]}
    missing = [m for m in members if m not in have]
    votes = versions[-1]["votes"]
    if missing:
        out.update(next="review", v=n, missing=missing)
        idx["status"] = "reviewing"
    elif n >= hi:
        out.update(next="capped", v=n)
        idx.update(status="capped", final_version=n, stop_reason=f"reached v{hi}, the most allowed")
    elif n >= lo and votes["settle"] >= 2:
        out.update(next="settled", v=n)
        idx.update(status="settled", final_version=n, stop_reason=f"{votes['settle']} of {len(members)} reviewers said it's in a good spot")
    else:
        out.update(next="revise", v=n + 1)
        idx["status"] = "revising"
    if write:
        idxp.write_text(json.dumps(idx, indent=1, ensure_ascii=False) + "\n")
    return out


def main():
    args = [a for a in sys.argv[1:] if a != "--write"]
    if not args:
        print(__doc__)
        sys.exit(2)
    run_dir = Path(args[0])
    run = json.loads((run_dir / "run.json").read_text())
    ids = args[1:] or sorted(p.name for p in (run_dir / "designs").glob("*") if p.is_dir())
    for did in ids:
        print(json.dumps(decide(run_dir, did, run, "--write" in sys.argv)))


if __name__ == "__main__":
    main()
