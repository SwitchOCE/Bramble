# Birds at R12: stayers vs the line's stayer cap (4 from R10), duplicate stayers, Eggs/Nests, Stork/Goose,
# and board growth conditional on Stork + two fliers by R8.
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
B = pickle.load(open(os.path.join(D, "birds.pkl"), "rb"))
FLIERS = {"one_swallow", "chiffchaff", "mrs_jay", "old_tern", "mother_goose"}
def med(v): return st.median(v) if v else None
def has(v, c): return any(u[0] == c and u[5] == "board" for u in v["units"]) or any(x[0] == c for x in v["rec"])
for line in ["line_birds_homecoming", "line_birds_tempo"]:
    seats = sorted({(sd, se) for (sd, se, r), v in S.items() if v["line"] == line})
    stay = []; dup = 0; n12 = 0; eggs = []; groups = collections.defaultdict(list)
    for sd, se in seats:
        v = S.get((sd, se, 12))
        if v:
            n12 += 1
            board = [u for u in v["units"] if u[5] == "board" and "Birds" in u[7]]
            st_ = [u[0] for u in board if u[0] not in FLIERS]
            stay.append(len(st_)); dup += any(c > 1 for c in collections.Counter(st_).values())
            eggs.append(sum(1 for u in v["units"] if u[5] == "egg"))
        v8 = S.get((sd, se, 8))
        if not v8: continue
        nfl = len({x[3] for r in range(1, 9) if (sd, se, r) in S for x in S[(sd, se, r)]["rec"] if x[0] in FLIERS})
        g = ("Stork" if any(has(S[(sd, se, r)], "mrs_stork") for r in range(1, 9) if (sd, se, r) in S) else "noStork") + (f"+{min(nfl,3)}fliers")
        if (sd, se, 12) in S: groups[g].append(S[(sd, se, 12)]["stats"])
    print("==", line, f"R12 survivors {n12}: stayers (non-flier Birds) median {med(stay)}, >4 stayers {round(100*sum(1 for s in stay if s > 4)/n12)}%, a duplicated stayer {round(100*dup/n12)}%, Eggs on board median {med(eggs)}")
    for g in sorted(groups): print(f"   {g:18s} n={len(groups[g]):3d} R12 median {med(groups[g])}")
