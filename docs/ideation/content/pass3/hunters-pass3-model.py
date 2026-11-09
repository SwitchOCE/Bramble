"""Hunters pass 3 synthesis (hunters-pass3.md): a fought growth model. Paper and Python only; no Godot.

Run:  python3 -I hunters-pass3-model.py            (everything, about a minute)
      python3 -I hunters-pass3-model.py quick      (main lines only)

Rules as modelled (the synthesis defaults): trophies read the quarry's stats at the bell, floor, at
least +1/+1, and land AFTER the fight (OPT midfight=False); the Laird doubles 'Take:' text and grants
no Quarry (OPT laird_grant=False); joins never cleave and the Glutton has no Cleave; Isegrim has no
Health cut. Every one of these is a switch, and the main run prints the alternatives.

What it does, and how it differs from the three designers' models:
- Growth comes from fights. Each round, the line's board (as it stands BEFORE the fight) fights a
  sample of field boards; every trophy, Pelt and poached copy is what those fights produced, averaged.
  So Take rates fall when the board is behind and rise when it is ahead (the breaker's probe 1), and
  boards are reported as they fight, not after their own fight (the breaker's off-by-one finding).
- The combat engine extends the breaker's probe (hunters-breaker-probe.py), which reproduces the
  audit's carry test. Rulebook ch. 9: reading order, pointer and flags, back-row protection,
  random targets, simultaneous exchange. Added for this design:
    Quarry marks at the bell (own text, then lent hunts in reading order, then the Laird's grant);
    Take (quarry dies while the marker is on the board, or in the same exchange; first marker in
    reading order); trophies read the bell snapshot, floor, at least +1/+1, and land after the fight
    even if the unit fainted (or at once, with midfight=True); Sable; Pack joins (Brother Wolf joins both);
    Agnes (pack leaders take half the hit back); Grizel (pack kills feed every attacker); Wick;
    the Glutton (after each Take); the Lodger (after a unit beside him makes a Take); Ermeline's
    Pelt (a quarter of the biggest quarry, after the fight); Russet's poached copy (base + half the
    quarry's permanent buffs; reported, not bought); the Laird ('Take:' text twice); Old Brock (units next
    to him hunt the enemy across from him, any row); Isegrim (he and units beside him hunt the
    biggest enemy, any row; optional Health cut); Cleave with or without joins (for the ablation).
- Field boards are plain stat sticks with no text: size = target median x lognormal(0, 0.45);
  half Battlegrounds-shaped (a carry of a third, in the back row 3 times in 4), half random spread.
  The target: today's bots to R6, 70 at R7, then x1.5 a round (158 / 531 / 1,793 at R9 / 12 / 15),
  the breaker's numbers. Strong = 1.35 x median (717 at R12).
Limits: scripted arrivals stand in for the shop; no gold except Russet's copy; no heroes, spells
(except Harvest Supper +1/+1 at R7, R9, R11) or neutrals; field boards never adapt to Hunters.
"""
import math, random, sys

FRONT = (0, 1, 2, 3)
ADJ = ((1,), (0, 2), (1, 3), (2,), (5,), (4, 6), (5,))
BEHIND = {0: (4,), 1: (4, 5), 2: (5, 6), 3: (6,)}
INFRONT = {4: (0, 1), 5: (1, 2), 6: (2, 3)}
def nextto(s): return ADJ[s] + BEHIND.get(s, ()) + INFRONT.get(s, ())
SLOTS = {"F1": 0, "F2": 1, "F3": 2, "F4": 3, "B1": 4, "B2": 5, "B3": 6}

OPT = {"join_cleave": False, "midfight": False, "laird_grant": False, "buffs_base": None}

# ------------------------------------------------------------------ the field
E = {1: 5, 2: 10, 3: 17, 4: 26, 5: 37, 6: 50, 7: 70}
for _r in range(8, 18): E[_r] = E[_r - 1] * 1.5
NU = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6}
def nu(r): return NU.get(r, 7)
SIGMA = 0.45

def split(total, af):
    a = max(1, round(total * af)); return a, max(1, round(total - a))

def field_board(r, rng, scale=1.0, sigma=SIGMA, shape=None):
    T = E[r] * scale * math.exp(rng.gauss(0, sigma))
    n = nu(r)
    b = [None] * 7
    shape = shape or ("bg" if (r >= 7 and rng.random() < 0.5) else "rand")
    if shape == "bg" and n == 7:
        c = T / 3; o = (T - c) / 6
        cs = rng.choice((4, 5, 6)) if rng.random() < 0.75 else rng.choice(FRONT)
        for i in range(7):
            b[i] = split(c if i == cs else o, 0.45)
        return b
    w = [math.exp(rng.gauss(0, 0.35)) for _ in range(n)]
    z = sum(w)
    order = [0, 1, 2, 3, 4, 5, 6][:n]
    for i, x in zip(order, w):
        b[i] = split(T * x / z, rng.uniform(0.38, 0.52))
    return b

