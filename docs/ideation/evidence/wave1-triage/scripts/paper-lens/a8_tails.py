"""Tails at R12 under realistic arrivals (shop luck): p50, p90, p99 and share above 3x the median,
for design, B, C and the 'C h3' Birds set; design/B/C for Fairies. Same machinery as a6."""
import os, sys, random, statistics as st
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import a6_dials as A
Bm, F, B, E = A.Bm, A.F, A.B, A.E
def q(v, p): v = sorted(v); return v[int(p * (len(v) - 1))]
def bird_dist(over, seed=5):
    Bm.m.P.clear(); Bm.m.P.update(A.BIRD_DESIGN); Bm.m.P.update(over); rng = random.Random(seed); out = {}
    for line, key in (("line_birds_homecoming", "A"), ("line_birds_tempo", "U")):
        L0 = Bm.m.LINES[key]; v = []
        for skey, rs in B[line].items():
            h = E[line][skey]; arr, sup = Bm.shop_arrivals(L0, h, rng)
            o = Bm.run_line(dict(L0, climb=Bm.seat_climb(h), arrive=arr, supper=sup), cost=Bm.SLICE_COST)
            if "12" in rs: v.append(o[12])
        out[line] = v
    return out
def fairy_dist(over, seed=3):
    F.OVER.clear(); F.OVER.update(over); rng = random.Random(seed); out = {}
    for line, kind in (("line_fairies_ring", "ring"), ("line_fairies_court", "court")):
        plan = F.m.ring_plan("typ") if kind == "ring" else F.m.court_plan("typ")
        paper = F.play(plan); occ = {r: paper[r]["occ"] for r in paper}; v = []
        for skey, rs in B[line].items():
            h = E[line][skey]; offers = F.offers_for(h, rng)
            o = F.play(plan, arr=F.shop_arrivals(h, rng), offers=offers, occupied=occ)
            if "12" in rs: v.append(o[12]["rec"])
        out[line] = v
    return out
def show(tag, d):
    for line, v in d.items():
        m = st.median(v)
        print("  %-10s %-22s p50 %5.0f p90 %5.0f p99 %6.0f max %6.0f | p90/p50 %.1f | share >3x median %.1f%%" % (
            tag, line, m, q(v, .9), q(v, .99), max(v), q(v, .9) / m, 100 * sum(x > 3 * m for x in v) / len(v)))
for line in B:
    v = [rs["12"]["stats"] for rs in B[line].values() if "12" in rs]; m = st.median(v)
    print("  %-10s %-22s p50 %5.0f p90 %5.0f p99 %6.0f max %6.0f | p90/p50 %.1f | share >3x median %.1f%%" % (
        "REAL", line, m, q(v, .9), q(v, .99), max(v), q(v, .9) / m, 100 * sum(x > 3 * m for x in v) / len(v)))
for tag, o in (("design", {}), ("B", {"h": 2.25, "hg": 3.0, "k": 0.125, "chiff": 3, "s": 1/6}),
               ("C", {"h": 2.5, "hg": 3.0, "k": 0.15, "eggm": 3.0, "chiff": 4, "s": 1/6, "g": 5}),
               ("C h3", {"h": 3.0, "hg": 3.5, "k": 0.15, "eggm": 3.0, "chiff": 4, "s": 1/6, "g": 5})):
    show(tag, bird_dist(o))
BF = {"fairies_ring_growth": 2, "fairies_lob_turns": 2, "fairies_nan_rings": 2, "fairies_monarch_period": 2}
CF = {"fairies_ring_growth": 4, "fairies_lob_turns": 2, "fairies_lob_growth": 3, "fairies_silky_growth": 2,
      "fairies_nan_rings": 2, "fairies_monarch_period": 2, "fairies_monarch_multiplier": 3, "fairies_golden_monarch_multiplier": 4}
for tag, o in (("design", {"fairies_fetch_share": 0.5}), ("B", BF), ("C", CF)):
    show(tag, fairy_dist(o))
