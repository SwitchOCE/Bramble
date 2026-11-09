"""Ring size and Ring count at R12 for Fairy seats with and without the engine core. Reuses condstats.py parsing."""
import sys, statistics, runpy, os, io, contextlib, gzip, json, glob
RUN = sys.argv[1]
with contextlib.redirect_stdout(io.StringIO()):
    g = runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), "condstats.py"))
labels, own = g["labels"], g["own"]
b12 = {}
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.boards.json.gz"))):
    for b in json.load(gzip.open(f)):
        if b["round"] == 12:
            b12[(b["seed"], b["seat"])] = b
k0 = next(iter(b12.values()))
print("slots sample:", json.dumps(k0.get("slots"))[:300])
def rings(b):
    s = b.get("slots") or []
    tot = 0
    for x in s:
        for r in (x or []):
            if isinstance(r, dict) and r.get("name") == "Ring":
                tot += r.get("count", 0) or 0
    return tot
for line in ("line_fairies_ring", "line_fairies_court"):
    seats = [k for k, v in labels.items() if v == line and k in b12]
    for name, need in [("annis<=R6 & clur<=R9", [("old_moth_annis", 6), ("cluricaun", 9)]), ("annis<=R6", [("old_moth_annis", 6)]), ("clur<=R9", [("cluricaun", 9)])]:
        yes = [k for k in seats if all(own[k].get(c, 99) <= r for c, r in need)]
        no = [k for k in seats if k not in set(yes)]
        f = lambda ks, fn: statistics.median(fn(b12[k]) for k in ks) if ks else None
        print(line, name, "n", len(yes), "ring size", f(yes, lambda b: b.get("ring_size") or 0), "vs", f(no, lambda b: b.get("ring_size") or 0), "| size>=3", round(sum((b12[k].get("ring_size") or 0)>=3 for k in yes)/max(1,len(yes)),2), "vs", round(sum((b12[k].get("ring_size") or 0)>=3 for k in no)/max(1,len(no)),2),
              "| rings", f(yes, rings), "vs", f(no, rings))
