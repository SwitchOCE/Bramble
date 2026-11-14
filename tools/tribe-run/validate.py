#!/usr/bin/env python3
"""Check the tribe-run data against docs/design/tribe-run/data-format.md.

Usage: validate.py RUN_DIR [DESIGN_ID ...]
With no design ids, checks every design. Exit 1 and print each problem if any.
"""
import json, re, sys
from pathlib import Path

KEBAB = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
STATUS = {"drafting", "reviewing", "revising", "settled", "capped", "failed"}
CHANGE_KINDS = {"changed", "added", "removed", "renamed", "retiered"}
FLAG_KINDS = {"broken", "watch", "unclear"}
errs = []
warns = []


def err(where, msg):
    errs.append(f"{where}: {msg}")


def load(p):
    try:
        return json.loads(Path(p).read_text())
    except Exception as e:  # noqa: BLE001
        err(p, f"cannot read JSON ({e})")
        return None


def norm(s):
    return re.sub(r"\s+", " ", re.sub(r"[*_`\\]", "", str(s))).strip().lower()


def check_version(d, path, shape, prev, reviews_prev):
    if d is None:
        return
    for k in ("identity", "units", "extras", "builds", "risks", "tier_check", "rationale", "changes", "declined"):
        if k not in d:
            err(path, f"missing '{k}'")
    units = d.get("units", [])
    uids = [u.get("uid") for u in units] + [x.get("uid") for x in d.get("extras", [])]
    if len(uids) != len(set(uids)):
        err(path, "duplicate uid")
    counts = {}
    for u in units:
        for k in ("uid", "name", "tier", "attack", "health", "text", "golden"):
            if k not in u:
                err(path, f"unit {u.get('uid')} missing '{k}'")
        if not re.match(r"^u\d{2,}$", str(u.get("uid", ""))):
            err(path, f"bad unit uid {u.get('uid')}")
        counts[str(u.get("tier"))] = counts.get(str(u.get("tier")), 0) + 1
    if counts != {k: v for k, v in shape.items()}:
        warns.append(f"{path}: tier shape {counts} differs from {shape} (shown in the portal; not an error)")
    if prev is None:
        if d.get("changes"):
            err(path, "v1 must have no changes")
        return
    pu = {u["uid"]: u for u in prev.get("units", []) + prev.get("extras", []) if "uid" in u}
    cu = {u["uid"]: u for u in units + d.get("extras", []) if "uid" in u}
    changed = {c.get("uid") for c in d.get("changes", [])}
    if d.get("identity") != prev.get("identity") and "identity" not in changed:
        err(path, "identity (mechanic, keywords or how it plays) changed with no change entry uid 'identity'")
    for c in d.get("changes", []):
        if c.get("uid") != "identity" and c.get("kind") not in CHANGE_KINDS:
            err(path, f"change {c.get('uid')} bad kind {c.get('kind')}")
        for k in ("what", "why", "from"):
            if not c.get(k):
                err(path, f"change {c.get('uid')} missing '{k}'")
    for uid in set(pu) | set(cu):
        if uid in pu and uid in cu:
            a = {k: pu[uid].get(k) for k in ("name", "tier", "attack", "health", "text", "golden")}
            b = {k: cu[uid].get(k) for k in ("name", "tier", "attack", "health", "text", "golden")}
            if a != b and uid not in changed:
                err(path, f"{uid} differs from the previous version but has no change entry")
        elif uid not in changed:
            err(path, f"{uid} {'removed' if uid in pu else 'added'} with no change entry")
    for uid in cu:
        if uid not in pu and prev is not None:
            n = int(re.sub(r"\D", "", uid) or 0)
            used = [int(re.sub(r"\D", "", u) or 0) for u in pu if u[0] == uid[0]]
            if used and n <= max(used):
                err(path, f"new card {uid} reuses an old number")
    covered = {f for c in d.get("changes", []) for f in c.get("from", [])} | {x.get("point") for x in d.get("declined", [])}
    for r in reviews_prev:
        for p in r.get("points", []):
            if p.get("kind") == "fix" and f"{r['id']}#{p['pid']}" not in covered:
                err(path, f"fix point {r['id']}#{p['pid']} neither applied nor declined")


