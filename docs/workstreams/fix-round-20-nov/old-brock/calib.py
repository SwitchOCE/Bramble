"""Check the check: the same head-to-head method on known effects (bramble-design Costing)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fights
from fights import P, X, run, fill, pair_cases

def vu(v):
    kind, m = v
    if kind.startswith("kw:"):
        u = {"def": "plain-brock", "grants": [[kind[3:]]]}
        return u
    return orig(v)
orig = fights.variant_unit
fights.variant_unit = vu

SEEDS = [1000 + 7919 * i for i in range(50)]
MULTS = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0]
def crossing(curve):
    prev=None
    for m,s in curve:
        if s>=0.5:
            if prev is None: return m
            pm,ps=prev; return pm+(m-pm)*(0.5-ps)/(s-ps) if s!=ps else m
        prev=(m,s)
    return float('inf')
boards = {
  "full mid board, X in front (F2)": [P(6,12), X, P(6,12), P(6,12)] + [P(5,10)]*3,
  "full mid board, X in back (B1)": [P(6,12)]*4 + [X] + [P(5,10)]*2,
  "duo: 6/12 + X, X in front": [P(6,12), X, None, None, None, None, None],
}
out = {}
for bname, b in boards.items():
    for eff in ["brock", "kw:cleave", "kw:badger_lance", "kw:taunt", "kw:badger_overrun"]:
        mine = fill(b, (eff, 1))
        curve = []
        err = 0
        for m in MULTS:
            s, n, e = run(pair_cases(mine, fill(b, ("plain", m)), SEEDS), "cal")
            err += e
            curve.append((m, 1 - s))
        ev = crossing(curve)
        out[f"{bname} | {eff}"] = {"even": ev, "curve": curve, "errors": err, "n": n}
        print(f"{bname:34s} {eff:18s} even x{ev:.2f}  err={err}  " + " ".join(f"{m:g}:{s:.0%}" for m, s in curve), flush=True)
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "calibration_results.json"), "w"), indent=1, default=str)
