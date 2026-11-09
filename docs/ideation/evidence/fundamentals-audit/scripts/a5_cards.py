import sys
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *

P, R, C, byp = load()
U = {}
for f in glob.glob("/home/alex/code/Bramble-ideation-balance/content/units/*.json"):
    d = json.load(open(f))
    U[d["id"]] = d
out = []
W = out.append
place = {(p["seed"], p["seat"]): p["place"] for p in P}
boards = collections.defaultdict(list)
for c in C:
    boards[(int(c["seed"]), int(c["seat"]))].append(c)
nb = len(boards)
nw = sum(1 for k in boards if place[k] == 1)
on_all = collections.Counter()
on_win = collections.Counter()
on_top4 = collections.Counter()
gold_win = collections.Counter()
for k, cs in boards.items():
    ids = {c["card"] for c in cs}
    for i in ids:
        on_all[i] += 1
        if place[k] == 1:
            on_win[i] += 1
        if place[k] <= 4:
            on_top4[i] += 1
    if place[k] == 1:
        for c in cs:
            if c["golden"] == "1":
                gold_win[c["card"]] += 1
W("## 1. Cards on winning final boards (400 winners; %d final boards in all)\n" % nb)
W("Share = boards with at least one copy. Lift = share of winner boards / share of all final boards. Final boards of 1st and 2nd are late-game boards, so high-tier cards lift by construction: compare within a tier.\n")
rows = []
for cid, n in on_win.most_common(30):
    u = U.get(cid, {})
    rows.append([u.get("name", cid), u.get("tier", "?"), "/".join(u.get("tribes", [])) or "neutral", "%d/%d" % (u.get("attack", 0), u.get("health", 0)),
                 "%.0f%%" % (100 * n / nw), "%.0f%%" % (100 * on_all[cid] / nb), "%.2f" % ((n / nw) / (on_all[cid] / nb)), gold_win[cid]])
W(table(["card", "tier", "tribe", "printed", "on winner boards", "on all final boards", "lift", "golden copies on winner boards"], rows))

# Within-tier lift: tier average lift
W("\n\n## 2. Highest and lowest lift within each tier (cards on 40+ final boards)\n")
rows = []
for t in range(1, 7):
    cs = [cid for cid in on_all if U.get(cid, {}).get("tier") == t and on_all[cid] >= 40]
    if not cs:
        continue
    lifts = sorted(((on_win[c] / nw) / (on_all[c] / nb), c) for c in cs)
    avg = mean([l for l, _ in lifts])
    hi = lifts[-3:][::-1]
    lo = lifts[:2]
    rows.append([t, len(cs), "%.2f" % avg, "; ".join("%s %.2f" % (U[c]["name"], l) for l, c in hi), "; ".join("%s %.2f" % (U[c]["name"], l) for l, c in lo)])
W(table(["tier", "cards", "mean lift", "top 3", "bottom 2"], rows))

# Board composition of winners
W("\n\n## 3. Winner boards: tier mix, goldens, tribe count\n")
tiers = collections.Counter()
goldens = []
ntr = []
for k, cs in boards.items():
    if place[k] != 1:
        continue
    for c in cs:
        tiers[U.get(c["card"], {}).get("tier", 0)] += 1
    goldens.append(sum(c["golden"] == "1" for c in cs))
tot = sum(tiers.values())
W("Units by tier on winner boards: " + ", ".join("T%d %.0f%%" % (t, 100 * tiers[t] / tot) for t in sorted(tiers)))
W("Golden units per winner board: mean %.2f, median %.0f; boards with 0 goldens %.0f%%." % (mean(goldens), med(goldens), 100 * mean([g == 0 for g in goldens])))
pf = collections.Counter(p["final_tribe"] for p in P if p["place"] == 1)
W("Winners' final tribe label: " + ", ".join("%s %d" % kv for kv in pf.most_common()))

# Top cards by printed stats? caps
W("\n\n## 4. Caps on permanent growth among slice units\n")
caps = [(d["name"], d["tier"], d.get("permanent_buff_cap")) for d in U.values() if d.get("set") == "slice" and d.get("permanent_buff_cap")]
W("Slice units with a permanent_buff_cap field: %d of %d." % (len(caps), sum(1 for d in U.values() if d.get("set") == "slice")))
W("; ".join("%s (T%d) %s" % c for c in sorted(caps, key=lambda c: c[1])))
open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/out_a5.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
