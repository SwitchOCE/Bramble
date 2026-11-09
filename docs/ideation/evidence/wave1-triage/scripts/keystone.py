"""Link between board size and engine pieces / tier-6 timing, per line, at R12 and R14."""
import os, pickle
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
D = pickle.load(open(os.path.join(HERE, "boards.pkl"), "rb"))
rows = D["rows"]
PAPER = {12: {"line_birds_homecoming": 615, "line_birds_tempo": 361, "line_fairies_ring": 530, "line_fairies_court": 945},
         14: {"line_birds_homecoming": 1275, "line_birds_tempo": 894, "line_fairies_ring": 1410, "line_fairies_court": 1325}}
BIRD_KEYS = ["mrs_stork", "cuckoo", "great_lump", "mother_goose", "mr_redbreast", "gabble_ratchet", "seven_whistlers", "jack_daw"]
FAIRY_KEYS = ["old_moth_annis", "cluricaun", "lob_lie_by_the_fire", "silky", "fairy_monarch", "queen_of_elfland", "cradle_fetch", "reel_mistress"]

idx = {(r["seed"], r["seat"], r["round"]): r for r in rows}


def med(v):
    return float(np.median(v)) if len(v) else float("nan")


def spearman(a, b):
    a = np.argsort(np.argsort(a)); b = np.argsort(np.argsort(b))
    return float(np.corrcoef(a, b)[0, 1])


def seen_by(r, key, upto):
    """unit owned (any location) at any captured round 8..upto for this seat"""
    for rr in range(8, upto + 1):
        x = idx.get((r["seed"], r["seat"], rr))
        if x and key in x["owned"]:
            return True
    return False


def report(line, rnd, keys):
    rs = [r for r in rows if r["line"] == line and r["round"] == rnd]
    v = np.array([r["stats"] for r in rs], float)
    m = np.median(v)
    big = v >= 2 * m
    P = PAPER[rnd][line]
    print(f"\n### {line} R{rnd}: n={len(rs)} median={m:.0f} paper={P}  (>=2x median: {big.sum()} boards)")
    print(f"{'piece':22s} {'on-board%':>9s} {'owned%':>7s} | {'med with(owned)':>15s} {'med without':>11s} {'ratio':>5s} | {'% of >=2x boards owning':>23s}")
    for k in keys:
        on = np.array([k in r["onboard"] for r in rs])
        ow = np.array([k in r["owned"] for r in rs])
        print(f"{k:22s} {on.mean()*100:8.1f}% {ow.mean()*100:6.1f}% | {med(v[ow]):15.0f} {med(v[~ow]):11.0f} {med(v[ow])/max(med(v[~ow]),1):5.2f} | {ow[big].mean()*100 if big.any() else float('nan'):22.1f}%")
    cnt = np.array([sum(k in r["owned"] for k in keys[:6]) for r in rs])
    print("engine pieces owned (first 6 keys) -> n, median, median/paper, share >=2x line median")
    for c in range(0, 7):
        sel = cnt == c
        if sel.sum() >= 5:
            print(f"   {c}: n={sel.sum():4d} ({sel.mean()*100:4.1f}%) median={med(v[sel]):6.0f} ({med(v[sel])/P:.2f}x paper)  p90={np.quantile(v[sel],.9):6.0f}  >=2x={np.mean(v[sel]>=2*m)*100:5.1f}%")
    print(f"   spearman(stats, pieces owned) = {spearman(v, cnt):.3f}")
    # tier 6 timing
    t6 = np.array([r["p_tier6_turn"] if r["p_tier6_turn"] else 99 for r in rs])
    print("tier-6 turn -> n, median, share >=2x")
    for lo, hi, lab in ((0, 9, "<=9"), (10, 10, "10"), (11, 11, "11"), (12, 12, "12"), (13, 98, "13+"), (99, 99, "never/0")):
        sel = (t6 >= lo) & (t6 <= hi)
        if sel.sum() >= 5:
            print(f"   T6 {lab:7s}: n={sel.sum():4d} ({sel.mean()*100:4.1f}%) median={med(v[sel]):6.0f} ({med(v[sel])/P:.2f}x paper) p90={np.quantile(v[sel],.9):6.0f}  >=2x={np.mean(v[sel]>=2*m)*100:5.1f}%")
    tiers = np.array([r["tier"] for r in rs])
    print("   tier at this round:", {int(t): int((tiers == t).sum()) for t in np.unique(tiers)})
    print(f"   spearman(stats, -tier6_turn) = {spearman(v, -t6):.3f}; spearman(stats, gold_spent) = {spearman(v, np.array([r['gold_spent'] for r in rs])):.3f}")
    return rs, v


for rnd in (12, 14):
    for line in ("line_birds_homecoming", "line_birds_tempo"):
        rs, v = report(line, rnd, BIRD_KEYS)
        hc = np.array([r["homecomings"] or 0 for r in rs])
        gb = np.array([r["golden_board"] for r in rs])
        print(f"   spearman(stats, homecomings field)={spearman(v, hc):.3f}; median homecomings={np.median(hc)}; golden units on board: share>0 {np.mean(gb>0)*100:.1f}%, med with {med(v[gb>0]):.0f} vs without {med(v[gb==0]):.0f}")
        mu = np.array([r["max_unit"] for r in rs])
        print(f"   biggest unit median {np.median(mu):.0f}; p90 {np.quantile(mu,.9):.0f}; spearman(stats,max_unit)={spearman(v,mu):.3f}")
    for line in ("line_fairies_ring", "line_fairies_court"):
        rs, v = report(line, rnd, FAIRY_KEYS)
        rsz = np.array([r["ring_size"] or 0 for r in rs]); rg = np.array([r["rings"] for r in rs])
        prod = rsz * rg
        print(f"   ring size quantiles p10/50/90: {np.quantile(rsz,[.1,.5,.9]).tolist()}  rings p10/50/90: {np.quantile(rg,[.1,.5,.9]).tolist()}")
        print(f"   spearman(stats, ring_size)={spearman(v, rsz):.3f}  spearman(stats, rings)={spearman(v, rg):.3f}  spearman(stats, size*rings)={spearman(v, prod):.3f}")
        for s in sorted(set(rsz.tolist())):
            sel = rsz == s
            if sel.sum() >= 5:
                print(f"   ring size {s:4.0f}: n={sel.sum():4d} ({sel.mean()*100:4.1f}%) median stats={med(v[sel]):6.0f} ({med(v[sel])/PAPER[rnd][line]:.2f}x paper)  median rings={np.median(rg[sel]):.0f}  >=2x={np.mean(v[sel]>=2*np.median(v))*100:5.1f}%")
        gb = np.array([r["golden_board"] for r in rs])
        print(f"   golden on board share {np.mean(gb>0)*100:.1f}%: median with {med(v[gb>0]):.0f} vs without {med(v[gb==0]):.0f}")
