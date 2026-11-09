import sys, random
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *

P, R, C, byp = load()
out = []
W = out.append
lob = collections.defaultdict(list)
for r in R:
    lob[(r["seed"], r["round"])].append(r)

# --- validation: even rounds balance
bad = 0
for (s, rn), rs in lob.items():
    w = sum(r["result"] == "win" for r in rs)
    l = sum(r["result"] == "loss" for r in rs)
    t = sum(r["result"] == "tie" for r in rs)
    if len(rs) % 2 == 0 and (w != l or t % 2):
        bad += 1
W("Check: lobby-rounds with an even number alive where wins != losses or ties are odd: %d (expect 0).\n" % bad)

# --- 1. per-player win rate distribution
W("## 1. Per-player win rate W/(W+L), all 3,200 players\n")
wr = []
for p in P:
    k = (p["seed"], p["seat"])
    w = sum(r["result"] == "win" for r in byp[k])
    l = sum(r["result"] == "loss" for r in byp[k])
    wr.append((w / (w + l), w + l, p["place"]))
bins = [0, .1, .2, .3, .4, .5, .6, .7, .8, .9, 1.01]
rows = []
for a, b in zip(bins, bins[1:]):
    sel = [x for x in wr if a <= x[0] < b]
    rows.append(["%.0f-%.0f%%" % (100 * a, min(100, 100 * b)), len(sel), "%.1f%%" % (100 * len(sel) / len(wr)),
                 mean([x[2] for x in sel]) if sel else float("nan")])
W(table(["win rate", "players", "share", "mean place"], rows))
allw = sum(r["result"] == "win" for r in R)
alll = sum(r["result"] == "loss" for r in R)
allt = sum(r["result"] == "tie" for r in R)
W("\nAll fights pooled: %d wins, %d losses, %d ties: win share of decided %.2f%%. Mean of per-player rates %.1f%%, median %.1f%%, sd %.1f points." % (
    allw, alll, allt, 100 * allw / (allw + alll), 100 * mean([x[0] for x in wr]), 100 * med([x[0] for x in wr]),
    100 * statistics.pstdev([x[0] for x in wr])))
# null: coin flips with each player's own number of decided fights
rng = random.Random(1)
sims = []
for _ in range(20):
    sims.append(statistics.pstdev([sum(rng.random() < .5 for _ in range(n)) / n for _, n, _ in wr]))
W("Coin-flip null with the same fight counts: sd %.1f points. Observed spread is %.1fx the coin-flip spread." % (
    100 * mean(sims), statistics.pstdev([x[0] for x in wr]) / mean(sims)))

# --- 2. win rate by round and alive count
W("\n\n## 2. Win chance against lobby rank of board stats (rounds with 8 alive)\n")
W("Rank 1 = biggest board in the lobby that round. 'Stats decide' = the bigger board always wins against a random opponent: (8-rank)/7.\n")
rk = collections.defaultdict(lambda: collections.Counter())
for (s, rn), rs in lob.items():
    if len(rs) != 8 or rn < 3:
        continue
    srt = sorted(rs, key=lambda x: -x["stats"])
    for i, r in enumerate(srt):
        band = "R3-5" if rn <= 5 else ("R6-8" if rn <= 8 else "R9-11")
        rk[(band, i + 1)][r["result"]] += 1
rows = []
for i in range(1, 9):
    row = [i, "%.0f%%" % (100 * (8 - i) / 7)]
    for band in ("R3-5", "R6-8", "R9-11"):
        c = rk[(band, i)]
        n = c["win"] + c["loss"] + c["tie"]
        row.append("%.0f%%" % (100 * c["win"] / n) if n else "-")
    rows.append(row)
W(table(["stat rank", "stats decide", "R3-5", "R6-8", "R9-11"], rows))

W("\n\n## 3. Win chance by board size relative to the lobby median (all rounds 4+, all alive counts)\n")
rb = collections.defaultdict(lambda: collections.Counter())
for (s, rn), rs in lob.items():
    if rn < 4:
        continue
    m = statistics.median([x["stats"] for x in rs])
    if m <= 0:
        continue
    for r in rs:
        x = r["stats"] / m
        b = min(int(x * 20) / 20, 1.5)
        b = max(b, 0.6)
        rb[b][r["result"]] += 1
rows = []
for b in sorted(rb):
    c = rb[b]
    n = sum(c.values())
    rows.append(["%.2f-%.2f" % (b, b + .05) if 0.6 < b < 1.5 else ("<=0.65" if b <= 0.6 else ">=1.50"), n,
                 "%.0f%%" % (100 * c["win"] / n), "%.0f%%" % (100 * c["tie"] / n)])
W(table(["stats / lobby median", "fights", "win", "tie"], rows))

# --- 4. streaks
W("\n\n## 4. Streaks by final place\n")


def streaks(seq, sym):
    best = cur = 0
    runs = []
    for x in seq:
        if x == sym:
            cur += 1
            best = max(best, cur)
        else:
            if cur:
                runs.append(cur)
            cur = 0
    if cur:
        runs.append(cur)
    return best, runs


