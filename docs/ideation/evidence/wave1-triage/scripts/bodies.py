# Board fill at combat start: bodies on the board, in hand, away; empty slots holding Rings.
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
for line in ["line_fairies_ring", "line_fairies_court", "line_birds_homecoming", "line_birds_tempo", "hard_field"]:
    print("==", line)
    for r in (6, 8, 10, 12, 14):
        rows = [v for (sd, se, rr), v in S.items() if rr == r and v["line"] == line]
        if not rows: continue
        b = collections.Counter(sum(1 for u in v["units"] if u[5] == "board") for v in rows)
        hand = [sum(1 for x in v["rec"] if x[1] == "hand") for v in rows]
        away = [sum(1 for x in v["rec"] if x[1] == "away") for v in rows]
        empty_ring = [sum(1 for s in range(7) if v["rings"][s] > 0 and not any(u[1] == s and u[5] == "board" for u in v["units"])) for v in rows]
        dist = " ".join(f"{k}:{round(100*b[k]/len(rows))}" for k in sorted(b))
        print(f"  R{r} n={len(rows)} board bodies % [{dist}]  mean hand {st.mean(hand):.2f}  mean away {st.mean(away):.2f}  mean empty ringed slots {st.mean(empty_ring):.2f}")
