import sys, gzip, random
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *

out = []
W = out.append
V = "/home/alex/code/Bramble-ideation/docs/ideation/evidence/damage-v05"
G = [json.loads(l) for f in sorted(glob.glob(V + "/B.*.jsonl.gz")) for l in gzip.open(f, "rt")]
assert len(G) == 200 and all(g["complete"] for g in G)

# --- v05 B: damage per loss by round (real heroes only)
loss_by_round = collections.defaultdict(list)  # round -> list of (base, perf, damage)
ghost = collections.Counter()
ls_used = 0
kills = []
for g in G:
    for f in g["fights"]:
        pl = f["players"]
        if -1 in pl:
            gi = pl.index(-1)
            w = f["winner"]
            ghost["fights"] += 1
            ghost["ghost_win" if w == gi else ("tie" if w < 0 else "live_win")] += 1
        if f["winner"] < 0:
            continue
        for ch in f["charges"]:
            if ch["damage"] <= 0 and ch["base"] == 0 and ch["performance"] == 0:
                # round 1-3 losses still charged with 0; keep them
                pass
            loss_by_round[f["round"]].append((ch["base"], ch["performance"], ch["damage"]))
            if ch["health_after"] <= 0:
                kills.append((f["round"], ch["health_before"], ch["damage"], ch["health_after"]))
        ls_used += len(f["last_stand_sides"])

W("## 1. Damage per loss by round, damage-v05 arm B (200 Hard lobbies, older card pool, same damage rule)\n")
W("Survivors = enemy starting survivors (the 'performance' part). Each loss is one charge to a real hero.\n")
rows = []
surv_mean = {}
surv_emp = {}
for rn in sorted(loss_by_round):
    xs = loss_by_round[rn]
    perf = [x[1] for x in xs]
    surv_mean[rn] = mean(perf)
    surv_emp[rn] = perf
    rows.append([rn, len(xs), base(rn), mean(perf), med(perf), q(perf, .9), mean([x[2] for x in xs]),
                 "%.0f%%" % (100 * mean([x[1] / x[2] for x in xs if x[2] > 0])) if any(x[2] for x in xs) else "-"])
W(table(["round", "losses", "base", "survivors mean", "survivors med", "survivors p90", "damage mean", "survivor share"], rows))
W("\nGhost fights (arm B): %d; live player won %d, tied %d, ghost won %d (%.1f%%)." % (
    ghost["fights"], ghost["live_win"], ghost["tie"], ghost["ghost_win"], 100 * ghost["ghost_win"] / ghost["fights"]))
W("Last Stand saves used (arm B): %d in 200 lobbies (%.2f per lobby)." % (ls_used, ls_used / 200))
ok = [k[1] - k[2] for k in kills]
W("Killing blows: %d; Health before the blow median %.0f; overkill (damage - health before) mean %.1f, median %.0f." % (
    len(kills), med([k[1] for k in kills]), mean([-k[3] for k in kills]), med([-k[3] for k in kills])))

# --- v05 B: Health by round by place
W("\n\n## 2. Median Health at end of round, by final place (arm B)\n")
hp = collections.defaultdict(list)
losses_at_out = collections.defaultdict(list)
for g in G:
    for p in g["players"]:
        for rr in p["rounds"]:
            hp[(p["place"], rr["round"])].append(rr["health"])
        losses_at_out[p["place"]].append(sum(1 for rr in p["rounds"] if rr["result"] == "loss"))
rows = []
for rn in range(1, 23):
    rows.append([rn] + [("%.0f" % med(hp[(pl, rn)])) if len(hp[(pl, rn)]) >= 20 else "-" for pl in range(1, 9)])
W(table(["round"] + ["place %d" % i for i in range(1, 9)], rows))
W("\nLosses over the game by place (arm B): " + ", ".join(
    "%d: %.1f" % (pl, mean(losses_at_out[pl])) for pl in range(1, 9)))

# --- pass 2: base damage taken, implied survivor damage
P, R, C, byp = load()
W("\n\n## 3. Pass 2 lobbies: base damage taken and what survivors must have added\n")
W("Base damage is known exactly from the loss rounds. Health is not logged, so survivor damage is inferred: an eliminated hero took at least 40 in total.\n")
rows = []
implied = []
for pl in range(1, 9):
    ks = [(p["seed"], p["seat"]) for p in P if p["place"] == pl]
    b = [sum(base(r["round"]) for r in byp[k] if r["result"] == "loss") for k in ks]
    nl = [sum(1 for r in byp[k] if r["result"] == "loss") for k in ks]
    nlate = [sum(1 for r in byp[k] if r["result"] == "loss" and base(r["round"]) > 0) for k in ks]
    last = [byp[k][-1]["result"] for k in ks]
    if pl > 1:
        for k, bb, n in zip(ks, b, nlate):
            implied.append((40 - bb) / max(n, 1))
    rows.append([pl, mean(nl), mean(nlate), mean(b), med(b), (40 - mean(b)) if pl > 1 else float("nan"),
                 ((40 - mean(b)) / mean(nlate)) if pl > 1 else float("nan"),
                 "%.0f%%" % (100 * mean([x == "loss" for x in last]))])
W(table(["place", "losses", "losses from R4 (base>0)", "base taken mean", "base med", "survivor damage needed (40-base)",
         "per charged loss", "last fight a loss"], rows))
W("\nEliminated players: survivor damage at least %.2f per charged loss (mean of per-player lower bounds)." % mean(implied))

