"""Which paper assumption carries the gap, at design dials (repo models, accounting parameters).

Fairies: guaranteed units + realistic spells/thanks/Nans ('spells'), single-piece knockouts on the
authored plan, and how often the authored arrival schedule happens on time under shop luck.
Birds: single-piece knockouts on line A/U, and on-time probability of the authored arrivals.
Also each paper line's R12 board as a percentile of the real R12 distribution.
"""
import json, os, random, statistics as st, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.environ.setdefault("TAG", "design")
import a4_fairies_rerun as F
import a3_birds_rerun as Bm
import a2_shopluck as sl

D = json.load(open(os.path.join(HERE, "seats.json")))
B, E = D["boards"], D["econ"]


def pct_rank(x, v):
    return sum(1 for y in v if y >= x) / len(v)


print("=== Paper R12 board against the real R12 distribution (share of real survivors at or above it)")
paper12 = {"line_birds_homecoming": 615, "line_birds_tempo": 361, "line_fairies_ring": 530, "line_fairies_court": 945}
for line, p in paper12.items():
    v = [rs["12"]["stats"] for rs in B[line].values() if "12" in rs]
    print("  %-22s paper %4d  real median %4.0f  real p90 %4.0f  real max %5d  share >= paper %.1f%%  (of all 640 seats: %.1f%%)" % (
        line, p, st.median(v), sorted(v)[int(.9 * len(v))], max(v), 100 * pct_rank(p, v), 100 * sum(1 for y in v if y >= p) / 640))

rng = random.Random(9)
print("\n=== Fairies: which assumption (R12 pre-start medians over the real seats' shop histories)")
for line, kind in (("line_fairies_ring", "ring"), ("line_fairies_court", "court")):
    plan = F.m.ring_plan("typ") if kind == "ring" else F.m.court_plan("typ")
    paper = F.play(plan)
    occ = {r: paper[r]["occ"] for r in paper}
    first = F.plan_round_of(plan)
    spells_only = []
    for skey, rs in B[line].items():
        if "12" not in rs:
            continue
        offers = F.offers_for(E[line][skey], rng)
        o = F.play(plan, arr=dict(first), offers=offers, occupied=occ)
        spells_only.append(o[12]["rec"])
    print("  %s: paper %d | units guaranteed, spells/thanks/Nans from shop luck: %.0f (%.2fx)" % (
        line, paper[12]["rec"], st.median(spells_only), st.median(spells_only) / paper[12]["rec"]))
    base = F.play(plan, arr=dict(first), offers=None, occupied=occ)[12]["rec"]
    print("    knockouts (that piece never arrives, the rest on time, spells as planned, T6 at 13): base %d; R12 board, x of base" % base)
    for nm in sorted(first, key=lambda k: first[k]):
        arr = dict(first); arr[nm] = 99
        o = F.play(plan, arr=arr, offers=None, occupied=occ)
        print("      %-10s (plan R%-2d) %5d  %.2f   S %g Rings %d" % (nm, first[nm], o[12]["rec"], o[12]["rec"] / base, o[12]["S"], o[12]["rings"]))
    # on-time probability of the whole schedule (each piece offered by its plan round + 1), shop luck
    ok = 0; n = 0; each = {nm: 0 for nm in first}
    for _ in range(3):
        for skey, h in E[line].items():
            arr = F.shop_arrivals(h, rng); n += 1
            hit = {nm: arr.get(nm, 99) <= first[nm] + 1 for nm in first}
            ok += all(hit.values())
            for nm in first:
                each[nm] += hit[nm]
    print("    on time (offered by plan round + 1) under shop luck: all %d pieces %.2f%%; each: %s" % (
        len(first), 100 * ok / n, ", ".join("%s %.0f%%" % (k, 100 * v / n) for k, v in each.items())))

print("\n=== Birds: knockouts on the authored line (design dials, paper climb), R12 board")
for line, key in (("line_birds_homecoming", "A"), ("line_birds_tempo", "U")):
    L0 = Bm.m.LINES[key]
    base = Bm.run_line(dict(L0), fill=True)
    print("  %s (line %s) paper+fill R12 %d" % (line, key, base[12]))
    for card in sorted(L0["arrive"], key=lambda c: L0["arrive"][c]):
        arr = dict(L0["arrive"]); arr.pop(card)
        o = Bm.run_line(dict(L0, arrive=arr), fill=True)
        print("      %-10s (plan R%-2d) %5d  %.2f" % (card, L0["arrive"][card], o[12], o[12] / base[12]))
    ok = 0; n = 0; each = {c: 0 for c in L0["arrive"]}
    for _ in range(3):
        for skey, h in E[line].items():
            arr, _s = Bm.shop_arrivals(L0, h, rng); n += 1
            hit = {c: arr.get(c, 99) <= L0["arrive"][c] + 1 for c in L0["arrive"]}
            ok += all(hit.values())
            for c in hit:
                each[c] += hit[c]
    print("    on time (offered by plan round + 1): all %d pieces %.2f%%; each: %s" % (
        len(each), 100 * ok / n, ", ".join("%s %.0f%%" % (k, 100 * v / n) for k, v in each.items())))
