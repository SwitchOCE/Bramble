import sys, os, json, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fights import P, R, X, cases, run, scale_unit, fill, pair_cases

N_SEEDS = int(sys.argv[1]) if len(sys.argv) > 1 else 100
SEEDS = [1000 + 7919 * i for i in range(N_SEEDS)]
MULTS = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0]
N = None

mid_front = [P(6, 12)] * 4
mid_back = [P(5, 10)] * 2


def with_kw(board, kw, idx):
    return [(P(u["stats"]["set_attack"], u["stats"]["set_health"], kw) if i in idx and isinstance(u, dict) else u)
            for i, u in enumerate(board)]


S3 = mid_front + [X] + mid_back
S3_opp = mid_front + [{"def": "plain-brock"}] + mid_back

badger = [R("tourney-champion", 5), R("ironhide-berserker", 5), R("the-oakfeller", 5), R("gate-warden", 5),
          X, R("greatsword-bearer", 5), R("armsbearer", 5)]
locust = [R("orchard-stripper", 5), R("brood-mother", 5), R("famine-caller", 5), R("skin-shedder", 5),
          X, R("gleaner", 5), R("dirge-singer", 5)]
pigeon_sortie = [R("wing-commander", 5), R("flying-ace", 5), R("lieutenant", 5), R("home-guard", 5),
                 R("squadron-leader", 5), R("group-captain", 5), R("colour-ensign", 5)]

SCN = [
    ("1v1: Brock alone vs plain 8/20", {"a": [X, N, N, N, N, N, N], "b": "mirror"}),
    ("duo: one 6/12 in front, Brock behind", {"a": [P(6, 12), N, N, N, X, N, N], "b": "mirror"}),
    ("half board: two 8/16 in front, Brock behind", {"a": [P(8, 16), P(8, 16), N, N, X, N, N], "b": "mirror"}),
    ("full mid board, Brock in back (B1)", {"a": S3, "b": "mirror"}),
    ("full mid board, Brock in front (F2)", {"a": [P(6, 12), X, P(6, 12), P(6, 12)] + [P(5, 10)] * 3, "b": "mirror"}),
    ("swarm: 2/3 units, Brock behind", {"a": [P(2, 3)] * 4 + [X] + [P(2, 3)] * 2, "b": "mirror"}),
    ("late big board: 20/40 front, 15/30 back", {"a": [P(20, 40)] * 4 + [X] + [P(15, 30)] * 2, "b": "mirror"}),
    ("vs Guard walls (opponent F2, F3 are 4/24 Guards)",
     {"a": S3, "b": [P(6, 12), P(4, 24, ["taunt"]), P(4, 24, ["taunt"]), P(6, 12), {"def": "plain-brock"}] + mid_back}),
    ("vs Sortie (opponent front row hits the back row)", {"a": S3, "b": with_kw(S3_opp, ["pigeon_sortie"], {0, 1, 2, 3})}),
    ("vs Cleave (opponent front row has Cleave)", {"a": S3, "b": with_kw(S3_opp, ["cleave"], {0, 1, 2, 3})}),
    ("real Badger board (+5/+5 each), Brock in B1", {"a": badger, "b": "mirror"}),
    ("real Locust death board (+5/+5 each), Brock in B1", {"a": locust, "b": "mirror"}),
    ("real Badger board vs real Pigeon Sortie board", {"a": badger, "b": pigeon_sortie}),
]
GOLD = ("full mid board, golden Brock vs golden plain 16/40", {"a": S3, "b": "gmirror"})


POOL = [0.7, 0.8, 0.9, 1.0, 1.1, 1.25, 1.4, 1.6, 1.8, 2.0, 2.5]
H2H_SEEDS = SEEDS[:50]
POOL_SEEDS = SEEDS[:20]


def crossing(target, curve):
    """Multiplier where curve (m, score), rising in m, reaches target (linear interpolation)."""
    prev = None
    for m, s in curve:
        if s >= target:
            if prev is None:
                return m if s == target else None  # already above at the lowest m
            pm, ps = prev
            return pm + (m - pm) * (target - ps) / (s - ps) if s != ps else m
        prev = (m, s)
    return float("inf")


def fmt(x):
    if x is None:
        return "<x1"
    if x == float("inf"):
        return f">x{MULTS[-1]:g}"
    return f"x{x:.2f}"


def pool_score(board_mine, opp_board):
    tot, n, e = 0.0, 0, 0
    for f in POOL:
        opp = [scale_unit(u, f) for u in opp_board]
        s, k, err = run(pair_cases(board_mine, opp, POOL_SEEDS), "pool")
        tot += s * k
        n += k
        e += err
    return tot / n, n, e


results = []
t0 = time.time()
for i, (name, scn) in enumerate(SCN + [GOLD]):
    gold = scn["b"] == "gmirror"
    vb = ("gbrock", 1) if gold else ("brock", 1)
    vp = "gplain" if gold else "plain"
    opp = scn["b"]
    if opp in ("mirror", "gmirror"):
        opp = fill(scn["a"], (vp, 1.0))
    brock_board = fill(scn["a"], vb)
    # 1. With and without: Brock's board against the same board with a plain 8/20 (or 16/40) there.
    plain1 = fill(scn["a"], (vp, 1.0))
    ww, n_ww, e1 = run(pair_cases(brock_board, plain1 if scn["b"] in ("mirror", "gmirror") else opp, H2H_SEEDS), "ww")
    pw, _, _ = run(pair_cases(plain1, opp, H2H_SEEDS), "pw")
    # 2. Head to head: Brock's board against the same board with a plain unit of m x stats.
    h2h = []
    for m in MULTS:
        s, _, e = run(pair_cases(brock_board, fill(scn["a"], (vp, m)), H2H_SEEDS), "h2h")
        h2h.append((m, 1 - s))  # the plain board's score: rises with m
    h2h_even = crossing(0.5, h2h)
    # 3. Pool: average score against the opponent board scaled 0.7x..2.5x.
    bp, n_pool, e3 = pool_score(brock_board, opp)
    pcurve = []
    for m in MULTS:
        s, _, _ = pool_score(fill(scn["a"], (vp, m)), opp)
        pcurve.append((m, s))
    pool_even = crossing(bp, pcurve)
    row = {"scenario": name, "brock_vs_opp": round(ww, 3), "plain_vs_opp": round(pw, 3), "fights_each": n_ww,
           "h2h_plain_score_by_mult": [(m, round(s, 3)) for m, s in h2h], "h2h_even": h2h_even,
           "pool_brock": round(bp, 3), "pool_plain_by_mult": [(m, round(s, 3)) for m, s in pcurve],
           "pool_even": pool_even, "pool_fights_each": n_pool, "errors": e1 + e3}
    results.append(row)
    print(f"{name:52s} | vs opp: Brock {ww:4.0%} plain {pw:4.0%} | h2h even {fmt(h2h_even):>6s} | "
          f"pool Brock {bp:4.0%} plain1 {pcurve[0][1]:4.0%} even {fmt(pool_even):>6s} | err {e1 + e3}", flush=True)
print(f"elapsed {time.time() - t0:.0f}s")
json.dump(results, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "costing_results.json"), "w"), indent=1, default=str)
