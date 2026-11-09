import csv, statistics as st, collections, math
D = "/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/"
COST = {2: 5, 3: 7, 4: 8, 5: 11, 6: 13}
players = {}
for row in csv.DictReader(open(D + "free_choice_plain.players.csv")):
    players[(int(row["seed"]), int(row["seat"]))] = row
rounds = collections.defaultdict(dict)
for row in csv.DictReader(open(D + "free_choice_plain.rounds.csv")):
    k = (int(row["seed"]), int(row["seat"]))
    rounds[k][int(row["round"])] = {c: int(row[c]) for c in ("tier", "units", "attack", "health", "bank", "spent", "paid_refreshes", "larder", "gold_left")} | {"result": row["result"]}

# Joint tier5 -> tier6 rounds
joint = collections.Counter()
gap = collections.Counter()
for k, rs in rounds.items():
    t5 = next((r for r in sorted(rs) if rs[r]["tier"] >= 5), None)
    t6 = next((r for r in sorted(rs) if rs[r]["tier"] >= 6), None)
    if t5 and t6: joint[(t5, t6)] += 1; gap[t6 - t5] += 1
print("tier5->tier6 (round reached t5, round reached t6): count, top 12")
for (a, b), n in joint.most_common(12): print(a, b, n)
print("gap t5->t6 rounds:", sorted(gap.items()))

# Could the player have afforded the next climb at turn start, under plain discount, in rounds where it did not climb?
# cost model: base cost of next tier minus rounds since last climb (round 1 counts 0; discount from turn 2), floor 0.
afford_no_climb = collections.Counter(); no_climb = collections.Counter(); climb = collections.Counter()
for k, rs in rounds.items():
    last_climb_round = 1
    prev_tier = 1
    for r in sorted(rs):
        row = rs[r]
        t = row["tier"]
        if prev_tier >= 6:
            prev_tier = t; continue
        cost = max(0, COST[prev_tier + 1] - (r - last_climb_round))
        if t > prev_tier:
            climb[prev_tier] += 1
            last_climb_round = r
        else:
            no_climb[prev_tier] += 1
            if row["bank"] + row["larder"] >= cost:
                afford_no_climb[prev_tier] += 1
        prev_tier = t
print("\nrounds at tier t with no climb, and share where turn-start gold (bank+larder) >= plain next-tier cost")
for t in range(1, 6):
    print(f"tier {t}: no-climb rounds {no_climb[t]}, could afford {afford_no_climb[t]} ({afford_no_climb[t]/max(1,no_climb[t]):.2f}); climbs {climb[t]}")

# Upgrade gold share: estimate gold spent on climbs using plain cost model vs total spent through round 14 for players alive at 14
up_share = []
for k, rs in rounds.items():
    if 14 not in rs: continue
    last = 1; prev = 1; upg = 0
    for r in sorted(rs):
        if r > 14: break
        t = rs[r]["tier"]
        while t > prev:
            c = max(0, COST[prev + 1] - (r - last)); upg += c; last = r; prev += 1
    tot = sum(rs[r]["spent"] for r in rs if r <= 14)
    up_share.append(upg / tot if tot else 0)
print("\nestimated share of gold spent on climbs through round 14 (plain discount model, upper-ish bound):", round(st.median(up_share), 3), "n", len(up_share))

# Banking: max gold_left per player, and rounds with gold_left >= 5
mx = [max(r["gold_left"] for r in rs.values()) for rs in rounds.values()]
print("\nmax gold carried by a player in a game: median", st.median(mx), "p90", sorted(mx)[int(.9*len(mx))], "max", max(mx))
lard = [max(r["larder"] for r in rs.values()) for rs in rounds.values()]
print("max larder (gold value of Acorn items held) per player: median", st.median(lard), "p90", sorted(lard)[int(.9*len(lard))], "max", max(lard))
pr_tot = collections.Counter()
for rs in rounds.values():
    for r in rs.values(): pr_tot[min(r["paid_refreshes"], 9)] += 1
print("paid refreshes per turn distribution:", sorted(pr_tot.items()))

# Board stats growth per unit per turn
by = collections.defaultdict(list)
for rs in rounds.values():
    for r, row in rs.items():
        if row["units"]: by[r].append((row["attack"] + row["health"]))
med = {r: st.median(v) for r, v in by.items() if len(v) > 100}
print("\nmedian board stats by round:", {r: med[r] for r in sorted(med)})
print("growth per round 9->20:", round((med[20] - med[9]) / 11, 1), "SP per board per round =", round((med[20] - med[9]) / 11 / 7, 2), "per unit")
# top boards
allb = [(row["attack"] + row["health"], row["units"], r, k) for k, rs in rounds.items() for r, row in rs.items()]
allb.sort(reverse=True)
print("largest boards seen:", allb[:5])
# winners final
w = [int(p["final_attack"]) + int(p["final_health"]) for p in players.values() if p["place"] == "1"]
print("winner final board stats: median", st.median(w), "p90", sorted(w)[int(.9*len(w))], "max", max(w), "-> per unit median", round(st.median(w)/7, 1))
# win/loss streaks: number of losses a player took before dying, and winners' losses
L = collections.defaultdict(list)
for k, rs in rounds.items():
    pl = int(players[k]["place"])
    L[pl].append(sum(1 for r in rs.values() if r["result"] == "loss"))
print("\nlosses taken in game, by place (median):", {p: st.median(v) for p, v in sorted(L.items())})
res = collections.Counter(r["result"] for rs in rounds.values() for r in rs.values())
print("results:", res)
