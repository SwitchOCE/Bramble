# Birds: flights, homecomings, eligible fliers left at home, Lump on the biggest Nest, biggest Bird.
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
B = pickle.load(open(os.path.join(D, "birds.pkl"), "rb"))
FLIERS = {"one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"}
def med(v): return st.median(v) if v else None
for line in ["line_birds_homecoming", "line_birds_tempo"]:
    seats = sorted({(sd, se) for (sd, se, r), v in S.items() if v["line"] == line})
    flights_by12 = []; homes_by12 = []; idle = collections.defaultdict(lambda: [0, 0]); lump = collections.Counter()
    biggest12 = []; fliers_home12 = []; away12 = []; birdshare12 = []; nonbird12 = []
    for sd, se in seats:
        nfl = 0; nh = 0
        for r in range(2, 13):
            v, p = S.get((sd, se, r)), S.get((sd, se, r - 1))
            b, bp = B.get((sd, se, r)), B.get((sd, se, r - 1))
            if not (v and p and b and bp): break
            away_now = {a[1] for a in b["away"]}; away_prev = {a[1] for a in bp["away"]}
            nfl += len(away_now - away_prev); nh += b["home"]
            # fliers that stood on the board at the last combat and the one before (so fought at home), still home now
            on_prev = {x[3]: x[0] for x in p["rec"] if x[1] == "board" and x[0] in FLIERS}
            pp = S.get((sd, se, r - 2))
            on_pp = {x[3] for x in pp["rec"] if x[1] == "board"} if pp else set()
            on_now = {x[3] for x in v["rec"] if x[1] == "board"}
            for iid, card in on_prev.items():
                if iid in on_pp or True:
                    idle[r][1] += 1
                    if iid in on_now and iid not in away_now: idle[r][0] += 1
            if any(u[0] == "great_lump" and u[5] == "board" for u in v["units"]) and b["nests"]:
                big = max(b["nests"], key=lambda n: n[2] + n[3])
                at = [u[1] for u in v["units"] if u[0] == "great_lump" and u[5] == "board"]
                nest_slots = {n[0] for n in b["nests"]}
                lump["on biggest Nest" if big[0] in at else ("on another Nest" if nest_slots & set(at) else "off any Nest")] += 1
            if r == 12:
                flights_by12.append(nfl); homes_by12.append(nh)
                birds = [u for u in v["units"] if u[5] == "board" and "Birds" in u[7]]
                biggest12.append(max([u[2] + u[3] for u in birds] + [a[2] + a[3] for a in b["away"]] + [0]))
                fliers_home12.append(sum(1 for u in v["units"] if u[5] == "board" and u[0] in FLIERS))
                away12.append(len(b["away"]))
                nonbird12.append(sum(1 for u in v["units"] if u[5] == "board" and "Birds" not in u[7]))
    print("==", line, "seats", len(seats))
    print(f"  by R12 (survivors): flights median {med(flights_by12)} (q25 {sorted(flights_by12)[len(flights_by12)//4]}, q75 {sorted(flights_by12)[3*len(flights_by12)//4]}), homecomings {med(homes_by12)}")
    print(f"  R12: biggest Bird (home or away) A+H median {med(biggest12)}; fliers at home {med(fliers_home12)}; away {med(away12)}; non-Birds on board {med(nonbird12)}")
    print("  share of fliers that stood last combat and are still home this combat (didn't fly):", {r: f"{round(100*a/max(1,n))}% of {n}" for r, (a, n) in sorted(idle.items())})
    print("  Lump with Nests open:", dict(lump))
