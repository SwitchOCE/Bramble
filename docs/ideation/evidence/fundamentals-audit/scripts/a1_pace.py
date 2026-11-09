import sys
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *

P, R, C, byp = load()
out = []
W = out.append

# ---- 1. Pace and stat curve by round
byround = collections.defaultdict(list)
for r in R:
    byround[r["round"]].append(r)
rows = []
for rn in sorted(byround):
    rs = byround[rn]
    full = [r for r in rs if r["units"] == 7]
    win = [r for r in rs if r["place"] == 1]
    t4 = [r for r in rs if r["place"] <= 4]
    per = [r["stats"] / r["units"] for r in rs if r["units"] > 0]
    wper = [r["stats"] / r["units"] for r in win if r["units"] > 0]
    rows.append([
        rn, len(rs), med([r["units"] for r in rs]), "%.0f%%" % (100 * len(full) / len(rs)),
        med([r["tier"] for r in rs]),
        q([r["stats"] for r in rs], .25), med([r["stats"] for r in rs]), q([r["stats"] for r in rs], .75),
        med(per), len(win), med([r["stats"] for r in win]), med(wper), med([r["stats"] for r in t4]),
        med([r["attack"] for r in rs]), med([r["health"] for r in rs]),
    ])
W("## 1. Board stats by round (all living players; board recorded after the round's fight)\n")
W(table(["round", "alive", "units med", "7 units", "tier med", "stats p25", "stats med", "stats p75", "per-unit med",
         "winners n", "winners stats med", "winners per-unit", "top-4 stats med", "attack med", "health med"], rows))

# winners final, by place final
W("\n\n## 2. Final board (last recorded round) by place\n")
rows = []
for pl in range(1, 9):
    ps = [p for p in P if p["place"] == pl]
    tot = [p["final_attack"] + p["final_health"] for p in ps]
    per = [(p["final_attack"] + p["final_health"]) / p["final_units"] for p in ps if p["final_units"]]
    rows.append([pl, len(ps), mean([p["rounds"] for p in ps]), med([p["rounds"] for p in ps]),
                 q(tot, .25), med(tot), q(tot, .75), med(per), mean([p["final_units"] for p in ps]),
                 mean([p["tier6_turn"] for p in ps if p["tier6_turn"] > 0]),
                 "%.0f%%" % (100 * mean([1 if p["tier6_turn"] > 0 else 0 for p in ps]))])
W(table(["place", "n", "rounds mean", "rounds med", "final stats p25", "final stats med", "p75", "per-unit med",
         "units", "tier6 turn (reached)", "reached T6"], rows))

# ---- 3. Lobby spread
W("\n\n## 3. Spread of boards inside one lobby, by round (median over lobbies)\n")
W("ratio = player's stats / lobby median that round, living players only.\n")
lob = collections.defaultdict(list)
for r in R:
    lob[(r["seed"], r["round"])].append(r)
rows = []
spread_series = {}
for rn in range(1, 24):
    mx, mn, cv, top2, gap, mxmin, iqr = [], [], [], [], [], [], []
    n = 0
    for (s, rr), rs in lob.items():
        if rr != rn or len(rs) < 3:
            continue
        st = sorted([x["stats"] for x in rs], reverse=True)
        m = statistics.median(st)
        if m <= 0:
            continue
        n += 1
        mx.append(st[0] / m)
        mn.append(st[-1] / m)
        mxmin.append(st[0] / max(st[-1], 1))
        top2.append(st[0] / max(st[1], 1))
        gap.append(st[0] - st[-1])
        sd = statistics.pstdev(st)
        cv.append(sd / statistics.mean(st))
        iqr.append((q(st, .75) - q(st, .25)) / m)
    if n:
        rows.append([rn, n, med(mx), med(mn), med(mxmin), med(top2), med(cv), med(iqr), med(gap)])
        spread_series[rn] = (med(mx), med(mn), med(cv))
