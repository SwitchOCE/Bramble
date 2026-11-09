# Flight choice: on a turn a Bird left, was a bigger flier left home that was eligible (on the board at the
# last combat and still on the board now, so it had fought at home)? Stats matched by card id (approximate
# when two copies stand).
import pickle, os, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
B = pickle.load(open(os.path.join(D, "birds.pkl"), "rb"))
FLIERS = {"one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"}
for line in ["line_birds_homecoming", "line_birds_tempo"]:
    c = collections.Counter(); ratio = []; idle_big = collections.Counter()
    for (sd, se, r), b in B.items():
        v = S.get((sd, se, r)); p = S.get((sd, se, r - 1)); bp = B.get((sd, se, r - 1))
        if r < 7 or not v or v["line"] != line or not p or not bp: continue
        new = [a for a in b["away"] if a[1] not in {x[1] for x in bp["away"]}]
        prev_board = {x[3] for x in p["rec"] if x[1] == "board"}
        elig = {x[0] for x in v["rec"] if x[1] == "board" and x[0] in FLIERS and x[3] in prev_board}
        home = [u[2] + u[3] for u in v["units"] if u[5] == "board" and u[0] in elig]
        if not new:
            if home: idle_big["no flight, an eligible flier stayed home"] += 1
            continue
        flown = max(a[2] + a[3] for a in new)
        if not home: c["no eligible flier left home"] += 1; continue
        c["flew the biggest eligible" if flown >= max(home) else "a bigger eligible flier stayed home"] += 1
        if flown < max(home): ratio.append(max(home) / max(1, flown))
    ratio.sort()
    print("==", line, "R7+ flight turns:", dict(c), dict(idle_big), " bigger-stayed size ratio median", round(ratio[len(ratio)//2], 2) if ratio else None)
