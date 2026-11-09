"""Within-seat compounding: per-seat growth rates, their distribution, persistence of rank, and paper homecomings."""
import os, pickle, json, math
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
D = pickle.load(open(os.path.join(HERE, "boards.pkl"), "rb"))
rows = D["rows"]
idx = {(r["seed"], r["seat"], r["round"]): r for r in rows}
LINES = ["line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court", "hard_field"]


def spearman(a, b):
    a = np.argsort(np.argsort(a)); b = np.argsort(np.argsort(b))
    return float(np.corrcoef(a, b)[0, 1])


def sarle_bc(x):
    x = np.asarray(x, float); n = len(x); m = x.mean()
    g = np.mean((x - m) ** 3) / x.std() ** 3
    kex = np.mean((x - m) ** 4) / x.std() ** 4 - 3
    return (g ** 2 + 1) / (kex + 3 * (n - 1) ** 2 / ((n - 2) * (n - 3)))


def hist(x, edges):
    h, _ = np.histogram(x, edges)
    return " ".join(f"{e:.2f}:{c}" for e, c in zip(edges[:-1], h))


print("Per-seat geometric growth a round (pre-start stats), seats alive at both ends")
for a, b in ((8, 12), (10, 14), (8, 14)):
    print(f"\n-- R{a} -> R{b} --")
    for line in LINES:
        seats = [(r["seed"], r["seat"]) for r in rows if r["line"] == line and r["round"] == b]
        g = []
        s0 = []; s1 = []
        for k in seats:
            x0 = idx.get((k[0], k[1], a)); x1 = idx[(k[0], k[1], b)]
            if x0 and x0["stats"] > 0:
                g.append((x1["stats"] / x0["stats"]) ** (1 / (b - a)))
                s0.append(x0["stats"]); s1.append(x1["stats"])
        g = np.array(g)
        print(f"{line:22s} n={len(g):4d} growth p10 {np.quantile(g,.1):.3f} p25 {np.quantile(g,.25):.3f} p50 {np.median(g):.3f} p75 {np.quantile(g,.75):.3f} p90 {np.quantile(g,.9):.3f} | share >=1.5 {np.mean(g>=1.5)*100:4.1f}%  >=1.3 {np.mean(g>=1.3)*100:4.1f}%  <1.15 {np.mean(g<1.15)*100:4.1f}% | BC {sarle_bc(np.log(g)):.3f} | rank corr start/end {spearman(np.array(s0),np.array(s1)):.3f} | rank corr start/growth {spearman(np.array(s0),g):.3f}")
        if (a, b) == (8, 14) or (a, b) == (10, 14):
            print("      hist:", hist(g, np.array([0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.8, 2.2, 3.5])))

print("\nTop-decile persistence: of seats in their line's top 10% at R10, share still top 10% at R14 (survivors at R14)")
for line in LINES:
    r10 = {(r["seed"], r["seat"]): r["stats"] for r in rows if r["line"] == line and r["round"] == 10}
    r14 = {(r["seed"], r["seat"]): r["stats"] for r in rows if r["line"] == line and r["round"] == 14}
    both = [k for k in r14 if k in r10]
    v10 = np.array([r10[k] for k in both]); v14 = np.array([r14[k] for k in both])
    t10 = v10 >= np.quantile(v10, .9); t14 = v14 >= np.quantile(v14, .9)
    print(f"{line:22s} n={len(both)} P(top10 R14 | top10 R10)={np.mean(t14[t10])*100:.1f}% (chance 10%)  P(top10 R14 | bottom half R10)={np.mean(t14[v10<=np.median(v10)])*100:.1f}%")

# paper homecomings vs real
P = json.load(open("/home/alex/code/Bramble-ideation-sol/tools/sim/evidence/wave1-accounting-paper.json"))
def find(d, path=""):
    if isinstance(d, dict):
        for k, v in d.items():
            if k == "homecomings_this_round":
                yield path, v
            else:
                yield from find(v, path + "/" + str(k))
print("\nPaper homecomings_this_round (authored):")
for p, v in find(P):
    if "birds" in p:
        print("  ", p, v)
print("\nReal 'homecomings' field per round, birds_homecoming (mean, median, share 0):")
for rnd in range(8, 15):
    hc = np.array([r["homecomings"] or 0 for r in rows if r["line"] == "line_birds_homecoming" and r["round"] == rnd])
    hc2 = np.array([r["homecomings"] or 0 for r in rows if r["line"] == "line_birds_tempo" and r["round"] == rnd])
    print(f"  R{rnd}: homecoming mean {hc.mean():.2f} med {np.median(hc):.0f} zero {np.mean(hc==0)*100:.0f}% | tempo mean {hc2.mean():.2f}")
