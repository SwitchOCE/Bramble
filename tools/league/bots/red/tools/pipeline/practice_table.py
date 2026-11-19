#!/usr/bin/env python3
"""Third pass (cards_p5.tsv): card_values_p4.py's method on ~1,400 games of the p2 bot (several runs with small
setting changes, pooled as one bot). Full-size steps where a card has 300+ fights (weighted), half-size below.
Games are streamed, not held in memory.

Signals (red's rows and blue's observable play only; reports.jsonl is never read):
 1. Fight model: every decided live fight, rounds 4-12, three bands; weighted ridge logistic regression
    P(A wins) ~ log(statsA/statsB) + tier diff + per-card copies diff. Card coefficient / stats coefficient
    = log stat multiplier, times the band's median board stats = effect in stat points ("fx").
 2. Mid-game placement: seats alive rounds 6-10, place ~ log stats + tier + round + cards (weighted ridge OLS).
 3. Buy rate when offered and buyable, rounds 3-10, red vs blue.
Plus a focus section on cards a reviewer doubted (brood-mother, gleaner), per run and red-only.
Usage: python3 card_values_p5.py <in tsv> <out tsv> <dir>:<weight> [<dir>:<weight> ...] > card_values_p5.txt"""
import json, sys, gzip, os, math, collections as C
import numpy as np

tsv_in, tsv_out = sys.argv[1], sys.argv[2]
RUNS = [(a.rsplit(':', 1)[0], float(a.rsplit(':', 1)[1])) for a in sys.argv[3:]]
FOCUS = ['brood-mother', 'gleaner']
lib = {c['id']: c for c in json.load(open(f"{RUNS[0][0]}/library.json"))}
hdr, rows = None, []
for i, l in enumerate(open(tsv_in)):
    f = l.rstrip('\n').split('\t')
    if i == 0: hdr = f
    else: rows.append(f)
T = {f[0]: f for f in rows}
cards = [f[0] for f in rows]
cidx = {c: i for i, c in enumerate(cards)}
K = len(cards)

def load(d):
    for l in open(f"{d}/games.jsonl"):
        try: yield json.loads(l)
        except json.JSONDecodeError: pass
class _Games:  # re-reads the file each time it is iterated, so games are never all in memory
    def __init__(self, d): self.d = d
    def __iter__(self): return load(self.d)
GAMES = [(d, w, _Games(d)) for d, w in RUNS]

def copies(board):
    v = np.zeros(K)
    for u in board:
        if u['card'] in cidx: v[cidx[u['card']]] += 2 if u['golden'] else 1
    return v

# ---------- 1. fights ----------
BANDS = [(4, 6), (7, 9), (10, 12)]
fights = {b: [] for b in BANDS}   # (logratio, tierdiff, cardvec diff, a_won, sA, sB, weight)
rvb = {b: [] for b in BANDS}      # red-v-blue: (red set, blue set, red won, weight, run)
for d, wt, games in GAMES:
    for g in games:
        col = {s['seat']: s['colour'] for s in g['seats']}
        brd = {(s['seat'], r['round']): r for s in g['seats'] for r in s['rounds']}
        for fr in g['fights']:
            band = next((b for b in BANDS if b[0] <= fr['round'] <= b[1]), None)
            if not band: continue
            for x in fr['fights']:
                a, b = x['a'], x['b']
                if b < 0 or x['winner'] is None: continue
                A, B = brd.get((a, fr['round'])), brd.get((b, fr['round']))
                if not A or not B or not A['board'] or not B['board']: continue
                sa, sb = A['board_attack'] + A['board_health'], B['board_attack'] + B['board_health']
                fights[band].append((math.log(sa / sb), A['tier'] - B['tier'], copies(A['board']) - copies(B['board']),
                                     x['winner'] == a, sa, sb, wt))
                if col[a] != col[b]:
                    red, blue = (A, B) if col[a] == 'red' else (B, A)
                    rw = x['winner'] == (a if col[a] == 'red' else b)
                    rvb[band].append(({u['card'] for u in red['board']}, {u['card'] for u in blue['board']}, rw, wt, d))

