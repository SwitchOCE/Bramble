# Missed Cluricaun tier-ups: how many slots were missing a Ring (by row), at the combat before the tier-up.
import pickle, os, collections, statistics as st
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
def onboard(v, card): return any(u[0] == card and u[5] == "board" for u in v["units"])
for line in ["line_fairies_ring", "line_fairies_court"]:
    miss = collections.Counter(); rows = collections.Counter(); per_seat = collections.Counter(); near = 0; tot = 0
    annis_back_only = 0
    for (sd, se, r), v in S.items():
        if v["line"] != line: continue
        p = S.get((sd, se, r - 1))
        if not p or v["tier"] <= p["tier"] or not (onboard(p, "cluricaun") and onboard(v, "cluricaun")): continue
        if (v["ring_size"] or 1) > (p["ring_size"] or 1): continue
        tot += 1
        m = [s for s in range(7) if v["rings"][s] == 0]   # still missing at the combat after (upper bound on what was missing)
        miss[len(m)] += 1
        f = sum(1 for s in m if s < 4); b = len(m) - f
        rows[(f, b)] += 1
        if len(m) <= 2: near += 1
        if f == 0 and b > 0 and onboard(p, "old_moth_annis"): annis_back_only += 1
        per_seat[(sd, se)] += 1
    print("==", line, "flat Cluricaun tier-ups:", tot, " missing slots after the tier-up turn:", sorted(miss.items()))
    print("   (front missing, back missing):", sorted(rows.items(), key=lambda kv: -kv[1])[:10])
    print("   missing <=2 slots:", near, f"({round(100*near/tot)}%)", " only back-row gaps with Annis on board:", annis_back_only)
