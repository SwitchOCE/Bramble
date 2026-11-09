# Conditional on key pieces arriving: does the board grow as the design says?
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
def med(v): return st.median(v) if v else None
def onboard(v, card): return any(u[0] == card and u[5] == "board" for u in v["units"])
def first(sd, se, card, upto=14):
    for r in range(1, upto + 1):
        v = S.get((sd, se, r))
        if v and onboard(v, card): return r
    return None
for line, paper12 in [("line_fairies_ring", 530), ("line_fairies_court", 945)]:
    seats = sorted({(sd, se) for (sd, se, r), v in S.items() if v["line"] == line})
    groups = collections.defaultdict(list)
    for sd, se in seats:
        a = first(sd, se, "old_moth_annis", 6); c = first(sd, se, "cluricaun", 8)
        l = first(sd, se, "lob_lie_by_the_fire", 9); s = first(sd, se, "silky", 9)
        g = ("Annis<=R6" if a else "noAnnis") + ("+Clur<=R8" if c else "") + ("+Lob/Silky<=R9" if (l or s) else "")
        groups[g].append((sd, se))
    print("==", line, "paper R12", paper12)
    print(f"{'group':38s} {'n':>4s} {'surv12':>6s} {'R10 st':>7s} {'R12 st':>7s} {'R12 rings':>9s} {'R12 size':>8s} {'R12 ringed':>10s} {'R14 st':>7s}")
    for g in sorted(groups, key=lambda g: -len(groups[g])):
        ss = groups[g]
        r10 = [S[(sd, se, 10)]["stats"] for sd, se in ss if (sd, se, 10) in S]
        r12 = [S[(sd, se, 12)] for sd, se in ss if (sd, se, 12) in S]
        r14 = [S[(sd, se, 14)]["stats"] for sd, se in ss if (sd, se, 14) in S]
        print(f"{g:38s} {len(ss):4d} {len(r12):6d} {med(r10)!s:>7s} {med([v['stats'] for v in r12])!s:>7s} {med([sum(v['rings']) for v in r12])!s:>9s} {med([v['ring_size'] or 1 for v in r12])!s:>8s} {med([sum(1 for c in v['rings'] if c) for v in r12])!s:>10s} {med(r14)!s:>7s}")