def ridge_logit(X, y, s, lam):
    w = np.zeros(X.shape[1]); pen = np.full(X.shape[1], lam); pen[:2] = 1e-3
    for _ in range(30):
        p = 1 / (1 + np.exp(-X @ w)); W = s * p * (1 - p)
        H = X.T @ (X * W[:, None]) + np.diag(pen)
        g = X.T @ (s * (y - p)) - pen * w
        w += np.linalg.solve(H, g)
    return w

fx, med = {}, {}
for band, F in fights.items():
    X = np.array([[f[0], f[1], *f[2]] for f in F]); y = np.array([float(f[3]) for f in F]); s = np.array([f[6] for f in F])
    X = np.vstack([X, -X]); y = np.concatenate([y, 1 - y]); s = np.concatenate([s, s])
    w = ridge_logit(X, y, s, lam=8.0)
    med[band] = float(np.median([f[4] for f in F] + [f[5] for f in F]))
    present = (np.abs(np.array([f[2] for f in F])) > 0)
    n = (present * np.array([f[6] for f in F])[:, None]).sum(0)   # weighted fight count
    for c in cards:
        k = cidx[c]
        fx.setdefault(c, {})[band] = ((math.exp(w[2 + k] / w[0]) - 1) * med[band], float(n[k]))
    print(f"band {band}: {len(F)} fights (weighted {sum(f[6] for f in F):.0f}), stats coef {w[0]:.2f}, tier coef {w[1]:.2f}, median stats {med[band]:.0f}")

def rvb_stats(c, band, run=None):
    F = [f for f in rvb[band] if run is None or f[4] == run]
    def m(sel):
        ws = sum(f[3] for f in sel); return (sum(f[3] * f[2] for f in sel) / ws if ws else float('nan'), ws)
    return m([f for f in F if c in f[0]]), m([f for f in F if c not in f[0]]), m([f for f in F if c in f[1]]), m([f for f in F if c not in f[1]])

# ---------- 2. mid-game placement ----------
P = []
for d, wt, games in GAMES:
    for g in games:
        for s_ in g['seats']:
            for r in s_['rounds']:
                if 6 <= r['round'] <= 10 and r['board']:
                    st = r['board_attack'] + r['board_health']
                    P.append(([math.log(st), r['tier'], r['round']], s_['place'], s_['colour'], copies(r['board']), {u['card'] for u in r['board']}, wt, d))
Xb = np.array([[1, *p[0], *(p[0][2] == k for k in (7, 8, 9, 10))] for p in P], float)
Xc = np.array([p[3] > 0 for p in P], float)
X = np.hstack([Xb, Xc]); y = np.array([p[1] for p in P], float); sw = np.array([p[5] for p in P])
pen = np.r_[np.full(Xb.shape[1], 1e-3), np.full(K, 30.0)]
wp = np.linalg.solve(X.T @ (X * sw[:, None]) + np.diag(pen), X.T @ (sw * y))
place_coef = {c: wp[Xb.shape[1] + cidx[c]] for c in cards}
place_n = {c: float((Xc[:, cidx[c]] * sw).sum()) for c in cards}
print(f"placement model: {len(P)} seat-rounds 6-10; places per unit log stats {wp[1]:.2f}, per tier {wp[2]:.2f}")

# ---------- 3. buy rates ----------
off = C.defaultdict(C.Counter); buy = C.defaultdict(C.Counter)
for d, wt, _ in GAMES:
    sp = f"{d}/shops.jsonl.gz"
    for l in (gzip.open(sp, "rt") if os.path.exists(sp) else open(f"{d}/shops.jsonl")):
        try: x = json.loads(l)
        except json.JSONDecodeError: continue
        if not 3 <= x['round'] <= 10: continue
        b = {o['index'] for o in x['bought'] if not o['spell']}
        for o in x['offers']:
            if o['spell'] or not o['buyable']: continue
            off[o['card']][x['colour']] += wt
            if o['index'] in b: buy[o['card']][x['colour']] += wt
def br(c, col): return (buy[c][col] / off[c][col] if off[c][col] else float('nan'), off[c][col])

