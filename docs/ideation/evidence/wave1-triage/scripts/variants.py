"""Offer-rate estimates under supply variants, on each committed seat's real tier and refresh path.

Pool rules as in game_config.gd full_game(), all six tribes as in the run (tribes_per_lobby 0).
Depletion is ignored here (supply.py shows it moves P(seen) by 0-3 points). Estimates, not Godot.
Run: python3 -I variants.py <run_dir> <seat_labels.json.gz> <units_dir>
"""
import csv, glob, gzip, json, math, os, sys, collections, statistics

RUN, LABELS, UNITS = sys.argv[1], sys.argv[2], sys.argv[3]
HERE = os.path.dirname(os.path.abspath(__file__))
SLOTS = [4, 4, 4, 5, 5, 6]
ODDS = [[100], [50, 50], [20, 30, 50], [10, 15, 25, 50], [5, 10, 15, 25, 45], [5, 5, 10, 15, 25, 40]]

units = {}
for f in glob.glob(os.path.join(UNITS, "*.json")):
    d = json.load(open(f))
    if d.get("set") == "slice" and d.get("pool", True):
        units[d["id"]] = dict(tier=int(d["tier"]), tribe=(d.get("tribes") or ["neutral"])[0])
N6 = collections.Counter(u["tier"] for u in units.values())
F = collections.Counter((u["tribe"], u["tier"]) for u in units.values())
N5 = {t: N6[t] - F[("Hunters", t)] for t in range(1, 7)}  # one other tribe dropped (same shape for any)

KEYS = {"Fairies": {"old_moth_annis", "cluricaun", "fairy_monarch", "queen_of_elfland"},
        "Birds": {"mr_redbreast", "mrs_stork", "cuckoo"}}


def slot_p(card, T, n, double=False):
    t = units[card]["tier"]
    if t > T:
        return 0.0
    share = 2 / (n[t] + 1) if double else 1 / n[t]
    return ODDS[T - 1][t - 1] / 100 * share


def tribe_q(tribe, T, n):
    return sum(ODDS[T - 1][t - 1] / 100 * F[(tribe, t)] / n[t] for t in range(1, T + 1))


def p_fill(card, T, variant, rnd):
    tribe = units[card]["tribe"]
    S = SLOTS[T - 1]
    n = N5 if variant == "tribes5" else N6
    double = variant == "copies2" and card in KEYS[tribe]
    p = slot_p(card, T, n, double)
    guarantee_from = {"bg_r7": 7, "bg_r4": 4}.get(variant)
    if guarantee_from and rnd >= guarantee_from and T >= 2:
        q = tribe_q(tribe, T, n)
        r = p / q
        miss = sum(math.comb(S, k) * q ** k * (1 - q) ** (S - k) * (1 - r) ** max(k, 2) for k in range(S + 1))
        return 1 - miss
    return 1 - (1 - p) ** S


def kin_fill(card, T):
    """Ask for Kin: 2 slots from your tribe at the shop odds, the rest ordinary."""
    tribe = units[card]["tribe"]
    S = SLOTS[T - 1]
    p = slot_p(card, T, N6)
    r = p / tribe_q(tribe, T, N6)
    return 1 - (1 - r) ** min(2, S) * (1 - p) ** (S - min(2, S))


labels = {(r["seed"], r["seat"]): r["starting_line"] for r in json.load(gzip.open(LABELS))}
rounds = {}
for f in sorted(glob.glob(os.path.join(RUN, "chunk-*.rounds.csv"))):
    for r in csv.DictReader(open(f)):
        rounds[(int(r["seed"]), int(r["seat"]), int(r["round"]))] = (int(r["tier"]), int(r["paid_refreshes"]))

VARIANTS = ["base", "tribes5", "bg_r7", "bg_r4", "copies2", "kin_r4"]


def seen_by(seed, seat, card, R, variant):
    logq = 0.0
    for r in range(1, R + 1):
        if (seed, seat, r) not in rounds:
            break
        tier, refr = rounds[(seed, seat, r)]
        prev = rounds.get((seed, seat, r - 1), (1, 0))[0] if r > 1 else 1
        fills = [prev] + [tier] * refr
        v = "base" if variant == "kin_r4" else variant
        for T in fills:
            logq += math.log(max(1e-12, 1 - p_fill(card, T, v, r)))
        if variant == "kin_r4" and r >= 4 and tier >= 2:
            logq += math.log(max(1e-12, 1 - kin_fill(card, tier)))
    return 1 - math.exp(logq)


COMBOS = {
    "line_fairies_ring": [("old_moth_annis", 6), ("cluricaun", 9), ("fairy_monarch", 11)],
    "line_fairies_court": [("old_moth_annis", 6), ("cluricaun", 9), ("queen_of_elfland", 11)],
    "line_birds_homecoming": [("mr_redbreast", 6), ("mrs_stork", 9), ("cuckoo", 10)],
    "line_birds_tempo": [("mr_redbreast", 6), ("mrs_stork", 9), ("cuckoo", 10)],
}
cond = json.load(open(os.path.join(HERE, "condstats.json")))
out = {}
for line, combo in COMBOS.items():
    seats = [k for k, v in labels.items() if v == line]
    res = {}
    for v in VARIANTS:
        singles = {c: statistics.mean(seen_by(s, st, c, R, v) for s, st in seats) for c, R in combo}
        pair = statistics.mean(seen_by(s, st, combo[0][0], combo[0][1], v) * seen_by(s, st, combo[1][0], combo[1][1], v)
                               for s, st in seats)
        triple = statistics.mean(math.prod(seen_by(s, st, c, R, v) for c, R in combo) for s, st in seats)
        res[v] = dict(singles={f"{c}<=R{R}": round(singles[c], 3) for c, R in combo}, pair=round(pair, 3),
                      triple=round(triple, 3))
    out[line] = res
    print("\n==", line)
    print("  variant    " + "  ".join(f"{c[:10]}<=R{R}" for c, R in combo) + "   pair  triple   (P seen, mean over committed seats)")
    for v in VARIANTS:
        r = res[v]
        print(f"  {v:9s}  " + "  ".join(f"{x*100:13.0f}" for x in r["singles"].values()) + f"  {r['pair']*100:5.0f}  {r['triple']*100:5.0f}")
json.dump(out, open(os.path.join(HERE, "variants.json"), "w"), indent=1)

# per-fill table for key cards: base vs bg guarantee vs tribes5 at each shop tier
print("\nper-fill P(card shown), base / 5 tribes / BG guarantee (from R7)")
for c in ["old_moth_annis", "cluricaun", "cradle_fetch", "fairy_monarch", "mr_redbreast", "mrs_stork", "cuckoo"]:
    print(f"  {c:16s}", " ".join(f"T{T}:{p_fill(c,T,'base',9)*100:4.1f}/{p_fill(c,T,'tribes5',9)*100:4.1f}/{p_fill(c,T,'bg_r7',9)*100:4.1f}"
                               for T in range(units[c]['tier'], 7)))
print("\nP(a shop slot is your tribe) by shop tier:", " ".join(f"T{T}:{tribe_q('Fairies',T,N6)*100:.1f}%" for T in range(1, 7)))
