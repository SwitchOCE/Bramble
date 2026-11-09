import csv, statistics as st, sys, collections, math
D = "/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/"
INCOME = [3, 4, 5, 6, 7, 8, 9, 10]
def inc(r): return INCOME[min(r, 8) - 1]

players = {}
for row in csv.DictReader(open(D + "free_choice_plain.players.csv")):
    if any(row[k] == "" for k in ("seed", "seat", "place", "rounds", "tier6_turn")):
        continue
    players[(int(row["seed"]), int(row["seat"]))] = row
seeds = {k[0] for k in players}
rounds = collections.defaultdict(list)
bad = 0
REQ = ["seed", "seat", "round", "tier", "units", "attack", "health", "bank", "spent", "paid_refreshes", "result", "gold_left"]
for row in csv.DictReader(open(D + "free_choice_plain.rounds.csv")):
    if any(row[k] == "" for k in REQ):
        bad += 1; continue
    key = (int(row["seed"]), int(row["seat"]))
    if key not in players: bad += 1; continue
    rounds[key].append({k: (int(row[k]) if k not in ("result", "bot", "strategy", "suite") else row[k]) for k in REQ + ["larder"] if row.get(k, "") != ""})
for k in rounds: rounds[k].sort(key=lambda r: r["round"])
print("players", len(players), "seeds", len(seeds), "player-rounds", sum(len(v) for v in rounds.values()), "dropped rows", bad)

def q(xs, p):
    xs = sorted(xs)
    if not xs: return float("nan")
    i = (len(xs) - 1) * p
    lo, hi = math.floor(i), math.ceil(i)
    return xs[lo] + (xs[hi] - xs[lo]) * (i - lo)

out = []
def P(*a):
    s = " ".join(str(x) for x in a); print(s); out.append(s)

# 1. tier by round
P("\n## Tier by round (players alive that round)")
P("round,n_alive,median_tier,mean_tier,p25,p75,share_t6,median_bank,median_spent,median_gold_left,mean_gold_left,share_left_ge5,median_paid_refreshes,mean_paid_refreshes,median_board_stats,median_units,median_stats_per_unit")
byr = collections.defaultdict(list)
for k, rs in rounds.items():
    for r in rs: byr[r["round"]].append(r)
for rd in sorted(byr):
    rs = byr[rd]
    if len(rs) < 30: continue
    t = [r["tier"] for r in rs]
    stats = [r["attack"] + r["health"] for r in rs]
    spu = [(r["attack"] + r["health"]) / r["units"] for r in rs if r["units"] > 0]
    P(rd, len(rs), st.median(t), round(st.mean(t), 2), q(t, .25), q(t, .75), round(sum(x == 6 for x in t) / len(t), 3),
      st.median(r["bank"] for r in rs), st.median(r["spent"] for r in rs), st.median(r["gold_left"] for r in rs),
      round(st.mean(r["gold_left"] for r in rs), 2), round(sum(r["gold_left"] >= 5 for r in rs) / len(rs), 3),
      st.median(r["paid_refreshes"] for r in rs), round(st.mean(r["paid_refreshes"] for r in rs), 2),
      st.median(stats), st.median(r["units"] for r in rs), round(st.median(spu), 1) if spu else "")

# 2. tier-6
P("\n## Tier 6")
t6 = [int(p["tier6_turn"]) for p in players.values()]
reached = [x for x in t6 if x > 0]
P("players", len(t6), "reached t6", len(reached), round(len(reached) / len(t6), 3), "median t6 turn", st.median(reached), "p25", q(reached, .25), "p75", q(reached, .75), "min", min(reached))
# by place
for pl in range(1, 9):
    ps = [p for p in players.values() if int(p["place"]) == pl]
    r6 = [int(p["tier6_turn"]) for p in ps if int(p["tier6_turn"]) > 0]
    P(f"place {pl}: n {len(ps)} rounds median {st.median(int(p['rounds']) for p in ps)} reached t6 {round(len(r6)/len(ps),3)} median t6 turn {st.median(r6) if r6 else '-'} final board stats median {st.median(int(p['final_attack'])+int(p['final_health']) for p in ps)} units {st.median(int(p['final_units']) for p in ps)} gold_spent median {st.median(int(p['gold_spent']) for p in ps)}")