def even(total, n=7, af=0.45):
    a, h = split(total / n, af); return [(a, h)] * n

def bgshape(T, carry_slot=5):
    c = T / 3; o = (T - c) / 6
    return [split(c if i == carry_slot else o, 0.45) for i in range(7)]

# ------------------------------------------------------------------ combat
class CU:
    __slots__ = ("name", "a", "h", "slot", "kw", "flag", "joined", "led", "shield", "quarry", "reach", "sa", "sh", "side", "ta", "th")
    def __init__(s, name, a, h, slot, kw, side):
        s.name, s.a, s.h, s.slot, s.kw, s.side = name, a, h, slot, kw, side
        s.flag = False; s.joined = set(); s.led = False
        s.shield = bool(kw.get("shield")); s.quarry = None; s.reach = False
        s.sa, s.sh = a, h
        s.ta, s.th = a, h

def mk_side(board, side):
    out = {}
    for i, u in enumerate(board):
        if u is None: continue
        if isinstance(u, tuple):
            out[i] = CU(f"e{i}", u[0], u[1], i, {}, side)
        else:
            out[i] = CU(u["name"], int(round(u["a"])), int(round(u["h"])), i, u["kw"], side)
    return out

def tro(share, sa, sh):
    return (max(1, int(share * sa)), max(1, int(share * sh)))

