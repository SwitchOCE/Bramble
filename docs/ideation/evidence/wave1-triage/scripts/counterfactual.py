"""Static counterfactuals: does a floor lever or a ceiling dial lift the typical game, and what does each do to the spread?

Static means: re-price the captured R12/R14 boards; no re-simulation of fights, survival or extra gold. Direction only.
"""
import os, pickle
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
D = pickle.load(open(os.path.join(HERE, "boards.pkl"), "rb"))
rows = D["rows"]
idx = {(r["seed"], r["seat"], r["round"]): r for r in rows}
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run"
PAPER = {12: {"line_birds_homecoming": 615, "line_birds_tempo": 361, "line_fairies_ring": 530, "line_fairies_court": 945},
         14: {"line_birds_homecoming": 1275, "line_birds_tempo": 894, "line_fairies_ring": 1410, "line_fairies_court": 1325}}

# Need per-slot ring counts and which slots are occupied: reload just fairy records with slots.
import glob, gzip, json
ring_detail = {}
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.boards.json.gz"))):
    for r in json.load(gzip.open(f)):
        if r["line"] in ("line_fairies_ring", "line_fairies_court") and r["round"] in (12, 14):
            occ = {u["slot"] for u in r["units"] if u["location"] == "board" and "slot" in u}
            counts = []
            for i, s in enumerate(r.get("slots") or []):
                c = sum(m.get("count", 0) for m in s if m.get("name") == "Ring")
                counts.append((i, c, i in occ))
            ring_detail[(r["seed"], r["seat"], r["round"])] = counts


def summ(v, P, m0):
    v = np.asarray(v, float)
    m = np.median(v)
    return f"median {m:6.0f} ({m/P:.2f}x paper, {m/m0:.2f}x now)  p10 {np.quantile(v,.1):6.0f} p90 {np.quantile(v,.9):6.0f}  p90/p50 {np.quantile(v,.9)/m:.2f}  p10/p50 {np.quantile(v,.1)/m:.2f}  >=2x own median {np.mean(v>=2*m)*100:4.1f}%"


for rnd in (12, 14):
    for line in ("line_fairies_ring", "line_fairies_court"):
        rs = [r for r in rows if r["line"] == line and r["round"] == rnd]
        P = PAPER[rnd][line]
        base, occ_rings, size = [], [], []
        for r in rs:
            det = ring_detail[(r["seed"], r["seat"], rnd)]
            oc = sum(c for i, c, o in det if o)
            s = r["ring_size"] or 1
            ring_stats = 2 * s * oc  # attack+health from Rings on occupied slots
            base.append(r["stats"] - ring_stats); occ_rings.append(oc); size.append(s)
        base = np.array(base, float); oc = np.array(occ_rings, float); s = np.array(size, float)
        now = base + 2 * s * oc
        m0 = np.median(now)
        print(f"\n### {line} R{rnd} n={len(rs)} (paper {P})")
        print(f"  ring stats share of board: median {np.median(2*s*oc/now)*100:.0f}%; non-ring stats median {np.median(base):.0f}; occupied-slot Rings median {np.median(oc):.0f}; Ring size median {np.median(s):.0f}")
        print(f"  now                         : {summ(now, P, m0)}")
        # ceiling dials: growth above the starting size scaled up (only games whose growers fired gain)
        for k in (1.5, 2.0, 3.0):
            v = base + 2 * (1 + k * (s - 1)) * oc
            print(f"  ceiling: Ring growth x{k:<4}    : {summ(v, P, m0)}")
        # floor levers: everyone's size +1 or +2 (starting Ring size), or everyone reaches at least size N
        for add in (1, 2, 3):
            v = base + 2 * (s + add) * oc
            print(f"  floor: starting size +{add}       : {summ(v, P, m0)}")
        for N in (4, 6):
            v = base + 2 * np.maximum(s, N) * oc
            print(f"  floor: every game size >= {N}   : {summ(v, P, m0)}")
        # Ring count floor: everyone at least the paper-ish count on occupied slots (scale count to p75)
        p75 = np.quantile(oc, .75)
        v = base + 2 * s * np.maximum(oc, p75)
        print(f"  floor: Rings >= p75 ({p75:.0f})      : {summ(v, P, m0)}")

# Birds: link of R12 stats to cumulative homecomings R8..R12 (engine throughput)
for rnd in (12, 14):
    for line in ("line_birds_homecoming", "line_birds_tempo"):
        rs = [r for r in rows if r["line"] == line and r["round"] == rnd]
        P = PAPER[rnd][line]
        v = np.array([r["stats"] for r in rs], float)
        cum = np.array([sum((idx.get((r["seed"], r["seat"], k)) or {}).get("homecomings") or 0 for k in range(8, rnd + 1)) for r in rs])
        m = np.median(v)
        print(f"\n### {line} R{rnd}: cumulative homecomings R8..R{rnd}: p10/50/90 {np.quantile(cum,[.1,.5,.9]).tolist()} (paper R8..R{rnd}: {'10' if rnd==12 else '15'} on homecoming line)")
        a = np.argsort(np.argsort(v)); b = np.argsort(np.argsort(cum))
        print(f"  spearman(stats, cumulative homecomings) = {np.corrcoef(a,b)[0,1]:.3f}")
        for lo, hi in ((0, 2), (3, 4), (5, 6), (7, 8), (9, 11), (12, 99)):
            sel = (cum >= lo) & (cum <= hi)
            if sel.sum() >= 5:
                print(f"  {lo:2d}-{hi:2d} homecomings: n={sel.sum():4d} ({sel.mean()*100:4.1f}%) median {np.median(v[sel]):6.0f} ({np.median(v[sel])/P:.2f}x paper)  >=2x line median {np.mean(v[sel]>=2*m)*100:5.1f}%")
        mu = np.array([r["max_unit"] for r in rs], float)
        print(f"  biggest unit share median {np.median(mu/v)*100:.0f}%; boards >=2x median: biggest unit share median {np.median((mu/v)[v>=2*m])*100:.0f}%")
