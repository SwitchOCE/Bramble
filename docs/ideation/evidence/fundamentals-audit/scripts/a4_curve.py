import sys
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *

P, R, C, byp = load()
out = []
W = out.append


def lstsq(X, y):
    # tiny normal-equation solver
    n = len(X[0])
    A = [[sum(X[k][i] * X[k][j] for k in range(len(X))) for j in range(n)] for i in range(n)]
    b = [sum(X[k][i] * y[k] for k in range(len(X))) for i in range(n)]
    for i in range(n):
        piv = max(range(i, n), key=lambda r: abs(A[r][i]))
        A[i], A[piv] = A[piv], A[i]
        b[i], b[piv] = b[piv], b[i]
        for r in range(n):
            if r != i:
                f = A[r][i] / A[i][i]
                for c in range(i, n):
                    A[r][c] -= f * A[i][c]
                b[r] -= f * b[i]
    return [b[i] / A[i][i] for i in range(n)]


def r2(y, yh):
    m = mean(y)
    return 1 - sum((a - b) ** 2 for a, b in zip(y, yh)) / sum((a - m) ** 2 for a in y)


def fits(xs, ys, label):
    rows = []
    c = lstsq([[1, x] for x in xs], ys)
    lin = [c[0] + c[1] * x for x in xs]
    rows.append([label, "linear", "%.1f + %.2f r" % (c[0], c[1]), r2(ys, lin), max(abs(a - b) for a, b in zip(ys, lin))])
    c2 = lstsq([[1, x, x * x] for x in xs], ys)
    quad = [c2[0] + c2[1] * x + c2[2] * x * x for x in xs]
    rows.append([label, "quadratic", "%.1f + %.2f r + %.3f r^2" % tuple(c2), r2(ys, quad), max(abs(a - b) for a, b in zip(ys, quad))])
    ce = lstsq([[1, x] for x in xs], [math.log(y) for y in ys])
    ex = [math.exp(ce[0] + ce[1] * x) for x in xs]
    rows.append([label, "exponential", "%.1f * %.3f^r" % (math.exp(ce[0]), math.exp(ce[1])), r2(ys, ex), max(abs(a - b) for a, b in zip(ys, ex))])
    cp = lstsq([[1, math.log(x)] for x in xs], [math.log(y) for y in ys])
    pw = [math.exp(cp[0]) * x ** cp[1] for x in xs]
    rows.append([label, "power", "%.2f * r^%.2f" % (math.exp(cp[0]), cp[1]), r2(ys, pw), max(abs(a - b) for a, b in zip(ys, pw))])
    return rows


series = {}
for name, sel in (("everyone alive", lambda r: True), ("eventual winners", lambda r: r["place"] == 1),
                  ("eventual 5th-8th", lambda r: r["place"] >= 5)):
    by = collections.defaultdict(list)
    for r in R:
        if sel(r):
            by[r["round"]].append(r)
    series[name] = by

W("## 1. Shape of the median board-stats curve (fits on rounds 5-16; 5 = first full board, 16 = last round all winners are present)\n")
xs = list(range(5, 17))
rows = []
for name in ("everyone alive", "eventual winners"):
    ys = [med([r["stats"] for r in series[name][x]]) for x in xs]
    rows += fits(xs, ys, name)
W(table(["series", "model", "fit", "R^2", "max error"], rows))
xs2 = list(range(8, 20))
ys2 = [med([r["stats"] for r in series["eventual winners"][x]]) for x in xs2]
W("\nWinners, rounds 8-19 only (income is flat at 10 from round 8):\n")
W(table(["series", "model", "fit", "R^2", "max error"], fits(xs2, ys2, "winners R8-19")))

W("\n\n## 2. Growth per round: median stats, increment, and growth rate\n")
rows = []
prev = {}
for x in range(2, 23):
    row = [x]
    for name in ("everyone alive", "eventual winners", "eventual 5th-8th"):
        rs = series[name].get(x, [])
        if len(rs) < 30:
            row += ["-", "-", "-"]
            continue
        m = med([r["stats"] for r in rs])
        p = prev.get(name)
        row += [m, (m - p) if p is not None else "-", ("%.0f%%" % (100 * (m - p) / p)) if p else "-"]
        prev[name] = m
    rows.append(row)
W(table(["round", "all med", "all +", "all %", "winners med", "winners +", "winners %", "5th-8th med", "5th-8th +", "5th-8th %"], rows))

