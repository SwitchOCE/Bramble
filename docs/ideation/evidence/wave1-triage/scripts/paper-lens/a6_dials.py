"""Realized elasticity of the preset dials, and dial sets that would reach re-based targets.

Uses the presets' own scratch models (scratchpad/presets/birds-presets-model.py and
presets/fairies/model.py, built Cluricaun timing), replayed with realistic arrivals as in a3/a4
(shop-luck arrivals + shop-luck spells; and captured arrivals). Predicted real = measured real at
design dials x (realized at the dial set / realized at design), per line and round.
"""
import json, os, random, statistics as st, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PR = "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/presets"
os.environ["BIRDS_MODEL"] = PR + "/birds-presets-model.py"
os.environ["BIRDS_ARGS"] = "preset=design"
os.environ["FAIRY_MODEL"] = PR + "/fairies/model.py"
os.environ["TAG"] = "a6"
sys.path.insert(0, HERE)
import a3_birds_rerun as Bm
import a4_fairies_rerun as F

D = json.load(open(os.path.join(HERE, "seats.json")))
B, E = D["boards"], D["econ"]
ROUNDS = (8, 10, 12, 14)
REAL = {l: {t: st.median([rs[str(t)]["stats"] for rs in B[l].values() if str(t) in rs]) for t in ROUNDS} for l in B}

BIRD_DESIGN = dict(Bm.m.P)


def birds(over, seed=5):
    Bm.m.P.clear(); Bm.m.P.update(BIRD_DESIGN); Bm.m.P.update(over)
    rng = random.Random(seed)
    res = {}
    for line, key in (("line_birds_homecoming", "A"), ("line_birds_tempo", "U")):
        L0 = Bm.m.LINES[key]
        paper = Bm.run_line(dict(L0), fill=False)
        v = {t: [] for t in ROUNDS}
        for skey, rs in B[line].items():
            h = E[line][skey]
            arr, sup = Bm.shop_arrivals(L0, h, rng)
            o = Bm.run_line(dict(L0, climb=Bm.seat_climb(h), arrive=arr, supper=sup), cost=Bm.SLICE_COST)
            for t in ROUNDS:
                if str(t) in rs:
                    v[t].append(o[t])
        res[line] = dict(paper={t: paper[t] for t in ROUNDS}, real={t: st.median(v[t]) for t in ROUNDS})
    return res


def fairies(over, seed=3):
    F.OVER.clear(); F.OVER.update(over)
    rng = random.Random(seed)
    res = {}
    for line, kind in (("line_fairies_ring", "ring"), ("line_fairies_court", "court")):
        plan = F.m.ring_plan("typ") if kind == "ring" else F.m.court_plan("typ")
        paper = F.play(plan)
        occ = {r: paper[r]["occ"] for r in paper}
        v = {t: [] for t in ROUNDS}; s = {t: [] for t in ROUNDS}
        for skey, rs in B[line].items():
            h = E[line][skey]
            offers = F.offers_for(h, rng)
            o = F.play(plan, arr=F.shop_arrivals(h, rng), offers=offers, occupied=occ)
            for t in ROUNDS:
                if str(t) in rs:
                    v[t].append(o[t]["rec"]); s[t].append(o[t]["S"])
        res[line] = dict(paper={t: paper[t]["rec"] for t in ROUNDS}, real={t: st.median(v[t]) for t in ROUNDS},
                         S={t: st.median(s[t]) for t in ROUNDS})
    return res


def show(tag, res, base):
    out = {}
    for line, r in res.items():
        pred = {t: REAL[line][t] * r["real"][t] / base[line]["real"][t] for t in ROUNDS}
        g = (pred[14] / pred[8]) ** (1 / 6)
        out[line] = pred
        print("  %-14s %-22s paper R12 %5.0f | realized R8/10/12/14 %s | predicted real %s | growth x%.2f%s" % (
            tag, line, r["paper"][12], "/".join("%.0f" % r["real"][t] for t in ROUNDS),
            "/".join("%.0f" % pred[t] for t in ROUNDS), g,
            (" | S@12 %.1f" % r["S"][12]) if "S" in r else ""))
    return out


if __name__ == "__main__":
    allout = {}
    print("=== Birds (presets model; predicted real = measured real x realized ratio to design)")
    bd = birds({})
    sets = [("design", {}),
            ("B", {"h": 2.25, "hg": 3.0, "k": 0.125, "chiff": 3, "s": 1 / 6}),
            ("C", {"h": 2.5, "hg": 3.0, "k": 0.15, "eggm": 3.0, "chiff": 4, "s": 1 / 6, "g": 5}),
            ("C h2.75", {"h": 2.75, "hg": 3.0, "k": 0.15, "eggm": 3.0, "chiff": 4, "s": 1 / 6, "g": 5}),
            ("C h3", {"h": 3.0, "hg": 3.5, "k": 0.15, "eggm": 3.0, "chiff": 4, "s": 1 / 6, "g": 5}),
            ("B h2.5", {"h": 2.5, "hg": 3.0, "k": 0.125, "chiff": 3, "s": 1 / 6}),
            ("B h3", {"h": 3.0, "hg": 3.5, "k": 0.125, "chiff": 3, "s": 1 / 6})]
    for tag, o in sets:
        allout["birds " + tag] = show(tag, birds(o), bd)
    print("\n=== Fairies (presets model, built Cluricaun timing; Fetch 1/2 as built for design)")
    D0 = {"fairies_fetch_share": 0.5}
    fd = fairies(D0)
    BF = {"fairies_ring_growth": 2, "fairies_lob_turns": 2, "fairies_nan_rings": 2, "fairies_monarch_period": 2}
    CF = {"fairies_ring_growth": 4, "fairies_lob_turns": 2, "fairies_lob_growth": 3, "fairies_silky_growth": 2,
          "fairies_nan_rings": 2, "fairies_monarch_period": 2, "fairies_monarch_multiplier": 3,
          "fairies_golden_monarch_multiplier": 4}
    sets = [("design", D0), ("B", BF), ("C", CF),
            ("s0=2", dict(D0, fairies_initial_ring_size=2.0)),
            ("s0=3", dict(D0, fairies_initial_ring_size=3.0)),
            ("annis2", dict(D0, fairies_annis_rings=2)),
            ("annis2 sally2 nan2", dict(D0, fairies_annis_rings=2, fairies_sally_rings=2, fairies_nan_rings=2)),
            ("B+s0=2", dict(BF, fairies_initial_ring_size=2.0)),
            ("B+s0=3", dict(BF, fairies_initial_ring_size=3.0)),
            ("C+s0=2", dict(CF, fairies_initial_ring_size=2.0)),
            ("B+s0=2+annis2", dict(BF, fairies_initial_ring_size=2.0, fairies_annis_rings=2)),
            ("B+s0=3+annis2+sally2", dict(BF, fairies_initial_ring_size=3.0, fairies_annis_rings=2, fairies_sally_rings=2))]
    for tag, o in sets:
        allout["fairies " + tag] = show(tag, fairies(o), fd)
    json.dump(allout, open(os.path.join(HERE, "a6_dials.json"), "w"), indent=1)
