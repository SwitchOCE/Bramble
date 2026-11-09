"""Fairies: how much of each real board is Ring stats, and what the same boards would read with a
bigger Ring size (starting size +1/+2, or x2), counted on the captured boards themselves.
Ring stat on a slot = ceil(count x size) to Attack and to Health, for occupied non-Shy slots.
"""
import json, math, os, statistics as st

HERE = os.path.dirname(os.path.abspath(__file__))
D = json.load(open(os.path.join(HERE, "seats.json")))
B = D["boards"]
SHY = {"hob_in_the_hearth", "lob_lie_by_the_fire", "silky"}
for line in ("line_fairies_ring", "line_fairies_court"):
    print("=====", line)
    for t in (8, 10, 12, 14):
        rows = []
        for rs in B[line].values():
            x = rs.get(str(t))
            if not x or x["rings"] is None:
                continue
            S = x["S"] or 1.0
            occ = {}
            for u in x["units"]:
                if u["loc"] == "board" and u["slot"] is not None:
                    occ[u["slot"]] = u["id"]
            def ringstats(size):
                return sum(2 * math.ceil(c * size - 1e-9) for s, c in enumerate(x["rings"]) if s in occ and occ[s] not in SHY)
            rs0 = ringstats(S)
            base = x["stats"] - rs0
            rows.append((x["stats"], rs0, base, base + ringstats(S + 1), base + ringstats(S + 2), base + ringstats(2 * S), sum(x["rings"]), S))
        med = lambda i: st.median(r[i] for r in rows)
        share = st.median(r[1] / r[0] for r in rows if r[0])
        print("  R%d n=%d board %.0f | Ring stats %.0f (median share %.0f%%) | +1 size %.0f (x%.2f) | +2 size %.0f (x%.2f) | size x2 %.0f (x%.2f) | Rings %.0f S %.1f" % (
            t, len(rows), med(0), med(1), 100 * share, med(3), med(3) / med(0), med(4), med(4) / med(0), med(5), med(5) / med(0), med(6), med(7)))
