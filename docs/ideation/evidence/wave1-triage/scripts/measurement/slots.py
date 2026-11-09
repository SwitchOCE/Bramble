# Which slots hold Rings, and who stands on the Rings (Shy units and empty slots waste them).
import pickle, os, statistics as st, collections
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
SHY = {"lob_lie_by_the_fire", "silky", "hob_in_the_hearth"}
NAMES = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
for line in ["line_fairies_ring", "line_fairies_court"]:
    print("==", line)
    for r in (8, 10, 12):
        rows = [v for (sd, se, rr), v in S.items() if rr == r and v["line"] == line]
        ringed = [round(100 * sum(1 for v in rows if v["rings"][s] > 0) / len(rows)) for s in range(7)]
        share = [round(100 * sum(v["rings"][s] for v in rows) / max(1, sum(sum(v["rings"]) for v in rows))) for s in range(7)]
        waste = collections.Counter(); total = 0
        stander = collections.Counter()
        for v in rows:
            at = {u[1]: u for u in v["units"] if u[5] == "board"}
            for s in range(7):
                c = v["rings"][s]; total += c
                u = at.get(s)
                if c == 0: continue
                if u is None: waste["empty"] += c
                elif u[0] in SHY: waste["shy"] += c
                else: waste["used"] += c
            b1 = at.get(4)
            stander["(empty)" if b1 is None else ("non-Fairy" if "Fairies" not in b1[7] else b1[0])] += 1
        print(f" R{r} n={len(rows)} % seats with a Ring on " + " ".join(f"{NAMES[s]}:{ringed[s]}" for s in range(7)))
        print(f"      share of all Rings  " + " ".join(f"{NAMES[s]}:{share[s]}" for s in range(7)))
        print(f"      Rings under: used {round(100*waste['used']/max(1,total))}%  Shy {round(100*waste['shy']/max(1,total))}%  empty {round(100*waste['empty']/max(1,total))}%")
        print(f"      B1 stander: " + ", ".join(f"{k} {round(100*n/len(rows))}%" for k, n in stander.most_common(8)))