# ---------- decide (p2 rule, then half-size steps) ----------
def decide(c):
    f = T[c]; power = float(f[1]); growth = float(f[2]); base = lib[c]['attack'] + lib[c]['health']
    cur_fx = power - base
    num = den = 0.0; ntot = 0.0
    for band, wt in zip(BANDS, (1.0, 2.0, 1.0)):
        e, n = fx[c][band]
        if n < 15: continue
        num += wt * n * e; den += wt * n; ntot += n
    parts, delta = [], 0.0
    if den:
        est = num / den; gap = est - cur_fx
        if growth >= 4 and gap < 0: gap *= 0.5
        delta += 0.6 * ntot / (ntot + 150) * gap
        parts.append(f"fight fx {est:+.0f} vs table {cur_fx:+.0f} (n={ntot:.0f})")
    pc, pn = place_coef[c], place_n[c]
    if pn >= 40:
        pts = max(-25, min(25, pc / wp[1] * med[(7, 9)]))
        delta += 0.4 * pn / (pn + 200) * pts
        parts.append(f"place coef {pc:+.2f} (n={pn:.0f})")
    rb, rn = br(c, 'red'); bb, bn = br(c, 'blue')
    if rn >= 50 and bn >= 50 and abs(bb - rb) >= 0.25 and delta * (bb - rb) > 0:
        delta += 4 * (bb - rb); parts.append(f"buy blue {100*bb:.0f}% red {100*rb:.0f}%")
    if ntot < 40: return 0, parts + ["n<40: no change"]
    (rw, rn2), (rwo, _), _, _ = rvb_stats(c, (7, 9))
    if rn2 >= 40 and (rw - rwo) * delta < 0 and abs(rw - rwo) > 0.05:
        delta *= 0.5; parts.append(f"halved: red raw win {100*rw:.0f}% with vs {100*rwo:.0f}% without (n={rn2:.0f})")
    # full step only when the placement model does not contradict the direction (|coef| < 0.1 counts as neutral)
    place_ok = pn < 40 or abs(pc) < 0.1 or (pc < 0) == (delta > 0)
    if ntot >= 300 and place_ok:                    # strong evidence: full-size step (p2 caps)
        cap = 15; raise_cap_low_tier = 10; floor = 3
    else:                                           # half-size step (p4 caps)
        delta *= 0.5; cap = 4 if ntot < 150 else 8; raise_cap_low_tier = 5; floor = 2
        parts.append("half step (n<300)" if ntot < 300 else "half step (placement disagrees)")
    if lib[c]['tier'] <= 2 and delta > 0: cap = min(cap, raise_cap_low_tier)
    delta = max(-cap, min(cap, delta))
    if abs(delta) < floor: return 0, parts
    return round(delta), parts

def keep_late_new(c):
    k = int(T[c][5]); e, n = fx[c][(10, 12)]
    if n >= 300 and e >= 25 and k < 3: return k + 1, f"late fight fx {e:+.0f} (n={n:.0f})"
    if n >= 300 and e <= -10 and k > 0: return k - 1, f"late fight fx {e:+.0f} (n={n:.0f})"
    return k, None

out = {c: decide(c) for c in cards}
# Overrides (p4 findings, re-checked on the pooled p2 runs in focus_check_p5.txt). From focus_check_p4.py (red-v-blue fights only, stats and tier held equal; focus_check_p4.txt):
#  brood-mother: worth less than its body in rounds 7-12 for both colours (p2swap red -38/-39 pts,
#    p1swap blue -34/-124); the pooled all-fights model's +14/+30 comes from same-colour fights. Take back
#    most of p2's +9 and block the keep_late raise.
#  gleaner: +35..+61 pts in rounds 4-9 for both colours, but ~0 for red and -43/-56 for blue in 10-12:
#    the p2 power holds (no further raise), keep_late 3 is too high.
# p5 re-check, pooled p2 runs (focus_check_p5.txt): brood-mother for red -11/-13/-54 pts by band (n 1354/3973/2357):
#   full step allowed now: 29 -> 17, keep_late 2 -> 1. Gleaner: +51/+43 red, +40/+39 blue in rounds 4-9;
#   -7 red / -28 blue in 10-12: power holds, keep_late 3 -> 2 (same as p4).
OVERRIDE = {'brood-mother': (-12, 1, "red-v-blue, stats held, pooled p2 runs: red -11/-13/-54 pts by band (n 1354/3973/2357)"),
            'gleaner': (0, 2, "red-v-blue, stats held, pooled p2 runs: +39..+51 in rounds 4-9, -7 (red) / -28 (blue) in 10-12: hold power, keep_late 3->2")}
