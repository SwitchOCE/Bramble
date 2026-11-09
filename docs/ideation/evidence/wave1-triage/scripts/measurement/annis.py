# Rings Annis adds per round: the increase on the slots behind her, between consecutive combats,
# when she stood in the same slot both rounds (1 a slot is End of Turn; each extra is a sale).
import pickle, os, statistics as st, collections, csv, glob
D = os.path.dirname(os.path.abspath(__file__))
S = pickle.load(open(os.path.join(D, "states.pkl"), "rb"))
BEHIND = {0: [4], 1: [4, 5], 2: [5, 6], 3: [6]}
RUN = "/home/alex/code/Bramble-ideation-sol/build/sim/wave1-accounting/run/"
rounds = {}
for path in glob.glob(RUN + "chunk-*.rounds.csv"):
    for row in csv.DictReader(open(path)):
        rounds[(int(row["seed"]), int(row["seat"]), int(row["round"]))] = row
def annis_slot(v):
    s = [u[1] for u in v["units"] if u[0] == "old_moth_annis" and u[5] == "board"]
    return s[0] if s else None
for line in ["line_fairies_ring", "line_fairies_court"]:
    inc = collections.defaultdict(list); gold = collections.defaultdict(list); tierups = collections.defaultdict(list)
    for (sd, se, r), v in S.items():
        if v["line"] != line or r < 4: continue
        p = S.get((sd, se, r - 1))
        if not p: continue
        a0, a1 = annis_slot(p), annis_slot(v)
        if a0 is None or a0 != a1 or a0 not in BEHIND: continue
        per_slot = (sum(v["rings"][s] for s in BEHIND[a0]) - sum(p["rings"][s] for s in BEHIND[a0])) / len(BEHIND[a0])
        sales = per_slot - 1  # Annis's own End of Turn Ring
        inc[r].append(sales)
        row = rounds.get((sd, se, r))
        if row: gold[r].append(int(row["gold_left"])); tierups[r].append(int(v["tier"] > p["tier"]))
    print("==", line, "rounds with Annis standing still: implied sales a turn (Rings per behind slot - 1)")
    for r in sorted(inc):
        xs = inc[r]
        print(f"  R{r:2d} n={len(xs):3d} mean sales {st.mean(xs):.2f} median {st.median(xs)}  zero-sale turns {round(100*sum(1 for x in xs if x <= 0)/len(xs))}%  gold left {st.mean(gold[r]):.2f}  tier-up turns {round(100*st.mean(tierups[r]))}%")
