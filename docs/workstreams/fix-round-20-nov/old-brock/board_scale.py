"""The skill's literal method: X's board against the same board with a plain 8/20 in X's slot,
every unit of that other board scaled k x, until even. Brock and known effects (check the check)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fights
from fights import P, R, X, run, fill, pair_cases, scale_unit
orig = fights.variant_unit
def vu(v):
    if v[0].startswith("kw:"):
        return {"def": "plain-brock", "grants": [[v[0][3:]]]}
    return orig(v)
fights.variant_unit = vu
SEEDS = [1000 + 7919 * i for i in range(50)]
KS = [1.0, 1.05, 1.1, 1.15, 1.2, 1.3, 1.4, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0]
def crossing(curve):
    prev=None
    for m,s in curve:
        if s>=0.5:
            if prev is None: return m
            pm,ps=prev; return pm+(m-pm)*(0.5-ps)/(s-ps) if s!=ps else m
        prev=(m,s)
    return float('inf')
def stats(board):
    t=0
    for u in board:
        if u is None: continue
        st=u.get("stats",{})
        c=fights.CARDS[u["def"]]; g=2 if u.get("golden") else 1
        if "set_attack" in st: t+=st["set_attack"]+st["set_health"]
        else: t+=c["attack"]*g+c["health"]*g+st.get("perm_attack",0)+st.get("perm_health",0)
    return t
locust = [R("orchard-stripper", 5), R("brood-mother", 5), R("famine-caller", 5), R("skin-shedder", 5), X, R("gleaner", 5), R("dirge-singer", 5)]
badger = [R("tourney-champion", 5), R("ironhide-berserker", 5), R("the-oakfeller", 5), R("gate-warden", 5), X, R("greatsword-bearer", 5), R("armsbearer", 5)]
boards = {
  "duo: 6/12 front, X behind": ([P(6,12), None, None, None, X, None, None], ["brock"]),
  "half: two 8/16 front, X behind": ([P(8,16), P(8,16), None, None, X, None, None], ["brock"]),
  "full mid, X in back (B1)": ([P(6,12)]*4 + [X] + [P(5,10)]*2, ["brock", "gbrock"]),
  "full mid, X in front (F2)": ([P(6,12), X, P(6,12), P(6,12)] + [P(5,10)]*3, ["brock", "kw:cleave", "kw:badger_lance", "kw:taunt", "kw:badger_overrun"]),
  "swarm 2/3s, X behind": ([P(2,3)]*4 + [X] + [P(2,3)]*2, ["brock"]),
  "late big 20/40s, X behind": ([P(20,40)]*4 + [X] + [P(15,30)]*2, ["brock"]),
  "real Badger board, X in B1": (badger, ["brock"]),
  "real Locust board, X in B1": (locust, ["brock"]),
}
out = {}
for bname, (b, effs) in boards.items():
    for eff in effs:
        gold = eff == "gbrock"
        mine = fill(b, (eff, 1))
        base = fill(b, ("gplain" if gold else "plain", 1.0))
        curve = []
        for k in KS:
            opp = [scale_unit(u, k) for u in base]
            s, n, e = run(pair_cases(mine, opp, SEEDS), "bs")
            curve.append((k, 1 - s))
        ev = crossing(curve)
        tot = stats(base)
        xs = 56 if gold else 28
        extra = (ev - 1) * tot if ev != float('inf') else float('inf')
        out[f"{bname} | {eff}"] = {"even_k": ev, "board_stats": tot, "extra_stats": extra, "x_stats": xs, "curve": curve, "n": n}
        print(f"{bname:30s} {eff:17s} board {tot:4d}  even at board x{ev:.2f} = +{extra:.0f} stats = {(xs+extra)/xs:.1f}x the unit's own {xs}  " + " ".join(f"{k:g}:{s:.0%}" for k, s in curve), flush=True)
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "board_scale_results.json"), "w"), indent=1, default=str)