OVERRIDE = {}  # the 19 Nov hand checks above apply to those cards only; empty for re-runs on changed cards
for c, (dl, kl, why) in OVERRIDE.items():
    out[c] = (dl, [why])
_kl = keep_late_new
def keep_late_new(c):
    if c in OVERRIDE: return OVERRIDE[c][1], f"override: {OVERRIDE[c][2]}" if OVERRIDE[c][1] != int(T[c][5]) else None
    return _kl(c)
print(f"\n{'card':26} t power base | fx 4-6 / 7-9 / 10-12 (pts, weighted n) | RvB 7-9 red-has win%/without n | place coef n | buy red/blue | delta")
for c in cards:
    f = T[c]; base = lib[c]['attack'] + lib[c]['health']
    (rw, rn), (rwo, _), _, _ = rvb_stats(c, (7, 9))
    fxs = " / ".join(f"{fx[c][b][0]:+5.0f} {fx[c][b][1]:5.0f}" for b in BANDS)
    rb, _ = br(c, 'red'); bb, _ = br(c, 'blue')
    print(f"{c:26} {lib[c]['tier']} {f[1]:>5} {base:4} | {fxs} | {100*rw:4.0f}/{100*rwo:3.0f} n{rn:5.0f} | {place_coef[c]:+.2f} {place_n[c]:5.0f} | {100*rb:4.0f}/{100*bb:4.0f} | {out[c][0]:+d}")

# ---------- focus: cards a reviewer doubted ----------
print("\nFocus (per run, unweighted): red-v-blue fights, red's win% with the card on red's board vs without, by band;"
      "\nred seats' final place with vs without it in rounds 6-10; fight-model fx from this run alone is in the pooled table above.")
for c in FOCUS:
    print(f"  {c} (table power {T[c][1]}, keep_late {T[c][5]})")
    for d, wt, games in GAMES:
        bands = []
        for band in BANDS:
            (rw, rn), (rwo, rno), (bw, bn), (bwo, _) = rvb_stats(c, band, d)
            bands.append(f"{band[0]}-{band[1]}: {100*rw:3.0f}% vs {100*rwo:3.0f}% (n {rn/wt:4.0f}); blue has it: red {100*bw:3.0f}% vs {100*bwo:3.0f}% (n {bn/wt:4.0f})")
        rp_w = [s_['place'] for g in games for s_ in g['seats'] if s_['colour'] == 'red'
                and any(6 <= r['round'] <= 10 and c in {u['card'] for u in r['board']} for r in s_['rounds'])]
        rp_wo = [s_['place'] for g in games for s_ in g['seats'] if s_['colour'] == 'red'
                 and not any(6 <= r['round'] <= 10 and c in {u['card'] for u in r['board']} for r in s_['rounds'])]
        print(f"    {os.path.basename(d):8} red place with {np.mean(rp_w) if rp_w else float('nan'):.2f} (n {len(rp_w)}) vs without {np.mean(rp_wo):.2f} (n {len(rp_wo)})")
        for b_ in bands: print(f"      {b_}")
    print(f"    pooled decision: {out[c][0]:+d}: " + "; ".join(out[c][1]))

with open(tsv_out, 'w') as o:
    o.write('\t'.join(hdr) + '\n')
    for f in rows:
        g = list(f); g[1] = str(int(round(float(f[1]) + out[f[0]][0]))); g[5] = str(keep_late_new(f[0])[0])
        o.write('\t'.join(g) + '\n')
print("\nChanges, biggest first:")
for c in sorted(cards, key=lambda c: -abs(out[c][0])):
    dl, parts = out[c]
    if dl: print(f"  {c:26} {T[c][1]:>4} -> {int(float(T[c][1]) + dl):4} ({dl:+d}): " + "; ".join(parts))
print("\nkeep_late changes:")
for c in cards:
    k, why = keep_late_new(c)
    if why: print(f"  {c:26} {T[c][5]} -> {k}: {why}")