def check_review(r, path, uids):
    if r is None:
        return
    for k in ("id", "design_id", "v", "member", "ratings", "ratings_why", "verdict", "points", "standouts", "weakest", "flags"):
        if k not in r:
            err(path, f"missing '{k}'")
    for c, val in r.get("ratings", {}).items():
        if not isinstance(val, int) or not 1 <= val <= 10:
            err(path, f"rating {c}={val} not a whole number 1-10")
    if r.get("verdict") not in ("settle", "iterate"):
        err(path, "verdict must be settle or iterate")
    if len(r.get("points", [])) > 5 or len(r.get("standouts", [])) > 3 or len(r.get("weakest", [])) > 3:
        err(path, "too many points, standouts or weakest")
    for group in ("points", "standouts", "weakest", "flags"):
        for x in r.get(group, []):
            if x.get("uid") is not None and x.get("uid") not in uids:
                err(path, f"{group} names unknown uid {x.get('uid')}")
    for f in r.get("flags", []):
        if f.get("kind") not in FLAG_KINDS:
            err(path, f"flag kind {f.get('kind')}")


def check_design(run_dir, did, run):
    ddir = run_dir / "designs" / did
    idx = load(ddir / "design.json")
    if idx is None:
        return
    if idx.get("status") not in STATUS:
        err(ddir, f"bad status {idx.get('status')}")
    seed, _, route = did.partition("--")
    if idx.get("seed") != seed or idx.get("route") != route:
        err(ddir, "seed/route don't match the folder name")
    if route not in {r["id"] for r in run.get("routes", [])}:
        err(ddir, f"unknown route {route}")
    prev, prev_reviews = None, []
    vs = idx.get("versions", [])
    if idx.get("status") == "settled" and len(vs) < run.get("min_versions", 1):
        err(ddir, "settled before min_versions")
    if len(vs) > run.get("max_versions", 3):
        err(ddir, "more versions than max_versions")
    for i, ver in enumerate(vs, 1):
        if ver.get("v") != i:
            err(ddir, f"versions out of order at {i}")
        vp = ddir / f"v{i}.json"
        if i == 1 and not (ddir / "v1.md").exists():
            err(ddir, "v1.md missing")
        d = load(vp) if vp.exists() else (err(ddir, f"v{i}.json missing") or None)
        if i == 1 and d and (ddir / "v1.md").exists():
            md = norm((ddir / "v1.md").read_text())
            for u in d.get("units", []) + d.get("extras", []):
                for k in ("name", "text"):
                    if u.get(k) and norm(u[k]) not in md:
                        err(vp, f"{u.get('uid')} {k} is not copied word for word from v1.md")
        check_version(d, vp, run["shape"], prev, prev_reviews)
        uids = {u.get("uid") for u in (d or {}).get("units", []) + (d or {}).get("extras", [])}
        reviews = []
        for rid in ver.get("reviews", []):
            rp = ddir / "reviews" / f"{rid}.json"
            r = load(rp) if rp.exists() else (err(ddir, f"review {rid} missing") or None)
            check_review(r, rp, uids)
            if r:
                reviews.append(r)
        prev, prev_reviews = d, reviews
    if idx.get("status") in ("settled", "capped") and idx.get("final_version") != len(vs):
        err(ddir, "final_version should be the last version")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    run_dir = Path(sys.argv[1])
    run = load(run_dir / "run.json") or {}
    if "shape" not in run:
        err(run_dir, "run.json has no shape")
        run["shape"] = {}
    ids = sys.argv[2:] or sorted(p.name for p in (run_dir / "designs").glob("*") if p.is_dir())
    for did in ids:
        if not all(KEBAB.match(x) for x in did.split("--")):
            err(did, "id is not kebab seed--route")
        check_design(run_dir, did, run)
    for w in warns:
        print("warning:", w)
    for e in errs:
        print(e)
    print(f"{len(ids)} design(s) checked, {len(errs)} problem(s), {len(warns)} warning(s)")
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