W(table(["round", "lobbies", "max/median", "min/median", "max/min", "top/second", "CV (sd/mean)", "IQR/median", "max-min (abs)"], rows))

# ---- 4. Fights by place
W("\n\n## 4. Fights by final place\n")
rows = []
for pl in range(1, 9):
    ps = [(p["seed"], p["seat"]) for p in P if p["place"] == pl]
    w = [sum(1 for r in byp[k] if r["result"] == "win") for k in ps]
    l = [sum(1 for r in byp[k] if r["result"] == "loss") for k in ps]
    t = [sum(1 for r in byp[k] if r["result"] == "tie") for k in ps]
    n = [len(byp[k]) for k in ps]
    wr = [a / (a + b) for a, b in zip(w, l) if a + b]
    rows.append([pl, mean(n), mean(w), mean(l), mean(t), mean(wr), q(wr, .1), q(wr, .9), min(l), max(l)])
W(table(["place", "rounds", "wins", "losses", "ties", "win rate W/(W+L) mean", "p10", "p90", "min losses", "max losses"], rows))

# ---- 5. Early wins vs place
W("\n\n## 5. Wins in rounds 1-6 against final place\n")
rows = []
ew = {}
for p in P:
    k = (p["seed"], p["seat"])
    ew[k] = sum(1 for r in byp[k] if r["round"] <= 6 and r["result"] == "win")
for e in range(0, 7):
    ps = [p for p in P if ew[(p["seed"], p["seat"])] == e]
    if not ps:
        continue
    rows.append([e, len(ps), "%.1f%%" % (100 * len(ps) / len(P)), mean([p["place"] for p in ps]),
                 "%.0f%%" % (100 * mean([p["place"] <= 4 for p in ps])),
                 "%.1f%%" % (100 * mean([p["place"] == 1 for p in ps])),
                 "%.0f%%" % (100 * mean([p["place"] >= 7 for p in ps]))])
W(table(["wins R1-6", "players", "share", "mean place", "top 4", "1st", "7th-8th"], rows))

# rounds 7-12 conditional
W("\n\n## 6. Early (R1-6) and middle (R7-12) wins together: mean place (n)\n")
mid = {}
for p in P:
    k = (p["seed"], p["seat"])
    mid[k] = sum(1 for r in byp[k] if 7 <= r["round"] <= 12 and r["result"] == "win")
grid = collections.defaultdict(list)
for p in P:
    k = (p["seed"], p["seat"])
    e = ew[k]
    eb = "0-1" if e <= 1 else ("2-3" if e <= 3 else ("4" if e == 4 else "5-6"))
    m = mid[k]
    mb = "0-1" if m <= 1 else ("2-3" if m <= 3 else ("4" if m == 4 else "5-6"))
    grid[(eb, mb)].append(p["place"])
cols = ["0-1", "2-3", "4", "5-6"]
rows = []
for eb in cols:
    rows.append([eb] + ["%.2f (%d)" % (mean(grid[(eb, mb)]), len(grid[(eb, mb)])) if grid[(eb, mb)] else "-" for mb in cols])
W(table(["R1-6 wins \\ R7-12 wins"] + cols, rows))

# ---- 7. Elimination round
W("\n\n## 7. Elimination round by place (last recorded round)\n")
rows = []
for pl in range(1, 9):
    ps = [p["rounds"] for p in P if p["place"] == pl]
    rows.append([pl, min(ps), q(ps, .25), med(ps), q(ps, .75), max(ps)])
W(table(["place", "min", "p25", "median", "p75", "max"], rows))
first_out = [min(p["rounds"] for p in P if p["seed"] == s) for s in {p["seed"] for p in P}]
W("\nFirst elimination round per lobby: median %.1f, p25 %.1f, p75 %.1f. Game length (winner rounds) median %.1f, mean %.2f." % (
    med(first_out), q(first_out, .25), q(first_out, .75), med([p["rounds"] for p in P if p["place"] == 1]),
    mean([p["rounds"] for p in P if p["place"] == 1])))

open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/out_a1.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
