#!/usr/bin/env python3
"""Bundle a tribe-run folder into the one-file portal page.

Usage: bundle.py [RUN_DIR] [--out PATH]
RUN_DIR defaults to docs/design/tribe-run/run; PATH to docs/design/tribe-run/portal/index.html.
Reads only the files described in docs/design/tribe-run/data-format.md, embeds them as JSON
in portal/template.html, and prints the size. Works on a run in any partial state: missing or
unreadable files are skipped (and listed), never fatal. Standard library only.
"""
import hashlib, json, re, sys
from datetime import datetime
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TEMPLATE = REPO / "docs/design/tribe-run/portal/template.html"
DEFAULT_RUN = REPO / "docs/design/tribe-run/run"
DEFAULT_OUT = REPO / "docs/design/tribe-run/portal/index.html"
PLACEHOLDER = "__RUN_DATA__"
LIMIT = 16 * 1024 * 1024
problems = []


def load(p):
    try:
        return json.loads(Path(p).read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except Exception as e:  # noqa: BLE001
        problems.append(f"{p}: {e}")
        return None


def mean(xs):
    xs = [x for x in xs if isinstance(x, (int, float))]
    return round(sum(xs) / len(xs), 1) if xs else None


def vnum(name):
    m = re.match(r"^v(\d+)", name)
    return int(m.group(1)) if m else None


def design(ddir, criteria, members):
    did = ddir.name
    seed, _, route = did.partition("--")
    idx = load(ddir / "design.json") or {}
    if not isinstance(idx, dict):
        idx = {}
    old = {v.get("v"): v for v in idx.get("versions", []) if isinstance(v, dict)}
    md_path = ddir / "v1.md"
    md = None
    if md_path.exists():
        try:
            md = md_path.read_text(encoding="utf-8")
        except Exception as e:  # noqa: BLE001
            problems.append(f"{md_path}: {e}")
    # versions present on disk, in order, stopping at the first gap
    n = 0
    while (ddir / f"v{n + 1}.json").exists():
        n += 1
    rev_dir = ddir / "reviews"
    rev_files = sorted(rev_dir.glob("v*--*.json")) if rev_dir.is_dir() else []
    versions = []
    tribe_name = idx.get("tribe_name")
    for v in range(1, n + 1):
        data = load(ddir / f"v{v}.json")
        if isinstance(data, dict):
            tribe_name = (data.get("identity") or {}).get("tribe_name") or tribe_name
        else:
            data = None
        reviews = []
        for p in rev_files:
            if vnum(p.name) != v or p.name.startswith("_"):
                continue
            r = load(p)
            if isinstance(r, dict):
                r.setdefault("id", p.stem)
                r.setdefault("member", p.stem.split("--", 1)[-1])
                reviews.append(r)
        order = {m: i for i, m in enumerate(members)}
        reviews.sort(key=lambda r: (order.get(r.get("member"), 99), str(r.get("member"))))
        o = old.get(v) or {}
        ratings, votes = o.get("ratings"), o.get("votes")
        if not isinstance(ratings, dict):  # decide.py hasn't recorded this version yet
            crit = criteria or sorted({c for r in reviews for c in (r.get("ratings") or {})})
            ratings = {c: mean([(r.get("ratings") or {}).get(c) for r in reviews]) for c in crit}
        if not isinstance(votes, dict):
            votes = {k: sum(r.get("verdict") == k for r in reviews) for k in ("settle", "iterate")}
        versions.append({"v": v, "summary": o.get("summary"), "data": data,
                         "reviews": reviews, "ratings": ratings, "votes": votes})
    # status, final_version and stop_reason are decide.py's (it writes them into design.json).
    # Only the steps before it has a say are read from which files exist.
    status = idx.get("status")
    if status != "failed":
        if n == 0:
            status = "written" if md is not None else "designing"
        elif not versions[-1]["reviews"]:
            status = "unreviewed"
        elif status not in ("reviewing", "revising", "settled", "capped"):
            status = "reviewing"
    done = status in ("settled", "capped", "failed")
    final = idx.get("final_version") if done else None
    stop = idx.get("stop_reason") if done else None
    if not tribe_name and md:  # before extraction, take the name from the write-up's first heading
        m = re.search(r"^#\s+(.+)$", md, re.M)
        tribe_name = re.sub(r"[*_`]", "", m.group(1)).strip() if m else None
    key = f"{seed}-{hashlib.md5(did.encode()).hexdigest()[:4]}"
    return {"id": did, "key": key, "seed": seed, "route": route, "tribe_name": tribe_name,
            "status": status, "final_version": final, "stop_reason": stop,
            "md": md, "versions": versions}


def bundle(run_dir):
    run = load(run_dir / "run.json") or {}
    criteria = [c.get("id") for c in run.get("criteria", []) if isinstance(c, dict) and c.get("id")]
    members = [m.get("id") for m in run.get("committee", []) if isinstance(m, dict) and m.get("id")]
    slim_run = {
        "run_id": run.get("run_id"), "shape": run.get("shape") or {},
        "min_versions": run.get("min_versions", 1), "max_versions": run.get("max_versions", 3),
        "routes": [{"id": r.get("id"), "name": r.get("name")} for r in run.get("routes", []) if isinstance(r, dict)],
        "committee": [{"id": m.get("id"), "name": m.get("name"), "lens": m.get("lens")} for m in run.get("committee", []) if isinstance(m, dict)],
        "criteria": [{"id": c.get("id"), "name": c.get("name")} for c in run.get("criteria", []) if isinstance(c, dict)],
    }
    seeds = []
    sdir = run_dir / "seeds"
    if sdir.is_dir():
        for p in sorted(sdir.glob("*.json")):
            if p.name.startswith("_"):
                continue
            s = load(p)
            if isinstance(s, dict):
                s.setdefault("id", p.stem)
                seeds.append(s)
    designs = []
    ddir = run_dir / "designs"
    if ddir.is_dir():
        for p in sorted(ddir.iterdir()):
            if p.is_dir() and not p.name.startswith(("_", ".")):
                designs.append(design(p, criteria, members))
    known = {s["id"] for s in seeds}
    for d in designs:  # a design whose seed file is missing still gets a seed to sit under
        if d["seed"] not in known:
            known.add(d["seed"])
            seeds.append({"id": d["seed"], "name": d["seed"].replace("-", " ").title(), "pitch": None})
    rankings = {"seeds": {}, "overall": None}
    rdir = run_dir / "rankings"
    if rdir.is_dir():
        for p in sorted(rdir.glob("seed--*.json")):
            r = load(p)
            if isinstance(r, dict):
                rankings["seeds"][r.get("seed") or p.stem.split("--", 1)[1]] = r
        o = load(rdir / "overall.json")
        rankings["overall"] = o if isinstance(o, dict) else None
    return {"built": datetime.now().strftime("%d %b %Y, %H:%M"), "run": slim_run, "seeds": seeds,
            "designs": designs, "rankings": rankings, "problems": problems}


def main():
    args = sys.argv[1:]
    out = DEFAULT_OUT
    if "--out" in args:
        i = args.index("--out")
        if i + 1 >= len(args):
            print(__doc__)
            sys.exit(2)
        out = Path(args[i + 1])
        del args[i:i + 2]
    run_dir = Path(args[0]) if args else DEFAULT_RUN
    data = bundle(run_dir)
    # Inside <script type="application/json">: escape every "<" so no "</script>" or "<!--" can end it early.
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    blob = blob.replace("<", "\\u003c").replace("\u2028", "\\u2028").replace("\u2029", "\\u2029")
    tpl = TEMPLATE.read_text(encoding="utf-8")
    if tpl.count(PLACEHOLDER) != 1:
        sys.exit(f"{TEMPLATE} must contain {PLACEHOLDER} exactly once")
    html = tpl.replace(PLACEHOLDER, blob)
    size = len(html.encode("utf-8"))
    if size > LIMIT:
        sys.exit(f"page is {size / 1e6:.1f} MB, over the 16 MB limit; not written")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html, encoding="utf-8")
    for p in problems:
        print("skipped:", p)
    print(f"{out}: {len(data['designs'])} design(s), {len(data['seeds'])} seed(s), {size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