# Did players who never reached t6 die before t6 median turn?
nt6 = [p for p in players.values() if int(p["tier6_turn"]) == 0]
P("never reached t6: n", len(nt6), "median rounds survived", st.median(int(p["rounds"]) for p in nt6), "share surviving past round 15", round(sum(int(p["rounds"]) >= 15 for p in nt6) / len(nt6), 3))
P("game length (winner rounds): median", st.median(int(p["rounds"]) for p in players.values() if int(p["place"]) == 1),
  "p10", q([int(p["rounds"]) for p in players.values() if int(p["place"]) == 1], .1), "p90", q([int(p["rounds"]) for p in players.values() if int(p["place"]) == 1], .9))

# 3. first round each tier reached, per player (from round rows)
P("\n## First round at each tier (players who reached it)")
first = collections.defaultdict(list)
for k, rs in rounds.items():
    seen = set()
    for r in rs:
        for t in range(2, r["tier"] + 1):
            if t not in seen:
                seen.add(t); first[t].append(r["round"])
for t in range(2, 7):
    P(f"tier {t}: n {len(first[t])} median {st.median(first[t])} p25 {q(first[t], .25)} p75 {q(first[t], .75)} p10 {q(first[t], .1)}")
# winners only
P("winners only:")
firstw = collections.defaultdict(list)
for k, rs in rounds.items():
    if int(players[k]["place"]) != 1: continue
    seen = set()
    for r in rs:
        for t in range(2, r["tier"] + 1):
            if t not in seen:
                seen.add(t); firstw[t].append(r["round"])
for t in range(2, 7):
    P(f"tier {t}: n {len(firstw[t])} median {st.median(firstw[t])} p25 {q(firstw[t], .25)} p75 {q(firstw[t], .75)}")

# 4. gold flows: extra start-of-turn gold and in-turn gold
P("\n## Gold flows by round")
P("round,median_income_table,mean_extra_start_gold(bank-carry-income),mean_in_turn_gain(spent+left-bank),share_rounds_with_upgrade,mean_total_gold_per_round")
for rd in sorted(byr):
    rs = byr[rd]
    if len(rs) < 30: continue
    extra, gain, up = [], [], []
    for r in rs:
        key = None
    # need previous round per player
for rd in range(1, 26):
    extra, gain, up, tot = [], [], [], []
    for k, rs in rounds.items():
        idx = {r["round"]: r for r in rs}
        if rd not in idx: continue
        r = idx[rd]
        prev_left = idx[rd - 1]["gold_left"] if rd - 1 in idx else 0
        prev_tier = idx[rd - 1]["tier"] if rd - 1 in idx else 1
        extra.append(r["bank"] - prev_left - inc(rd))
        gain.append(r["spent"] + r["gold_left"] - r["bank"])
        up.append(r["tier"] > prev_tier)
        tot.append(r["spent"])
    if len(extra) < 30: continue
    P(rd, inc(rd), round(st.mean(extra), 2), round(st.mean(gain), 2), round(sum(up) / len(up), 3), round(st.mean(tot), 2))

# 5. cumulative spend and spend by end of game
P("\n## Cumulative gold spent by round (median), all players alive")
for rd in (3, 5, 8, 10, 12, 14, 16, 18, 20):
    cs = []
    for k, rs in rounds.items():
        s = sum(r["spent"] for r in rs if r["round"] <= rd)
        if any(r["round"] == rd for r in rs): cs.append(s)
    if cs: P(rd, "n", len(cs), "median cum spent", st.median(cs), "income-table cum", sum(inc(i) for i in range(1, rd + 1)))

# 6. paid refreshes distribution overall at tier 6
p6 = [r["paid_refreshes"] for rs in rounds.values() for r in rs if r["tier"] == 6]
P("\n## paid refreshes at tier 6 rounds: n", len(p6), "median", st.median(p6), "p90", q(p6, .9), "max", max(p6), "share >15", round(sum(x > 15 for x in p6) / len(p6), 4))
pa = [r["paid_refreshes"] for rs in rounds.values() for r in rs]
P("paid refreshes all rounds: median", st.median(pa), "p90", q(pa, .9), "p99", q(pa, .99), "max", max(pa))
gl = [r["gold_left"] for rs in rounds.values() for r in rs]
P("gold_left all rounds: median", st.median(gl), "p90", q(gl, .9), "p99", q(gl, .99), "max", max(gl))
bk = [r["bank"] for rs in rounds.values() for r in rs]
P("bank (gold at turn start) all rounds: median", st.median(bk), "p90", q(bk, .9), "p99", q(bk, .99), "max", max(bk))

open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/econ_pace_tables.txt", "w").write("\n".join(out))
