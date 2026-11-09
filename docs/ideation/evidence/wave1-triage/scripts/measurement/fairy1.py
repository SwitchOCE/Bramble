# Per-round shape of committed Fairy seats: Rings, ringed slots, Ring size, B1 share, pieces, fillers.
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
def med(v): return st.median(v) if v else float('nan')
def q(v, p):
    v = sorted(v); return v[int(p*(len(v)-1))] if v else float('nan')
for line in ["line_fairies_ring", "line_fairies_court"]:
    print("==", line)
    print("rnd n stats tier rings[q25,med,q75] ringed_slots ring_size B1rings%  fairies nonfairy annisF1 annisF2 annisOther noAnnis")
    for r in range(2, 15):
        rows = [v for (sd, se, rr), v in S.items() if rr == r and v["line"] == line]
        if not rows: continue
        tot = [sum(v["rings"]) for v in rows]
        ringed = [sum(1 for c in v["rings"] if c > 0) for v in rows]
        rs = [v["ring_size"] or 1 for v in rows]
        b1 = [v["rings"][4] / sum(v["rings"]) for v in rows if sum(v["rings"]) > 0]
        board = lambda v: [u for u in v["units"] if u[5] == "board"]
        fa = [sum(1 for u in board(v) if "Fairies" in u[7]) for v in rows]
        nf = [sum(1 for u in board(v) if "Fairies" not in u[7]) for v in rows]
        ann = collections.Counter()
        for v in rows:
            sl = [u[1] for u in board(v) if u[0] == "old_moth_annis"]
            ann["none" if not sl else ("F1" if 0 in sl else ("F2" if 1 in sl else "other"))] += 1
        n = len(rows)
        print(r, n, med([v["stats"] for v in rows]), med([v["tier"] for v in rows]),
              [q(tot, .25), med(tot), q(tot, .75)], med(ringed), med(rs), round(100*med(b1)) if b1 else None,
              med(fa), med(nf), *(round(100*ann[k]/n) for k in ["F1", "F2", "other", "none"]))
