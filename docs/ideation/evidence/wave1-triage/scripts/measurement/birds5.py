# Homecoming multiplier as realised: a Bird away at the last combat and back on the board now;
# its stats now over its stats when it left (matched by card id; the closest copy to 2x).
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
B = pickle.load(open(os.path.join(D, "birds.pkl"), "rb"))
ratios = collections.defaultdict(list); fate = collections.Counter()
for (sd, se, r), b in B.items():
    bp = B.get((sd, se, r - 1)); v = S.get((sd, se, r))
    if not bp or not v or "birds" not in v["line"]: continue
    now_away = {a[1] for a in b["away"]}
    for a in bp["away"]:
        if a[1] in now_away: continue
        loc = [x[1] for x in v["rec"] if x[3] == a[1]]
        fate[loc[0] if loc else "gone"] += 1
        if loc and loc[0] == "board":
            cands = [u[2] + u[3] for u in v["units"] if u[0] == a[0] and u[5] == "board"]
            if cands:
                left = a[2] + a[3]
                best = min(cands, key=lambda s: abs(s - 2 * left))
                ratios[a[0]].append(best / max(1, left))
print("where a homecoming Bird is at the next combat:", dict(fate))
for c, xs in ratios.items(): print(f"  {c:14s} n={len(xs):5d} stats back / stats at departure: median {st.median(xs):.2f}")
