"""Mixture-median estimate: R12 median if the share of committed seats holding the engine core rose.
Upper bound: seats that hold the core are also selected for luck and gold. Reuses condstats.py's parsing.
Run: python3 -I mix.py <run_dir> <seat_labels.json.gz>
"""
import sys, statistics, runpy, os
sys.argv = [sys.argv[0]] + sys.argv[1:3]
import io, contextlib
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    g = runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), "condstats.py"))
labels, own, stats, CONDS = g["labels"], g["own"], g["stats"], g["CONDS"]
PAPER = {"line_fairies_ring": 530, "line_fairies_court": 945, "line_birds_homecoming": 615, "line_birds_tempo": 361}

def wmedian(yes, no, s):
    pts = [(v, s / len(yes)) for v in yes] + [(v, (1 - s) / len(no)) for v in no]
    pts.sort(); acc = 0
    for v, w in pts:
        acc += w
        if acc >= 0.5:
            return v

for line, conds in CONDS.items():
    seats = [k for k, v in labels.items() if v == line and 12 in stats.get(k, {})]
    print(f"\n{line} (paper {PAPER[line]}, real median {statistics.median(stats[k][12] for k in seats)})")
    for name, need in conds[3:] if 'fairies' in line else conds[3:]:
        yes = [stats[k][12] for k in seats if all(own[k].get(c, 99) <= r for c, r in need)]
        no = [stats[k][12] for k in seats if not all(own[k].get(c, 99) <= r for c, r in need)]
        s0 = len(yes) / len(seats)
        print(f"  {name:42s} n_yes={len(yes):3d} now {s0*100:4.1f}% ->", "  ".join(
            f"{int(s*100)}%: {wmedian(yes, no, s):.0f} ({wmedian(yes, no, s)/PAPER[line]:.2f}x)" for s in (0.2, 0.4, 0.6, 1.0)))
    # pair condition too (index 2 for fairies, 3 for birds)
    for name, need in [conds[2]] if 'fairies' in line else []:
        yes = [stats[k][12] for k in seats if all(own[k].get(c, 99) <= r for c, r in need)]
        no = [stats[k][12] for k in seats if not all(own[k].get(c, 99) <= r for c, r in need)]
        print(f"  {name:42s} n_yes={len(yes):3d} now {len(yes)/len(seats)*100:4.1f}% ->", "  ".join(
            f"{int(s*100)}%: {wmedian(yes, no, s):.0f} ({wmedian(yes, no, s)/PAPER[line]:.2f}x)" for s in (0.2, 0.4, 0.6, 1.0)))