rows = []
lrun_all = collections.Counter()
runs_obs, runs_exp, runs_var = 0, 0, 0
for pl in range(1, 9):
    ks = [(p["seed"], p["seat"]) for p in P if p["place"] == pl]
    bw, bl, fin = [], [], []
    for k in ks:
        seq = [r["result"] for r in byp[k]]
        a, _ = streaks(seq, "win")
        b, lr = streaks(seq, "loss")
        bw.append(a)
        bl.append(b)
        for x in lr:
            lrun_all[x] += 1
        # final losing streak
        f = 0
        for x in reversed(seq):
            if x == "loss":
                f += 1
            else:
                break
        fin.append(f)
        # Wald-Wolfowitz runs on decided fights (ties dropped)
        d = [x for x in seq if x != "tie"]
        n1 = d.count("win")
        n2 = d.count("loss")
        n = n1 + n2
        if n1 and n2 and n > 2:
            runs = 1 + sum(1 for i in range(1, n) if d[i] != d[i - 1])
            e = 1 + 2 * n1 * n2 / n
            v = 2 * n1 * n2 * (2 * n1 * n2 - n) / (n * n * (n - 1))
            runs_obs += runs
            runs_exp += e
            runs_var += v
    rows.append([pl, mean(bw), mean(bl), max(bl), mean(fin), med(fin)])
W(table(["place", "longest win streak", "longest loss streak", "max loss streak", "final loss streak mean", "median"], rows))
W("\nRuns test on decided fights (all players): observed %d runs, expected %.0f if results were in random order within each player's own record; z = %.1f." % (
    runs_obs, runs_exp, (runs_obs - runs_exp) / math.sqrt(runs_var)))
W("Fewer runs than expected means results cluster into streaks beyond what each player's overall rate explains.")
W("Loss-run lengths (all runs): " + ", ".join("%d: %d" % (k, lrun_all[k]) for k in sorted(lrun_all)))

# --- 5. ties
W("\n\n## 5. Ties by round\n")
rows = []
for rn in range(1, 24):
    rs = [r for r in R if r["round"] == rn]
    if not rs:
        continue
    rows.append([rn, len(rs), "%.1f%%" % (100 * mean([r["result"] == "tie" for r in rs]))])
W(table(["round", "player-fights", "tie share"], rows))
W("\nOverall tie share: %.1f%% of player-fights." % (100 * allt / len(R)))

# --- 6. ghosts
W("\n\n## 6. Ghost fights (odd number alive)\n")
Pk = {(p["seed"], p["seat"]): p for p in P}
elim = collections.defaultdict(list)  # seed -> list of (round, place, seat)
for p in P:
    if p["place"] > 1:
        elim[p["seed"]].append((p["rounds"], p["place"], p["seat"]))
gh = []
for (s, rn), rs in lob.items():
    if len(rs) % 2 == 0:
        continue
    w = sum(r["result"] == "win" for r in rs)
    l = sum(r["result"] == "loss" for r in rs)
    res = "live_win" if w > l else ("ghost_win" if l > w else "tie")
    prior = [e for e in elim[s] if e[0] < rn]
    last_round = max(e[0] for e in prior)
    cands = [e for e in prior if e[0] == last_round]
    g = min(cands, key=lambda e: e[1])  # best place among that round's eliminations = last in the out list
    gk = (s, g[2])
    gstats = byp[gk][-1]["stats"]
    m = statistics.median([x["stats"] for x in rs])
    gh.append({"round": rn, "alive": len(rs), "res": res, "age": rn - last_round, "rel": gstats / m if m else float("nan"),
               "lowest": gstats < min(x["stats"] for x in rs)})
c = collections.Counter(g["res"] for g in gh)
W("Ghost fights: %d (%.2f per lobby). Live player won %d (%.1f%%), tied %d, ghost won %d (%.1f%%)." % (
    len(gh), len(gh) / 400, c["live_win"], 100 * c["live_win"] / len(gh), c["tie"], c["ghost_win"], 100 * c["ghost_win"] / len(gh)))
W("Ghost board stats / living lobby median: median %.2f, p90 %.2f; ghost smaller than every living board in %.0f%% of ghost fights; ghost age (rounds since its owner went out) median %.0f, max %d." % (
    med([g["rel"] for g in gh]), q([g["rel"] for g in gh], .9), 100 * mean([g["lowest"] for g in gh]), med([g["age"] for g in gh]), max(g["age"] for g in gh)))
rows = []
for a in (7, 5, 3):
    sel = [g for g in gh if g["alive"] == a]
    if sel:
        cc = collections.Counter(g["res"] for g in sel)
        rows.append([a, len(sel), med([g["rel"] for g in sel]), "%.1f%%" % (100 * cc["ghost_win"] / len(sel)), "%.1f%%" % (100 * cc["tie"] / len(sel))])
W(table(["alive", "ghost fights", "ghost stats / median", "ghost wins", "ties"], rows))
rows = []
for lo, hi in ((0, .8), (.8, .9), (.9, 1.0), (1.0, 3)):
    sel = [g for g in gh if lo <= g["rel"] < hi]
    if sel:
        cc = collections.Counter(g["res"] for g in sel)
        rows.append(["%.1f-%.1f" % (lo, hi), len(sel), "%.1f%%" % (100 * cc["ghost_win"] / len(sel))])
W("\n" + table(["ghost stats / median", "fights", "ghost wins"], rows))
# compare: live boards of the same relative size win how often vs a random opponent
W("\nFor comparison, a living board at 0.8-0.9 of the lobby median wins about the rate in section 3 against live opponents.")

open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/out_a3.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