# per-player within-player increments (same player, consecutive rounds) - removes survivorship
W("\n\n## 3. Same-player growth per round (median of each player's own increase from the previous round)\n")
inc = collections.defaultdict(list)
incw = collections.defaultdict(list)
for k, rs in byp.items():
    for a, b in zip(rs, rs[1:]):
        inc[b["round"]].append(b["stats"] - a["stats"])
        if b["place"] == 1:
            incw[b["round"]].append(b["stats"] - a["stats"])
rows = [[x, len(inc[x]), med(inc[x]), q(inc[x], .1), q(inc[x], .9), med(incw[x]) if incw[x] else "-"] for x in range(2, 23) if len(inc[x]) >= 30]
W(table(["round", "players", "median +", "p10", "p90", "winners median +"], rows))

# stats per gold
W("\n\n## 4. Board stats per gold spent so far (all alive): does a gold buy more stats later?\n")
rows = []
for x in range(2, 23):
    vals = []
    vals_round = []
    for k, rs in byp.items():
        sub = [r for r in rs if r["round"] <= x]
        if not sub or sub[-1]["round"] != x:
            continue
        spent = sum(r["spent"] for r in sub)
        if spent > 0:
            vals.append(sub[-1]["stats"] / spent)
    if len(vals) >= 30:
        sp = [r["spent"] for r in R if r["round"] == x]
        rows.append([x, len(vals), med(vals), mean(sp)])
W(table(["round", "players", "stats per gold spent (median)", "gold spent that round (mean)"], rows))

# Rank persistence
W("\n\n## 5. Does a lead persist? Correlation of a player's stats/lobby-median at round a with round b\n")
rel = {}
lob = collections.defaultdict(list)
for r in R:
    lob[(r["seed"], r["round"])].append(r)
for (s, x), rs in lob.items():
    m = statistics.median([y["stats"] for y in rs])
    for y in rs:
        rel[(s, y["seat"], x)] = y["stats"] / m if m else float("nan")


def corr(a, b):
    ma, mb = mean(a), mean(b)
    sa = math.sqrt(sum((x - ma) ** 2 for x in a))
    sb = math.sqrt(sum((x - mb) ** 2 for x in b))
    return sum((x - ma) * (y - mb) for x, y in zip(a, b)) / (sa * sb)


rows = []
for a, b in ((4, 6), (6, 8), (6, 10), (8, 10), (8, 12), (10, 12), (6, 12), (4, 12)):
    pa, pb = [], []
    for p in P:
        ka = (p["seed"], p["seat"], a)
        kb = (p["seed"], p["seat"], b)
        if ka in rel and kb in rel:
            pa.append(rel[ka])
            pb.append(rel[kb])
    rows.append(["R%d -> R%d" % (a, b), len(pa), corr(pa, pb)])
W(table(["rounds", "players", "correlation"], rows))
# predictive power of round-8 relative size for place
W("\nPlace by stats/lobby-median at round 8 (all 3,200 alive):\n")
rows = []
for lo, hi in ((0, .85), (.85, .95), (.95, 1.05), (1.05, 1.15), (1.15, 5)):
    ps = [p for p in P if lo <= rel[(p["seed"], p["seat"], 8)] < hi]
    rows.append(["%.2f-%.2f" % (lo, hi), len(ps), mean([p["place"] for p in ps]), "%.0f%%" % (100 * mean([p["place"] <= 4 for p in ps])),
                 "%.0f%%" % (100 * mean([p["place"] == 1 for p in ps]))])
W(table(["R8 stats / median", "players", "mean place", "top 4", "1st"], rows))

# winners' stats relative to their own lobby
W("\n\nEventual winner's board vs its lobby median, by round: " + ", ".join(
    "R%d %.2f" % (x, med([rel[(p["seed"], p["seat"], x)] for p in P if p["place"] == 1 and (p["seed"], p["seat"], x) in rel])) for x in (4, 6, 8, 10, 12, 14, 16)))
W("Eventual winner was the biggest board in its lobby: " + ", ".join(
    "R%d %.0f%%" % (x, 100 * mean([max(lob[(p["seed"], x)], key=lambda y: y["stats"])["seat"] == p["seat"] for p in P if p["place"] == 1])) for x in (4, 6, 8, 10, 12, 14)))

# chart data
cd = {"round": list(range(1, 24)),
      "all_median": [med([r["stats"] for r in series["everyone alive"].get(x, [])]) if series["everyone alive"].get(x) else None for x in range(1, 24)],
      "winners_median": [med([r["stats"] for r in series["eventual winners"].get(x, [])]) if series["eventual winners"].get(x) else None for x in range(1, 24)]}
json.dump(cd, open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/chart_stat_curve.json", "w"))
open("/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals/out_a4.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