def fight(b0, b1, rng):
    S = [mk_side(b0, 0), mk_side(b1, 1)]
    st = [{"takes": 0, "gains": {}, "pelt": None, "poach": [], "carry_take": 0, "packkills": 0} for _ in (0, 1)]

    def alive(u): return S[u.side].get(u.slot) is u

    def give(u, g):
        d = st[u.side]["gains"].setdefault(u.name, [0, 0])
        d[0] += g[0]; d[1] += g[1]
        if OPT["midfight"] and alive(u):
            u.a += g[0]; u.h += g[1]

    # the bell: snapshot, then marks
    bb = OPT["buffs_base"]
    for s in (0, 1):
        for u in S[s].values():
            u.sa, u.sh = u.a, u.h
            if bb and u.name.startswith("e"):
                u.ta, u.th = max(0, u.a - bb[0]), max(0, u.h - bb[1])
            else:
                u.ta, u.th = u.a, u.h
    biggest = [None, None]
    for s in (0, 1):
        en = S[1 - s]
        if en:
            biggest[s] = max(en.values(), key=lambda v: (v.a + v.h, -v.slot))
        units = [S[s][k] for k in sorted(S[s])]
        for u in units:                                   # 1. own text
            if u.kw.get("biggest") and biggest[s] is not None:
                u.quarry, u.reach = biggest[s], True
            elif u.kw.get("quarry") and u.slot in en:
                u.quarry, u.reach = en[u.slot], bool(u.kw.get("reach"))
        for u in units:                                   # 2. lent hunts, reading order
            if u.kw.get("gang") and u.quarry is not None:
                for k in ADJ[u.slot]:
                    v = S[s].get(k)
                    if v is not None and v.quarry is None:
                        v.quarry, v.reach = u.quarry, True
            if u.kw.get("brock") and u.slot in en:
                tgt = en[u.slot]
                for k in nextto(u.slot):
                    v = S[s].get(k)
                    if v is not None and v.quarry is None:
                        v.quarry, v.reach = tgt, True
        if OPT["laird_grant"] and any(u.kw.get("laird") for u in units):          # 3. the Laird's grant
            for u in units:
                if u.quarry is None and u.slot in en:
                    u.quarry = en[u.slot]
        qs = [u.quarry for u in units if u.quarry is not None]
        if qs:
            q = max(qs, key=lambda v: v.sa + v.sh)
            st[s]["pelt"] = (q.sa, q.sh)
    # Start of Combat
    for s in (0, 1):
        for u in S[s].values():
            if u.kw.get("cut") and u.quarry is not None:
                u.quarry.h -= int(u.kw["cut"] * u.quarry.h)
            if u.kw.get("sable") and u.quarry is not None:
                u.a += int(u.kw["sable"] * u.quarry.a)

    def laird_mult(s):
        m = 1
        for u in S[s].values():
            if u.kw.get("laird"): m = max(m, u.kw["laird"])
        return m

    def fire_take(o, m, q):
        st[o]["takes"] += 1
        if biggest[o] is q: st[o]["carry_take"] += 1
        lm = laird_mult(o)
        if m.kw.get("take"):
            g = tro(m.kw["take"], q.ta, q.th); give(m, (g[0] * lm, g[1] * lm))
        if m.kw.get("russet"):
            st[o]["poach"].extend([(q.sa, q.sh)] * lm)
        for x in list(S[o].values()):
            if x.kw.get("glutton"):
                give(x, tro(x.kw["glutton"], q.ta, q.th))
            if x.kw.get("lodger") and x is not m and m.slot in ADJ[x.slot]:
                give(x, tro(x.kw["lodger"], q.ta, q.th))

    def deaths(before):
        dead_all = []
        for s in (0, 1):
            dead = [u for u in list(S[s].values()) if u.h <= 0]
            for u in dead:
                del S[s][u.slot]
            dead_all.append(dead)
        for s in (0, 1):
            o = 1 - s
            for u in dead_all[s]:
                for m in before[o]:
                    if m.quarry is u:
                        fire_take(o, m, u)
                        break
        return dead_all

    def hit(t, amt):
        if amt <= 0: return
        if t.shield:
            t.shield = False; return
        t.h -= amt

    def legal(s, tgt, att):
        en = S[1 - s]
        if S[1 - s].get(tgt.slot) is not tgt: return False
        if att.reach: return True
        return (tgt.slot in FRONT) or not any(k in FRONT for k in en)

    def choose(s):
        units = [S[s][k] for k in sorted(S[s])]
        ready = [u for u in units if u.a > 0]
        if not ready: return None
        cand = [u for u in ready if not u.flag]
        if not cand:
            for u in units:
                u.flag = False; u.joined = set(); u.led = False
            cand = ready
        for u in cand:
            if u.kw.get("waits") and len(cand) > 1:
                partner = any((k in S[s]) and S[s][k].a > 0 and not S[s][k].flag for k in ADJ[u.slot])
                if partner: continue
            return u
        return cand[0]

    def target(s, att):
        if att.quarry is not None and legal(s, att.quarry, att): return att.quarry
        en = S[1 - s]
        front = [en[k] for k in sorted(en) if k in FRONT]
        c = front if front else [en[k] for k in sorted(en)]
        return c[rng.randrange(len(c))] if c else None

    n0, n1 = len(S[0]), len(S[1])
    active = 0 if n0 > n1 else 1 if n1 > n0 else rng.randint(0, 1)
    attacks = 0; last = -1
    while S[0] and S[1]:
        if attacks >= 200: return -1, st
        if not any(u.a > 0 for u in S[0].values()) and not any(u.a > 0 for u in S[1].values()):
            return -1, st
        att = choose(active)
        if att is not None:
            attacks += 1
            t = target(active, att)
            if t is not None:
                before = [[S[0][k] for k in sorted(S[0])], [S[1][k] for k in sorted(S[1])]]
                joiners = []
                for k in ADJ[att.slot]:
                    j = S[active].get(k)
                    if j is None or j is att or not j.kw.get("pack") or j.a <= 0 or j.led: continue
                    if (not j.flag) or (j.kw.get("both") and j.joined and att.slot not in j.joined):
                        joiners.append(j)
                for u in S[active].values():
                    if u.slot <= att.slot: u.flag = True
                att.led = True
                back = t.a
                hit(t, att.a)
                if att.kw.get("cleave"):
                    for k in ADJ[t.slot]:
                        v = S[1 - active].get(k)
                        if v: hit(v, att.a // att.kw.get("cleave_div", 1))
                for j in joiners:
                    j.flag = True; j.joined.add(att.slot)
                    hit(t, j.a)
                    if j.kw.get("cleave") and OPT["join_cleave"]:
                        for k in ADJ[t.slot]:
                            v = S[1 - active].get(k)
                            if v: hit(v, j.a // j.kw.get("cleave_div", 1))
                if joiners:
                    ag = [u.kw["agnes"] for u in S[active].values() if u.kw.get("agnes")]
                    if ag: back = int(back * min(ag))
                hit(att, back)
                last = active
                deaths(before)
                if S[1 - active].get(t.slot) is not t and joiners:
                    st[active]["packkills"] += 1
                    gz = [u.kw["grizel"] for u in S[active].values() if u.kw.get("grizel")]
                    for u in [att] + joiners:
                        if gz: give(u, tro(max(gz), t.ta, t.th))
                    for j in joiners:
                        if j.kw.get("wick"): give(j, tro(j.kw["wick"], t.ta, t.th))
        active = 1 - active
    if S[0] and not S[1]: return 0, st
    if S[1] and not S[0]: return 1, st
    return last, st

def match(b0, b1, n=600, seed=3):
    rng = random.Random(seed); w = 0
    for i in range(n):
        if i % 2 == 0:
            r, _ = fight(b0, b1, rng); w += (r == 0)
        else:
            r, _ = fight(b1, b0, rng); w += (r == 1)
    return w / n

# ------------------------------------------------------------------ cards (pass 3 synthesis)
S_DEFAULT = 0.5
def cards(s=S_DEFAULT, sable=1.0, lodger=None, glutton=None, cleave=False, cut=0.0, agnes=0.5, grizel=None, wick=None, nip=None, laird=2):
    q = s / 2
    return {
        "nip":          (2, 2, {"quarry": 1, "take": nip if nip is not None else s}),
        "wick":         (2, 2, {"pack": 1, "wick": wick if wick is not None else q}),
        "young_brock":  (2, 3, {}),
        "sable":        (2, 3, {"quarry": 1, "take": s, "sable": sable}),
        "toll_bard":    (2, 4, {"quarry": 1}),
        "russet":       (3, 3, {"quarry": 1, "russet": 1}),
        "brother_wolf": (3, 5, {"pack": 1, "waits": 1, "both": 1}),
        "lodger":       (4, 4, {"lodger": lodger if lodger is not None else s}),
        "lutra":        (3, 5, {"quarry": 1, "reach": 1, "take": s}),
        "ermeline":     (3, 7, {"ermeline": 1}),
        "old_brock":    (3, 6, {"brock": 1}),
        "agnes":        (4, 6, {"pack": 1, "agnes": agnes}),
        "grizel":       (5, 8, {"pack": 1, "grizel": grizel if grizel is not None else q}),
        "glutton":      (5, 7, dict({"pack": 1, "glutton": glutton if glutton is not None else s}, **({"cleave": 1} if cleave else {}))),
        "laird":        (6, 9, {"laird": laird}),
        "isegrim":      (7, 10, dict({"biggest": 1, "gang": 1}, **({"cut": cut} if cut else {}))),
    }

GOLD = {"nip": ("take", 2), "sable": ("take", 2), "lutra": ("take", 2), "glutton": ("glutton", 2), "laird": ("laird", 1.5),
        "lodger": ("lodger", 2), "grizel": ("grizel", 2), "wick": ("wick", 2), "ermeline": ("ermeline", 2), "agnes": ("agnes", 0.5)}

# ------------------------------------------------------------------ lines
# Climb turns before R7 leave a unit off the board (the climb's gold), so unit counts lag the field there.
# A layout is (from_round, {slot: card}); cards persist (with their gains) while they stay on the board.
# 'heir' lists (round, card) sold beside Young Brock: he inherits its stats (moves are free, so the
# player moves it beside him first). 'golden' lists (round, card): from that round the card is golden.
LINE_A = dict(name="A, the Pack (tempo, then Grizel and Isegrim)", pelt=False, climbs=[2, 4, 6, 8, 11], layouts=[
    (1, {"F1": "wick"}),
    (2, {"F1": "nip", "F2": "wick"}),
    (3, {"F1": "sable", "F2": "wick", "F3": "nip"}),
    (5, {"F1": "sable", "F2": "brother_wolf", "F3": "nip", "F4": "wick", "B1": "lutra"}),
    (7, {"F1": "sable", "F2": "brother_wolf", "F3": "nip", "F4": "wick", "B1": "lutra", "B2": "agnes", "B3": "young_brock"}),
    (8, {"F1": "sable", "F2": "brother_wolf", "F3": "nip", "F4": "wick", "B1": "lutra", "B2": "agnes", "B3": "grizel"}),
    (10, {"F1": "sable", "F2": "brother_wolf", "F3": "nip", "F4": "wick", "B1": "lutra", "B2": "glutton", "B3": "grizel"}),
    (11, {"F1": "sable", "F2": "brother_wolf", "F3": "nip", "F4": "wick", "B1": "isegrim", "B2": "glutton", "B3": "grizel"}),
], heir=[], golden=[])

LINE_B = dict(name="B, Open Season (Takers, Pelts, the Glutton, the Laird)", pelt=True, flex="russet", climbs=[2, 5, 7, 9, 11], layouts=[
    (1, {"F1": "nip"}),
    (2, {"F1": "nip", "F2": "young_brock"}),
    (3, {"F1": "sable", "F2": "nip", "F3": "young_brock"}),
    (4, {"F1": "sable", "F2": "nip", "F3": "young_brock", "F4": "russet"}),
    (6, {"F1": "sable", "F2": "nip", "F3": "lodger", "F4": "russet", "B2": "lutra", "B3": "young_brock"}),
    (7, {"F1": "sable", "F2": "nip", "F3": "lodger", "F4": "russet", "B1": "ermeline", "B2": "lutra", "B3": "young_brock"}),
    (9, {"F1": "sable", "F2": "nip", "F3": "lodger", "F4": "ermeline", "B1": "lutra", "B2": "glutton", "B3": "young_brock"}),
    (11, {"F1": "sable", "F2": "nip", "F3": "lodger", "F4": "ermeline", "B1": "lutra", "B2": "glutton", "B3": "laird"}),
], heir=[(9, "russet")], golden=[])

def shift(line, d, frm=5, name=None):
    L = dict(line); L["name"] = name or f"{line['name']} [pieces from R{frm} {d:+d}]"
    L["layouts"] = [((r + d) if r >= frm else r, lay) for r, lay in line["layouts"]]
    L["layouts"].sort(key=lambda x: x[0])
    L["heir"] = [((r + d) if r >= frm else r, c) for r, c in line["heir"]]
    L["golden"] = [((r + d) if r >= frm else r, c) for r, c in line.get("golden", [])]
    return L

def strong(line, golds, name):
    L = shift(line, -1, 5, name); L["golden"] = golds; return L

def low_b():
    # Low roll: no Glutton until R12 and no Lodger (Young Brock stays in F3).
    L = dict(LINE_B); L["name"] = "B low roll (no Lodger; Glutton only at R12)"
    lays = []
    for r, lay in LINE_B["layouts"]:
        lay = dict(lay)
        for k, v in list(lay.items()):
            if v == "lodger": lay[k] = "toll_bard" if r < 7 else "russet"
        if r in (9, 11):
            lay = {k: (("russet" if v == "glutton" else v)) for k, v in lay.items()}
        lays.append((r, lay))
    lays.append((12, {"F1": "sable", "F2": "nip", "F3": "russet", "F4": "ermeline", "B1": "lutra", "B2": "glutton", "B3": "laird"}))
    L["layouts"] = lays; L["heir"] = [(7, "toll_bard")]
    return L

def low_a():
    L = dict(LINE_A); L["name"] = "A low roll (no Grizel; Isegrim at R13)"
    lays = []
    for r, lay in LINE_A["layouts"]:
        lay = {k: ("agnes" if v == "grizel" else v) for k, v in lay.items()}
        if "B2" in lay and lay["B2"] == "agnes" and "B3" in lay and lay["B3"] == "agnes":
            lay["B2"] = "young_brock"
        if r == 11:
            lay["B1"] = "lutra"
        lays.append((r, lay))
    lays.append((13, {"F1": "sable", "F2": "brother_wolf", "F3": "nip", "F4": "wick", "B1": "isegrim", "B2": "glutton", "B3": "agnes"}))
    L["layouts"] = lays
    return L

# ------------------------------------------------------------------ the growth run
SUPPER = {7: 1, 9: 1, 11: 1}
# A field unit's base (printed) stats by round, for trophies that read buffs (stats above base).
def BASE(r):
    return (2, 3) if r <= 2 else (3, 4) if r <= 4 else (3, 5) if r <= 6 else (4, 6) if r <= 8 else (5, 7) if r <= 10 else (6, 8)

def run(line, C, rounds=16, n=240, seed=11, stochastic=False, field_scale=1.0, mirror=False, start_mult=None, verbose=False):
    rng = random.Random(seed)
    stats = {}                     # card -> [a, h] gains (float)
    tribe = 0
    out = {}
    lay_for = {}
    cur = None
    li = 0
    layouts = line["layouts"]
    for r in range(1, rounds + 1):
        while li < len(layouts) and layouts[li][0] <= r:
            cur = layouts[li][1]; li += 1
        tribe += SUPPER.get(r, 0)
        for hr, c in line.get("heir", []):
            if hr == r and c in stats and "young_brock" in stats:
                g = stats.pop(c); b = C[c]
                stats["young_brock"][0] += b[0] + g[0]; stats["young_brock"][1] += b[1] + g[1]
        for c in cur.values():
            stats.setdefault(c, [0.0, 0.0])
        if start_mult and r == start_mult[0]:
            for c in cur.values():
                b = C[c]
                stats[c][0] = (b[0] + stats[c][0]) * start_mult[1] - b[0]
                stats[c][1] = (b[1] + stats[c][1]) * start_mult[1] - b[1]
        golden = {c for gr, c in line.get("golden", []) if gr <= r}
        board = [None] * 7
        H = 0
        for sl, c in cur.items():
            b = C[c]
            kw = dict(b[2])
            if c in golden and c in GOLD:
                k, f = GOLD[c]
                kw[k] = kw.get(k, 0) * f if k != "laird" else 3
            mul = 2 if c in golden else 1
            a = b[0] * mul + stats[c][0] + tribe
            h = b[1] * mul + stats[c][1] + tribe
            board[SLOTS[sl]] = {"name": c, "a": a, "h": h, "kw": kw}
            H += a + h
        biggest = max((u for u in board if u), key=lambda u: u["a"] + u["h"])
        rec = {"H": H, "ratio": H / E[r], "big": (biggest["name"], biggest["a"], biggest["h"]),
               "bigshare": (biggest["a"] + biggest["h"]) / H, "units": {u["name"]: (u["a"], u["h"]) for u in board if u}}
        # the fight(s)
        if OPT.get("buffs_mode"): OPT["buffs_base"] = BASE(r)
        nn = 1 if stochastic else n
        acc = {}; takes = 0; wins = 0; pelt = [0.0, 0.0]; poach = []; ct = 0
        for i in range(nn):
            if mirror:
                fb = [None if u is None else {"name": "m" + u["name"], "a": u["a"], "h": u["h"], "kw": u["kw"]} for u in board]
            else:
                fb = field_board(r, rng, scale=field_scale)
            if i % 2 == 0:
                res, st = fight(board, fb, rng); me = 0
            else:
                res, st = fight(fb, board, rng); me = 1
            s = st[me]
            wins += (res == me); takes += s["takes"]; ct += s["carry_take"]
            for k, g in s["gains"].items():
                d = acc.setdefault(k, [0, 0]); d[0] += g[0]; d[1] += g[1]
            if line.get("pelt") and s["pelt"]:
                np_ = 2 if "ermeline" in golden else 1
                g = tro(0.25, *s["pelt"]); pelt[0] += g[0] * np_; pelt[1] += g[1] * np_
            poach.extend(s["poach"])
        rec.update(win=wins / nn, takes=takes / nn, carry_takes=ct / nn)
        for k, g in acc.items():
            if k in stats:
                stats[k][0] += g[0] / nn; stats[k][1] += g[1] / nn
        if line.get("pelt") and "ermeline" in cur.values():
            pa, ph = pelt[0] / nn, pelt[1] / nn
            sink = pelt_sink(cur, stats, C, H)
            stats[sink][0] += pa; stats[sink][1] += ph
            rec["pelt"] = (pa, ph, sink)
        if poach and line.get("flex") and "russet" in cur.values():
            pa = sum(max(0, p[0] - 3) for p in poach) / max(1, len(poach)) / 2 + 3
            ph = sum(max(0, p[1] - 4) for p in poach) / max(1, len(poach)) / 2 + 4
            rec["poach"] = (len(poach) / nn, pa, ph)
        out[r] = rec
    return out

def pelt_sink(cur, stats, C, H):
    names = set(cur.values())
    tot = lambda c: C[c][0] + C[c][1] + stats[c][0] + stats[c][1]
    if "glutton" in names:
        if tot("glutton") < 0.35 * H: return "glutton"
        ts = [c for c in ("nip", "sable", "lutra") if c in names]
        return min(ts, key=tot) if ts else "glutton"
    return "sable" if "sable" in names else next(iter(names))

def show(out, rounds=(6, 9, 12, 15), label=""):
    for t in rounds:
        rec = out[t]
        print(f"  R{t:<2} {label:4s} board {rec['H']:7.0f}  x{rec['ratio']:.2f} of median {E[t]:6.0f}   "
              f"biggest {rec['big'][0]} {rec['big'][1]:.0f}/{rec['big'][2]:.0f} ({100 * rec['bigshare']:.0f}%)   "
              f"win {100 * rec['win']:3.0f}%  Takes {rec['takes']:.1f}")

def boardline(out, t):
    return "; ".join(f"{k} {a:.0f}/{h:.0f}" for k, (a, h) in sorted(out[t]["units"].items(), key=lambda kv: -(kv[1][0] + kv[1][1])))

def ratios(out, rounds=(6, 9, 12, 15)):
    return " ".join(f"R{t} {out[t]['ratio']:.2f}" for t in rounds)

# ------------------------------------------------------------------ fixed-board fights
def board_of(out, t, line, C, cleave=None, cut=None, golden=()):
    lay = None
    for r, l in line["layouts"]:
        if r <= t: lay = l
    b = [None] * 7
    for sl, c in lay.items():
        a, h = out[t]["units"][c]
        kw = dict(C[c][2])
        if cleave is not None and c == "glutton": kw["cleave"] = 1; kw.update(cleave)
        if cut is not None and c == "isegrim": kw["cut"] = cut
        if c in golden and c in GOLD:
            k, f = GOLD[c]; kw[k] = kw.get(k, 0) * f if k != "laird" else 3
        b[SLOTS[sl]] = {"name": c, "a": a, "h": h, "kw": kw}
    return b

def vs_fields(b, t, n=500):
    M = E[t]; Sg = 1.35 * M
    return (match(b, even(M), n), match(b, bgshape(M), n), match(b, even(Sg), n), match(b, bgshape(Sg), n))

def fmt4(w): return " / ".join(f"{100 * x:3.0f}%" for x in w)

# ------------------------------------------------------------------ main
if __name__ == "__main__":
    quick = "quick" in sys.argv
    C = cards()
    print("Hunters pass 3 synthesis model. Target median: " + ", ".join(f"R{t} {E[t]:.0f}" for t in (6, 9, 12, 15)) +
          "; strong = 1.35x. Boards are measured before each fight; growth comes from fights against the field.\n")
    res = {}
    for L in (LINE_A, LINE_B):
        o = run(L, C); res[L["name"]] = o
        print("=== Line " + L["name"])
        show(o)
        for t in (9, 12, 15):
            print(f"      R{t}: " + boardline(o, t))
        if L.get("pelt"):
            print("      Pelts a turn: " + ", ".join(f"R{t} +{o[t]['pelt'][0]:.0f}/+{o[t]['pelt'][1]:.0f} on {o[t]['pelt'][2]}" for t in (9, 12, 15)))
        print("      Early rounds (board / median, win vs field): " + ", ".join(f"R{t} x{o[t]['ratio']:.2f} {100 * o[t]['win']:.0f}%" for t in range(3, 10)))
        print()
    oa, ob = res[LINE_A["name"]], res[LINE_B["name"]]

    print("=== Fixed fights: each line's board as it fights, against median even / median BG-shaped / strong even / strong BG-shaped")
    for L, o in ((LINE_A, oa), (LINE_B, ob)):
        for t in (9, 12, 15):
            print(f"  {L['name'][:1]} R{t} [{o[t]['H']:.0f}]: {fmt4(vs_fields(board_of(o, t, L, C), t))}")
    if quick: sys.exit()

    print("\n=== Where trophies land: during the fight (Wild as written) or after it (this synthesis)")
    print("  Win % against plain field boards of k x the median, BG-shaped / even. Break-even k is what the keywords are worth.")
    def be(b, t, n=300):
        return "  ".join(f"{k}x {100 * match(b, bgshape(E[t] * k), n):.0f}/{100 * match(b, even(E[t] * k), n):.0f}" for k in (1.0, 1.35, 1.7, 2.0, 2.5))
    for L, o in ((LINE_A, oa), (LINE_B, ob)):
        for t in (9, 12):
            b = board_of(o, t, L, C)
            OPT["midfight"] = True; mid = be(b, t)
            OPT["midfight"] = False; aft = be(b, t)
            pl = be([None if u is None else (int(u["a"]), int(u["h"])) for u in b], t)
            print(f"  {L['name'][:1]} R{t} [{o[t]['ratio']:.2f}x]  during: {mid}\n{'':17s}after:  {aft}\n{'':17s}plain:  {pl}")

    print("\n=== Cleave on the Glutton (the breaker's must-fix), same boards: median even / median BG / strong even / strong BG")
    for L, o in ((LINE_A, oa), (LINE_B, ob)):
        for t in (12, 15):
            base = vs_fields(board_of(o, t, L, C), t)
            OPT["join_cleave"] = True
            jc = vs_fields(board_of(o, t, L, C, cleave={}), t)
            OPT["join_cleave"] = False
            lc = vs_fields(board_of(o, t, L, C, cleave={}), t)
            b = board_of(o, t, L, C, cleave={}); b[4], b[5] = b[5], b[4]
            ld = vs_fields(b, t)
            b2 = board_of(o, t, L, C); b2[4], b2[5] = b2[5], b2[4]
            l0 = vs_fields(b2, t)
            print(f"  {L['name'][:1]} R{t}: no Cleave {fmt4(base)} | joins cleave {fmt4(jc)} | joins don't {fmt4(lc)} | leads from B1 with Cleave {fmt4(ld)} (without {fmt4(l0)})")

    print("\n=== Share sweep (the rate parameter s; Wick, Grizel and Pelts stay at a quarter of the quarry)")
    for s in (1 / 3, 0.4, 0.5, 0.6):
        Cs = cards(s=s, wick=0.25, grizel=0.25)
        print(f"  s={s:.2f}   A: {ratios(run(LINE_A, Cs, n=160))}   B: {ratios(run(LINE_B, Cs, n=160))}")

    print("\n=== Pieces a round early or late (from R5), the breaker's robustness test")
    for d in (-1, 1, 2):
        print(f"  {d:+d}   A: {ratios(run(shift(LINE_A, d), C, n=160))}   B: {ratios(run(shift(LINE_B, d), C, n=160))}")

    print("\n=== Rolls")
    rolls = [
        (low_a(), "A low"), (low_b(), "B low"),
        (strong(LINE_A, [(6, "sable"), (11, "glutton")], "A strong (a round early; golden Sable R6, golden Glutton R11)"), "A strong"),
        (strong(LINE_B, [(6, "sable"), (11, "glutton")], "B strong (a round early; golden Sable R6, golden Glutton R11)"), "B strong"),
        (strong(LINE_B, [(5, "nip"), (6, "sable"), (10, "glutton"), (11, "laird")], "B top 1% (golden Nip R5, Sable R6, Glutton R10, Laird R11)"), "B top1"),
        (strong(LINE_A, [(5, "nip"), (6, "sable"), (9, "grizel"), (11, "glutton")], "A top 1% (golden Nip R5, Sable R6, Grizel R9, Glutton R11)"), "A top1"),
    ]
    for L, lab in rolls:
        o = run(L, C, n=160)
        print(f"  {L['name']}: {ratios(o)}   biggest at R15 {o[15]['big'][0]} {o[15]['big'][1]:.0f}/{o[15]['big'][2]:.0f} ({100 * o[15]['bigshare']:.0f}%)")

    print("\n=== Spread across games (one fight a round, 400 games a line): board / median")
    for L in (LINE_A, LINE_B):
        for t in (9, 12, 15):
            xs = sorted(run(L, C, rounds=t, stochastic=True, seed=1000 + g)[t]["ratio"] for g in range(400))
            p = lambda q: xs[int(q * (len(xs) - 1))]
            share2 = sum(x >= 2 * p(0.5) for x in xs) / len(xs)
            print(f"  {L['name'][:1]} R{t}: p10 {p(.1):.2f}  p50 {p(.5):.2f}  p90 {p(.9):.2f}  p90/p50 {p(.9) / p(.5):.2f}  "
                  f"at 2x the line's median or more {100 * share2:.0f}%  max {xs[-1]:.2f}")

    print("\n=== Behind at R8 (a losing streak): boards scaled to 0.75x at R8, then ratios")
    for L in (LINE_A, LINE_B):
        o = run(L, C, n=160, start_mult=(8, 0.75))
        print(f"  {L['name'][:1]}: R8 {o[8]['ratio']:.2f} -> R9 {o[9]['ratio']:.2f}, R12 {o[12]['ratio']:.2f}, R15 {o[15]['ratio']:.2f}")
    print("  Ahead at R8 (1.3x):")
    for L in (LINE_A, LINE_B):
        o = run(L, C, n=160, start_mult=(8, 1.3))
        print(f"  {L['name'][:1]}: R8 {o[8]['ratio']:.2f} -> R9 {o[9]['ratio']:.2f}, R12 {o[12]['ratio']:.2f}, R15 {o[15]['ratio']:.2f}")

    print("\n=== Hunter mirror: the line fights a copy of itself each round (growth a round, R9-R15; the field itself grows x1.50)")
    for L in (LINE_A, LINE_B):
        o = run(L, C, n=120, mirror=True)
        g = [o[t + 1]["H"] / o[t]["H"] for t in range(9, 15)]
        print(f"  {L['name'][:1]}: x{(o[15]['H'] / o[9]['H']) ** (1 / 6):.2f} a round (rounds: " + ", ".join(f"{x:.2f}" for x in g) + ")")
    for lab, Cx in (("Laird x1.5 ('and half again')", cards(laird=1.5)), ("no Laird", cards(laird=1))):
        o = run(LINE_B, Cx, n=120, mirror=True); of = run(LINE_B, Cx, n=160)
        print(f"  B with {lab}: mirror x{(o[15]['H'] / o[9]['H']) ** (1 / 6):.2f}; against the field R12 {of[12]['ratio']:.2f}, R15 {of[15]['ratio']:.2f}")

    print("\n=== The Laird: which half (line B board / median)")
    for lab, Cx, grant in (("'Take:' text twice (this synthesis)", cards(), False), ("all units have Quarry, no doubling", cards(laird=1), True),
                           ("both (Wild)", cards(), True)):
        OPT["laird_grant"] = grant
        o = run(LINE_B, Cx, n=160)
        OPT["laird_grant"] = False
        print(f"  {lab:38s} {ratios(o, (12, 13, 15))}  win R15 {100 * o[15]['win']:.0f}%  Takes R15 {o[15]['takes']:.1f}  biggest {o[15]['big'][0]} {100 * o[15]['bigshare']:.0f}%")

    print("\n=== Old Brock against a carry in their B2 (line B R12 board; strong BG-shaped field, carry in B2)")
    b = board_of(ob, 12, LINE_B, C)
    b2 = list(b); b2[3] = b[6]; b2[6] = b[5]
    b2[5] = {"name": "old_brock", "a": 6, "h": 9, "kw": dict(C["old_brock"][2])}
    for lab, bb in (("as built", b), ("Old Brock in B2, the Glutton in B3, the Laird in F4", b2)):
        rng = random.Random(5); ct = 0; w = 0; n = 500
        for i in range(n):
            fb = bgshape(1.35 * E[12], carry_slot=5)
            if i % 2 == 0: r_, st = fight(bb, fb, rng); me = 0
            else: r_, st = fight(fb, bb, rng); me = 1
            ct += st[me]["carry_take"]; w += (r_ == me)
        print(f"  {lab}: their carry is Taken in {100 * ct / n:.0f}% of fights; win {100 * w / n:.0f}%")

    print("\n=== Early levers (board / median, R3-R9)")
    old = cards(); old["nip"] = (2, 3, old["nip"][2]); old["wick"] = (2, 3, old["wick"][2])
    for lab, Cx in (("Nip and Wick 2/2 (this synthesis)", C), ("Nip and Wick 2/3 (Wild)", old)):
        print(f"  {lab:34s} A: {ratios(run(LINE_A, Cx, n=160), range(3, 10))}\n{'':36s}B: {ratios(run(LINE_B, Cx, n=160), range(3, 10))}")

    print("\n=== Isegrim's gang against the biggest enemy (line A R12 and R15 boards; carry Takes a fight, win vs strong BG-shaped)")
    for cut in (0.0, 0.25):
        for t in (12, 15):
            b = board_of(oa, t, LINE_A, C, cut=cut)
            rng = random.Random(7); ct = 0; w = 0; n = 400
            for i in range(n):
                fb = bgshape(1.35 * E[t], carry_slot=rng.choice((4, 5, 6)))
                if i % 2 == 0: r_, st = fight(b, fb, rng); me = 0
                else: r_, st = fight(fb, b, rng); me = 1
                ct += st[me]["carry_take"]; w += (r_ == me)
            print(f"  cut {cut:.2f} R{t}: their carry is Taken in {100 * ct / n:.0f}% of fights; win {100 * w / n:.0f}%")

    print("\n=== Sable's strike (full Attack vs half): line B early ratios and R12")
    for sb in (1.0, 0.5):
        o = run(LINE_B, cards(sable=sb), n=160)
        print(f"  Sable x{sb}: " + ", ".join(f"R{t} x{o[t]['ratio']:.2f}" for t in (4, 5, 6, 7, 8, 9, 12, 15)))
