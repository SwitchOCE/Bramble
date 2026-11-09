"""Distribution lens: quantiles, 2x-median share, bimodality, concentration per line and round."""
import os, pickle, math
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
D = pickle.load(open(os.path.join(HERE, "boards.pkl"), "rb"))
rows = D["rows"]
LINES = ["line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court", "hard_field"]
PAPER12 = {"line_birds_homecoming": 615, "line_birds_tempo": 361, "line_fairies_ring": 530, "line_fairies_court": 945}
PAPER14 = {"line_birds_homecoming": 1275, "line_birds_tempo": 894, "line_fairies_ring": 1410, "line_fairies_court": 1325}


def q(a, p):
    return float(np.quantile(a, p))


def gmm_bic(x, k, iters=500):
    """EM for 1-D Gaussian mixture; returns (bic, params). Deterministic init by quantiles."""
    x = np.asarray(x, float)
    n = len(x)
    if k == 1:
        mu, sd = x.mean(), x.std() + 1e-9
        ll = np.sum(-0.5 * np.log(2 * np.pi * sd ** 2) - (x - mu) ** 2 / (2 * sd ** 2))
        return -2 * ll + 2 * math.log(n), [(1.0, mu, sd)]
    best = None
    for split in (0.5, 0.7, 0.85, 0.3):
        mus = np.array([np.quantile(x, split / 2), np.quantile(x, (1 + split) / 2)])
        sds = np.array([x.std(), x.std()]) / 2 + 1e-6
        w = np.array([0.5, 0.5])
        for _ in range(iters):
            dens = np.stack([w[j] / (sds[j] * np.sqrt(2 * np.pi)) * np.exp(-(x - mus[j]) ** 2 / (2 * sds[j] ** 2)) for j in range(2)])
            tot = dens.sum(0) + 1e-300
            resp = dens / tot
            nk = resp.sum(1) + 1e-12
            w = nk / n
            mus = (resp * x).sum(1) / nk
            sds = np.sqrt((resp * (x - mus[:, None]) ** 2).sum(1) / nk) + 1e-3
        ll = np.sum(np.log(tot))
        bic = -2 * ll + 5 * math.log(n)
        if best is None or bic < best[0]:
            best = (bic, sorted(zip(w.tolist(), mus.tolist(), sds.tolist()), key=lambda t: t[1]))
    return best


def sarle_bc(x):
    x = np.asarray(x, float)
    n = len(x)
    m = x.mean(); s = x.std(ddof=1)
    g = np.mean((x - m) ** 3) / x.std() ** 3
    kex = np.mean((x - m) ** 4) / x.std() ** 4 - 3
    return (g ** 2 + 1) / (kex + 3 * (n - 1) ** 2 / ((n - 2) * (n - 3)))


def kde_modes(x, bw=None, grid=400):
    x = np.asarray(x, float)
    if bw is None:
        bw = 1.06 * x.std() * len(x) ** (-0.2)
    g = np.linspace(x.min(), x.max(), grid)
    dens = np.exp(-((g[:, None] - x[None, :]) ** 2) / (2 * bw ** 2)).sum(1)
    peaks = [i for i in range(1, grid - 1) if dens[i] > dens[i - 1] and dens[i] >= dens[i + 1]]
    # keep peaks at least 10% of max height
    peaks = [i for i in peaks if dens[i] > 0.1 * dens.max()]
    return [round(float(np.exp(g[i]))) for i in peaks]


by = {}
for r in rows:
    by.setdefault((r["line"], r["round"]), []).append(r)

print("=== Pre-start board stats by line and round (survivors) ===")
print("line round n | p10 p25 p50 p75 p90 p99 max | p90/p50 p10/p50 | >=2x line-med | >=2x field-med | <=0.5x med | top-unit share med | Sarle BC(log) | GMM dBIC(1-2) | GMM comps (w, med)")
field_med = {}
for rnd in range(8, 15):
    allv = [r["stats"] for r in rows if r["round"] == rnd]
    field_med[rnd] = float(np.median(allv))