# Losses at elimination broken down by round of losses: distribution of when losses happen by place
W("\n\n## 4. Pass 2: when losses happen, by final place (mean losses in each band)\n")
bands = [(1, 3), (4, 6), (7, 9), (10, 12), (13, 15), (16, 23)]
rows = []
for pl in range(1, 9):
    ks = [(p["seed"], p["seat"]) for p in P if p["place"] == pl]
    row = [pl]
    for lo, hi in bands:
        row.append(mean([sum(1 for r in byp[k] if lo <= r["round"] <= hi and r["result"] == "loss") for k in ks]))
    rows.append(row)
W(table(["place"] + ["R%d-%d" % b for b in bands], rows))

# Calibrate survivors scale k for pass 2 so eliminated players' expected total damage ~= 40 + overkill
over = mean([-k[3] for k in kills])
elim = [(p["seed"], p["seat"]) for p in P if p["place"] > 1]


def total(k, scale):
    return sum(base(r["round"]) + scale * surv_mean.get(r["round"], surv_mean[max(surv_mean)]) for r in byp[k] if r["result"] == "loss")


kscale = json.load(open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/model.json"))["kscale"]  # from a2b: places 5-8 only
W("\n\nCalibration (a2b): arm B survivors-per-loss curve scaled by %.2f, fitted on pass 2 places 5-8 (no Last Stand), overkill by place from arm B." % kscale)
# check winners stay under 40
wtot = [total((p["seed"], p["seat"]), kscale) for p in P if p["place"] == 1]
W("With that scale, winners' modelled damage taken: median %.1f, p90 %.1f, share above 39: %.0f%% (Last Stand can cover one)." % (
    med(wtot), q(wtot, .9), 100 * mean([x > 39 for x in wtot])))


# --- Model paths
def dmg(rn, scale=kscale):
    return base(rn) + scale * surv_mean.get(rn, surv_mean[max(surv_mean)])


W("\n\n## 5. Model: expected Health lost per loss by round (base + scaled survivors)\n")
rows = []
cum = 0
for rn in range(1, 23):
    cum += dmg(rn)
    rows.append([rn, base(rn), dmg(rn) - base(rn), dmg(rn), cum, 40 - cum])
W(table(["round", "base", "survivors (model)", "loss costs", "cumulative if lose every round", "Health left"], rows))


def path(results, scale=kscale):
    h = 40.0
    for i, res in enumerate(results):
        rn = i + 1
        if res == "L":
            h -= dmg(rn, scale)
        if h <= 0:
            return rn, results[:rn].count("L"), h
    return None, results.count("L"), h


def mc_path(results, n=4000, seed=7, scale=kscale, laststand=False):
    rng = random.Random(seed)
    deaths, ls = [], []
    for _ in range(n):
        h = 40
        died = None
        nl = 0
        for i, res in enumerate(results):
            rn = i + 1
            if res == "L":
                emp = surv_emp.get(rn, surv_emp[max(surv_emp)])
                s = rng.choice(emp) * scale
                h -= base(rn) + round(s)
                nl += 1
                if h <= 0:
                    died = (rn, nl)
                    break
        deaths.append(died)
    dr = [d[0] for d in deaths if d]
    dl = [d[1] for d in deaths if d]
    return len(dr) / n, (med(dr) if dr else float("nan")), (med(dl) if dl else float("nan"))


W("\n\n## 6. Paths: when do you die? (expected-value model; Monte Carlo with arm B survivor draws in brackets)\n")
paths = {
    "lose every round from R1": "L" * 22,
    "lose every round from R4": "WWW" + "L" * 19,
    "win R1-6, then lose every round (mid-game slump)": "W" * 6 + "L" * 16,
    "win R1-9, then lose every round": "W" * 9 + "L" * 13,
    "win R1-12, then lose every round": "W" * 12 + "L" * 10,
    "lose R1-6, win R7-12, then lose every round": "L" * 6 + "W" * 6 + "L" * 10,
    "lose R1-8, then win R9-14, then lose every round": "L" * 8 + "W" * 6 + "L" * 8,
    "alternate W/L from R1": "WL" * 11,
    "alternate L/W from R1": "LW" * 11,
    "win 2 of 3 (WWL repeating)": "WWL" * 8,
    "lose 2 of 3 (LLW repeating)": "LLW" * 8,
}
rows = []
for name, res in paths.items():
    d, nl, h = path(res)
    p_die, mr, ml = mc_path(res)
    rows.append([name, d if d else "survives", nl, "%.0f%% die; R%s; %s losses" % (100 * p_die, mr, ml)])
W(table(["path", "dies in round", "losses by then", "Monte Carlo"], rows))

# Losses you can still afford after weak or strong opening
W("\n\n## 7. How many more losses you can afford, by Health and round the losing starts\n")
rows = []
for start in (7, 10, 12, 14, 16):
    row = [start]
    for h0 in (40, 30, 20, 10):
        h = h0
        n = 0
        rn = start
        while h > 0 and rn < 40:
            h -= dmg(rn)
            n += 1
            rn += 1
        row.append(n)
    rows.append(row)
W(table(["losing streak starts at round", "from 40 Health", "from 30", "from 20", "from 10"], rows))
W("\nRead: the number is the loss that knocks you out (e.g. 3 = you survive 2).")

# Health left after an opening of k losses in R1-6 (base sum 0+0+0+1+1+2 = 4 + survivors)
W("\n\n## 8. Health left after rounds 1-6, by losses taken in rounds 1-6 (model; losses placed at random rounds)\n")
rows = []
import itertools
for k in range(0, 7):
    hs = []
    for combo in itertools.combinations(range(1, 7), k):
        hs.append(40 - sum(dmg(rn) for rn in combo))
    rows.append([k, mean(hs), min(hs), max(hs)])
W(table(["losses in R1-6", "Health left mean", "worst placement", "best placement"], rows))

json.dump({"kscale": kscale, "surv_mean": surv_mean, "overkill": over},
          open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/model.json", "w"))
open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/out_a2.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
