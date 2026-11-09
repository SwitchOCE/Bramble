"""R12 Ring size and stats for Fairy seats by early Lob/Silky/Monarch ownership. Reuses condstats.py parsing."""
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
for line in ("line_fairies_ring", "line_fairies_court"):
    seats = [k for k, v in labels.items() if v == line and k in b12]
    print(line, "all: S median", statistics.median(b12[k].get("ring_size") or 0 for k in seats), "S dist", sorted(__import__('collections').Counter(b12[k].get("ring_size") or 0 for k in seats).items()))
    for name, need in [("lob<=R7 & silky<=R10", [("lob_lie_by_the_fire", 7), ("silky", 10)]),
                       ("lob<=R9", [("lob_lie_by_the_fire", 9)]), ("silky<=R10", [("silky", 10)]),
                       ("monarch<=R10", [("fairy_monarch", 10)])]:
        yes = [k for k in seats if all(own[k].get(c, 99) <= r for c, r in need)]
        no = [k for k in seats if k not in set(yes)]
        S = lambda ks: statistics.median(b12[k].get("ring_size") or 0 for k in ks) if ks else None
        M = lambda ks: statistics.median(b12[k]["stats"] for k in ks) if ks else None
        print(f"  {name:24s} n={len(yes):3d} ({len(yes)/len(seats)*100:4.1f}%)  S {S(yes)} vs {S(no)}  mean S {statistics.mean(b12[k].get('ring_size') or 0 for k in yes) if yes else 0:.2f} vs {statistics.mean(b12[k].get('ring_size') or 0 for k in no):.2f}  stats {M(yes)} vs {M(no)}")