out = {}
for line in LINES:
    for rnd in range(8, 15):
        v = np.array([r["stats"] for r in by.get((line, rnd), [])], float)
        if len(v) == 0:
            continue
        med = np.median(v)
        ls = np.array([r["largest_share"] for r in by[(line, rnd)]], float)
        lv = np.log(np.maximum(v, 1))
        b1, _ = gmm_bic(lv, 1)
        b2, comps = gmm_bic(lv, 2)
        rec = dict(n=len(v), p10=q(v, .1), p25=q(v, .25), p50=med, p75=q(v, .75), p90=q(v, .9), p99=q(v, .99), mx=v.max(),
                   two=np.mean(v >= 2 * med), two_field=np.mean(v >= 2 * field_med[rnd]), half=np.mean(v <= 0.5 * med),
                   share=np.median(ls), bc=sarle_bc(lv), dbic=b1 - b2, comps=comps, modes=kde_modes(lv))
        out[(line, rnd)] = rec
        if rnd in (8, 10, 12, 14) or True:
            print(f"{line[5:] if line.startswith('line_') else line:18s} R{rnd:2d} {len(v):4d} | {rec['p10']:6.0f} {rec['p25']:6.0f} {med:6.0f} {rec['p75']:6.0f} {rec['p90']:6.0f} {rec['p99']:6.0f} {rec['mx']:6.0f} | "
                  f"{rec['p90']/med:4.2f} {rec['p10']/med:4.2f} | {rec['two']*100:5.1f}% | {rec['two_field']*100:5.1f}% | {rec['half']*100:5.1f}% | {rec['share']*100:4.1f}% | {rec['bc']:.3f} | {rec['dbic']:7.1f} | "
                  + "; ".join(f"{w:.2f}@{math.exp(m):.0f}" for w, m, s in comps) + f" | kde modes {rec['modes']}")
    print()

print("Field (all 8 seats) median by round:", {k: round(v) for k, v in field_med.items()})
print("\n=== Pooled all-seat share >= 2x pooled median (BG reference: 13-24% from turn 8) ===")
for rnd in range(8, 15):
    allv = np.array([r["stats"] for r in rows if r["round"] == rnd], float)
    com = np.array([r["stats"] for r in rows if r["round"] == rnd and r["line"] != "hard_field"], float)
    m = np.median(allv)
    ls = np.array([r["largest_share"] for r in rows if r["round"] == rnd], float)
    print(f"R{rnd}: n={len(allv)} med={m:.0f} p90={q(allv,.9):.0f} p90/med={q(allv,.9)/m:.2f} >=2x={np.mean(allv>=2*m)*100:.1f}%  committed-only >=2x own med={np.mean(com>=2*np.median(com))*100:.1f}%  biggest-unit share med={np.median(ls)*100:.1f}%")

print("\n=== R12 / R14 quantiles as a multiple of paper (survivors) ===")
for line in PAPER12:
    for rnd, P in ((12, PAPER12[line]), (14, PAPER14[line])):
        rec = out[(line, rnd)]
        v = np.array([r["stats"] for r in by[(line, rnd)]], float)
        print(f"{line[5:]:18s} R{rnd} paper {P:5d}: p50 {rec['p50']/P:.2f}x  p75 {rec['p75']/P:.2f}x  p90 {rec['p90']/P:.2f}x  p99 {rec['p99']/P:.2f}x  share at/above paper {np.mean(v>=P)*100:.1f}%  at/above 0.5x paper {np.mean(v>=0.5*P)*100:.1f}%")

print("\n=== Including eliminated seats (640 per line): share of all games ===")
for line in PAPER12:
    for rnd in (12, 14):
        v = np.array([r["stats"] for r in by[(line, rnd)]], float)
        P = PAPER12[line] if rnd == 12 else PAPER14[line]
        print(f"{line[5:]:18s} R{rnd}: alive {len(v)/640*100:.1f}%  alive & >=0.5x paper {np.sum(v>=0.5*P)/640*100:.1f}%  alive & >=paper {np.sum(v>=P)/640*100:.1f}%")

pickle.dump(out, open(os.path.join(HERE, "dist.pkl"), "wb"))
