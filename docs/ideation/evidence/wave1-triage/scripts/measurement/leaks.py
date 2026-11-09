# Fairy play leaks with the pieces the seat had: empty slots at combat, Hob sold while Silky stood,
# Cluricaun first played at tier 6 (his build text fires only after a tier-up), Monarch doublings.
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
SHY = {"lob_lie_by_the_fire", "silky", "hob_in_the_hearth"}
def med(v): return st.median(v) if v else None
def onboard(v, card): return any(u[0] == card and u[5] == "board" for u in v["units"])
for line in ["line_fairies_ring", "line_fairies_court"]:
    seats = sorted({(sd, se) for (sd, se, r), v in S.items() if v["line"] == line})
    uplift = []; base = []
    for sd, se in seats:
        v = S.get((sd, se, 12))
        if not v: continue
        board = [u for u in v["units"] if u[5] == "board"]
        size = v["ring_size"] or 1
        empty = [s for s in range(7) if not any(u[1] == s for u in board)]
        bodies = sorted(u[2] + u[3] - (0 if u[0] in SHY else 2 * size * v["rings"][u[1]]) for u in board)
        filler = bodies[len(bodies) // 2] if bodies else 10   # a median body from this board, without its Ring
        add = sum(filler + 2 * size * v["rings"][s] for s in empty)
        uplift.append(add / max(1, v["stats"])); base.append(v["stats"])
    print("==", line)
    print(f"  R12: filling every empty slot with a median body of the same board adds median {round(100*med(uplift))}% (mean {round(100*st.mean(uplift))}%)")
    hob = collections.Counter()
    for sd, se in seats:
        last = max(r for r in range(1, 30) if (sd, se, r) in S)
        for r in range(2, last):
            p, v = S[(sd, se, r)], S[(sd, se, r + 1)]
            ids0 = {x[3] for x in p["rec"] if x[0] == "hob_in_the_hearth" and x[1] == "board"}
            ids1 = {x[3] for x in v["rec"] if x[0] == "hob_in_the_hearth"}
            for i in ids0 - ids1:
                grew = (v["ring_size"] or 1) > (p["ring_size"] or 1)
                hob[("Silky stood" if onboard(p, "silky") else "no Silky", "S grew" if grew else "S flat")] += 1
    print("  Hob departures:", dict(hob))
    t6 = collections.Counter()
    for sd, se in seats:
        for r in range(1, 30):
            v = S.get((sd, se, r))
            if v and onboard(v, "cluricaun"):
                t6["first stood at T6 (dead)" if v["tier"] >= 6 else "first stood below T6"] += 1; break
    print("  Cluricaun seats:", dict(t6))
    mon = collections.Counter()
    for sd, se in seats:
        fr = None
        for r in range(1, 15):
            v = S.get((sd, se, r))
            if v and onboard(v, "fairy_monarch"): fr = r; break
        if fr and (sd, se, 14) in S:
            s0 = S[(sd, se, fr)]["ring_size"] or 1; s14 = S[(sd, se, 14)]["ring_size"] or 1
            mon[(14 - fr, round(s14 / s0, 1))] += 1
    print("  Monarch (rounds held to R14, Ring size R14/at arrival):", sorted(mon.items())[:25])
