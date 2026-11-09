"""Breaker probes for the Hunters pass 3 designs (hunters-breaker.md). Paper and Python only; no Godot.

Run: python3 -I hunters-breaker-probe.py [takes|carry|engine|ermeline|slots|all]

A small combat model in the style of ../fundamentals/bramble_combat.py (rulebook ch. 9), plus:
  - Quarry: at the bell a Quarry unit marks the enemy in the same slot label; it attacks it while it is
    a legal target (front row, or the back row once the front is empty; `reach` ignores rows).
    `biggest` marks the enemy with the most Attack + Health in any row, with reach.
  - Take: the quarry dies while its marker is on the board, or in the same exchange. One per death.
  - Pack: a unit beside the attacker (same row) with Pack, alive, unflagged and with Attack joins:
    it deals its Attack to the same target as a separate hit, and is flagged. Only the leader is hit back.
  - waits: a Pack unit that does not lead while a unit beside it can (Brother Wolf's rule / the Alpha).
  - shield (first damage prevented), cleave (hits the units beside the target too, no counter).
  - sable: at Start of Combat, gains `sable` x its quarry's Attack for the fight.
Units are (attack, health) or (attack, health, kw dict). Slots 0-3 = F1-F4, 4-6 = B1-B3.
"""
import random, sys, math

FRONT = (0, 1, 2, 3)
ADJ = ((1,), (0, 2), (1, 3), (2,), (5,), (4, 6), (5,))


class U:
    def __init__(s, a, h, slot, kw):
        s.a, s.h, s.slot, s.kw = a, h, slot, dict(kw or {})
        s.flag = False
        s.shield = bool(s.kw.get("shield"))
        s.quarry = None


def side_of(board):
    return {i: U(b[0], b[1], i, b[2] if len(b) > 2 else None) for i, b in enumerate(board) if b}


def fight(b0, b1, rng):
    S = [side_of(b0), side_of(b1)]
    takes = [0, 0]
    # the bell: marks
    for s in (0, 1):
        en = S[1 - s]
        for u in S[s].values():
            if u.kw.get("biggest") and en:
                u.quarry = max(en.values(), key=lambda v: (v.a + v.h, -v.slot))
            elif u.kw.get("quarry") and u.slot in en:
                u.quarry = en[u.slot]
    for s in (0, 1):  # Sable
        for u in S[s].values():
            if u.kw.get("sable") and u.quarry is not None:
                u.a += int(u.kw["sable"] * u.quarry.a)
    n0, n1 = len(S[0]), len(S[1])
    active = 0 if n0 > n1 else 1 if n1 > n0 else rng.randint(0, 1)
    attacks = 0
    last = -1

    def alive(s, u):
        return S[s].get(u.slot) is u

    def legal(s, tgt, att):
        en = S[1 - s]
        if not alive(1 - s, tgt):
            return False
        if att.kw.get("reach") or att.kw.get("biggest"):
            return True
        has_front = any(k in FRONT for k in en)
        return (tgt.slot in FRONT) or not has_front

    def choose(s):
        units = [S[s][k] for k in sorted(S[s])]
        ready = [u for u in units if u.a > 0]
        if not ready:
            return None
        cand = [u for u in ready if not u.flag]
        if not cand:
            for u in units:
                u.flag = False
            cand = ready
        for u in cand:
            if u.kw.get("waits"):
                partner = any((k in S[s]) and S[s][k].a > 0 and not S[s][k].flag and S[s][k] is not u
                              for k in ADJ[u.slot])
                if partner and len(cand) > 1:
                    continue
            att = u
            break
        else:
            att = cand[0]
        return att

    def target(s, att):
        if att.quarry is not None and legal(s, att.quarry, att):
            return att.quarry
        en = S[1 - s]
        front = [en[k] for k in sorted(en) if k in FRONT]
        c = front if front else [en[k] for k in sorted(en)]
        return c[rng.randrange(len(c))] if c else None

    def hit(t, amt):
        if amt <= 0:
            return
        if t.shield:
            t.shield = False
            return
        t.h -= amt

    def deaths(s_act, marker_alive_before):
        for s in (s_act, 1 - s_act):
            dead = [u for u in list(S[s].values()) if u.h <= 0]
            for u in dead:
                del S[s][u.slot]
            for u in dead:  # Take check for the other side
                o = 1 - s
                for m in marker_alive_before[o]:
                    if m.quarry is u:
                        takes[o] += 1
                        break

    while S[0] and S[1]:
        if attacks >= 200:
            return -1, takes
        if not any(u.a > 0 for u in S[0].values()) and not any(u.a > 0 for u in S[1].values()):
            return -1, takes
        att = choose(active)
        if att is not None:
            attacks += 1
            t = target(active, att)
            if t is not None:
                before = [list(S[0].values()), list(S[1].values())]
                joiners = []
                if att.slot in FRONT:
                    row = FRONT
                else:
                    row = (4, 5, 6)
                for k in ADJ[att.slot]:
                    j = S[active].get(k)
                    if j and j.kw.get("pack") and j.a > 0 and not j.flag:
                        joiners.append(j)
                for u in S[active].values():
                    if u.slot <= att.slot:
                        u.flag = True
                back = t.a
                hit(t, att.a)
                if att.kw.get("cleave"):
                    for k in ADJ[t.slot]:
                        v = S[1 - active].get(k)
                        if v:
                            hit(v, att.a)
                for j in joiners:
                    j.flag = True
                    hit(t, j.a)
                    if j.kw.get("cleave"):
                        for k in ADJ[t.slot]:
                            v = S[1 - active].get(k)
                            if v:
                                hit(v, j.a)
                hit(att, back)
                last = active
                deaths(active, before)
        active = 1 - active
    if S[0] and not S[1]:
        return 0, takes
    if S[1] and not S[0]:
        return 1, takes
    return last, takes


def match(b0, b1, n=2000, seed=3):
    rng = random.Random(seed)
    w = 0
    tk = 0
    for i in range(n):
        if i % 2 == 0:
            r, t = fight(b0, b1, rng)
            me = 0
        else:
            r, t = fight(b1, b0, rng)
            me = 1
        w += (r == me)
        tk += t[me]
    return w / n, tk / n


def even(total, n=7, af=0.45):
    per = total / n
    a = max(1, round(per * af))
    h = max(1, round(per - a))
    return [(a, h)] * n


def scale_board(b, k):
    return [None if u is None else (max(1, round(u[0] * k)), max(1, round(u[1] * k))) + ((u[2],) if len(u) > 2 else ())
            for u in b]


# ------------------------------------------------------------------ probe 1: Takes vs standing
def rand_board(total, rng, quarry_front=False, sd=0.35):
    w = [math.exp(rng.gauss(0, sd)) for _ in range(7)]
    z = sum(w)
    out = []
    for i, x in enumerate(w):
        per = total * x / z
        af = rng.uniform(0.38, 0.52)
        a, h = max(1, round(per * af)), max(1, round(per * (1 - af)))
        out.append((a, h, {"quarry": True}) if (quarry_front and i < 4) else (a, h))
    return out


def take_rate(k, n=1500, seed=5, total=531):
    """Takes per Quarry Hunter and win rate for a Hunter board of k x the enemy's total; both boards random."""
    rng = random.Random(seed)
    w = tk = 0
    for i in range(n):
        hb = rand_board(total * k, rng, quarry_front=True)
        eb = rand_board(total, rng)
        if i % 2 == 0:
            r, t = fight(hb, eb, rng); me = 0
        else:
            r, t = fight(eb, hb, rng); me = 1
        w += (r == me)
        tk += t[me]
    return w / n, tk / n / 4


def probe_takes():
    print("Probe 1. Takes a fight against standing. Both boards random (7 units, spread sd 0.35), enemy 531 stats (R12 median).")
    print("Hunter board: 4 Quarry Hunters in F1-F4 marking the enemy across, 3 plain back units, total k x the enemy.")
    print(" k(ratio)  win%   Takes a fight (4 Quarry Hunters)   per Hunter")
    for k in (0.5, 0.67, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 2.0):
        w, t = take_rate(k)
        print(f"  {k:4.2f}    {100 * w:5.1f}   {4 * t:4.2f}                              {t:4.2f}")


# ------------------------------------------------------------------ probe 2: the boards in a fight; Cleave
def bgshape(T):
    c = T / 3
    o = (T - c) / 6
    u = (round(o * .45), round(o * .55))
    return [u] * 5 + [(round(c * .45), round(c * .55))] + [u]


def drop(b, key):
    out = []
    for u in b:
        if u and len(u) > 2 and key in u[2]:
            kw = dict(u[2]); kw.pop(key); out.append((u[0], u[1], kw))
        else:
            out.append(u)
    return out


def show(name, b, meds, n=800):
    T = sum(u[0] + u[1] for u in b if u)
    r = []
    for M in meds:
        for lab, e in (("even", even(M)), ("BG-shaped", bgshape(M))):
            r.append(f"{M} {lab} {100 * match(b, e, n=n)[0]:.0f}%")
    print(f"  {name} [{T}]: " + "; ".join(r))


def probe_carry():
    print("Probe 2. Boards in a fight (win % against even boards and BG-shaped boards with a carry of a third in B2).")
    print("  Check: this model gives the audit's carry.txt result (24/24 + 6 x 3/3 vs 7 x 6/6 at F1):",
          f"{100 * match([(24, 24)] + [(3, 3)] * 6, [(6, 6)] * 7, n=4000)[0]:.1f}% (audit 15.4%)")
    lut = {"biggest": True}; sab = {"quarry": True, "sable": 0.5}; q = {"quarry": True}
    full = {"pack": True, "waits": True, "cleave": True, "shield": True}
    hold = {"pack": True, "waits": True, "shield": True}
    def cb(A, kw):
        return [(2, 3), (2, 3, sab), (2, 4, q), (2, 3, q), (3, 4, lut), (A[0], A[1], kw), (2, 3, {"pack": True})]
    print(" Carry design, its R12 layout, Alpha sized as it fights (the model reports the board after the fight):")
    show("Glutton Alpha 102/103, Pack + Shield + Cleave (R12)", cb((102, 103), full), (531, 717))
    show("Nip Alpha 87/88, Pack + Shield, no Glutton (R12)", cb((87, 88), hold), (531, 717))
    show("Glutton Alpha 186/187 as the doc prints R12", cb((186, 187), full), (531, 717))
    show("Glutton Alpha 102/103 halved by an answer (51/52)", cb((51, 52), full), (531,))
    eng = [(22, 22, {"quarry": True, "reach": True}), (35, 36, {"quarry": True, "sable": 0.5}), (36, 36, q), (6, 6, q),
           (64, 65, q), (37, 37, q), (29, 30, {"cleave": True, "quarry": True})]
    engd = [(22, 22, {"quarry": True, "reach": True}), (54, 55, {"quarry": True, "sable": 0.5}), (55, 55, q), (6, 6, q),
            (103, 103, q), (56, 56, q), (68, 68, {"cleave": True, "quarry": True})]
    print(" Engine design, R12 sett (mid-fight Feast ignored):")
    show("as it fights R12 (the doc's board minus its own R12 meal)", eng, (531, 717))
    show("as the doc prints R12 (after the R12 fight)", engd, (531, 717))
    wa = [(47, 58, {"quarry": True, "sable": 1.0}), (30, 38, {"pack": True, "waits": True}), (36, 43, q), (25, 30, {"pack": True}),
          (22, 27, lut), (55, 68, {"pack": True, "cleave": True, "biggest": True}), (17, 21, {"pack": True})]
    wb = [(47, 57, {"quarry": True, "sable": 1.0}), (32, 39, q), (11, 13), (46, 56, {"quarry": True, "reach": True}),
          (6, 9), (68, 83, {"pack": True, "cleave": True}), (9, 12)]
    print(" Wild design, R12 (its model is not off by one):")
    show("Pack line", wa, (531, 717))
    show("Pack line, Glutton without Cleave", drop(wa, "cleave"), (531, 717))
    show("Open Season line", wb, (531, 717))
    show("Open Season line, Glutton without Cleave", drop(wb, "cleave"), (531, 717))


# ------------------------------------------------------------------ probe 3: Feast steady state
def take_curve():
    return {k: take_rate(k, n=700, seed=11)[1] for k in (0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0)}


def interp(pts, k):
    ks = sorted(pts)
    if k <= ks[0]:
        return pts[ks[0]]
    if k >= ks[-1]:
        return pts[ks[-1]]
    for lo, hi in zip(ks, ks[1:]):
        if lo <= k <= hi:
            return pts[lo] + (pts[hi] - pts[lo]) * (k - lo) / (hi - lo)


def probe_engine():
    print("Probe 3. The Feast engine with Takes that depend on standing (Take rate per Quarry Hunter from probe 1).")
    pts = take_curve()
    print("  Take rate per Quarry Hunter by ratio:", ", ".join(f"{k}:{v:.2f}" for k, v in sorted(pts.items())))
    U = {7: 10.0}
    for r in range(8, 17):
        U[r] = U[r - 1] * 1.5
    med = {r: 7 * U[r] for r in U}
    # Hunter board = bodies (today's flat curve, +13 a round from 80 at R8, times a start factor) + Feast eaten.
    def run(feast_sched, marks_sched, start, s=1 / 6, mirror=False, label="", fixed=None):
        fe = 0.0
        out = []
        for r in range(8, 16):
            body = start * (80 + 13 * (r - 8))
            H = body + fe
            E = H if mirror else med[r]
            k = H / E
            F = max(v for rr, v in feast_sched if rr <= r)
            M = max(v for rr, v in marks_sched if rr <= r)
            t = fixed[r] if fixed else M * interp(pts, k)
            fe += F * t * s * 0.8 * (E / 7)
            if r + 1 in (9, 12, 15):
                H2 = start * (80 + 13 * (r + 1 - 8)) + fe
                E2 = H2 if mirror else med[r + 1]
                out.append(f"R{r + 1} {H2 / med[r + 1]:.2f}x")
        print(f"   {label:66s} " + "  ".join(out))
    sett = [(8, 6), (11, 7), (13, 8)]
    four = [(8, 4)]
    merged = [(8, 6), (9, 8), (10, 9), (11, 11), (13, 12)]
    marks = [(8, 4), (13, 7)]
    print("  Board against the field median (field x1.5 a round from R8; Hunter bodies flat, plus Feast).")
    print("  Bodies x1.0 = today's median (80 at R8, 0.76x the target's 105); x1.31 = level with the target at R8.")
    fixed = {8: 2.5, 9: 3, 10: 3, 11: 3.5, 12: 3.5, 13: 4.5, 14: 4.5, 15: 4.5}
    run(sett, four, 1.0, label="sett line, designer's FIXED Takes (3-4.5), bodies x1.0", fixed=fixed)
    run(sett, four, 1.31, label="sett line, designer's FIXED Takes, bodies x1.31", fixed=fixed)
    for st in (1.0, 1.31, 1.5, 1.75, 2.0):
        run(sett, four, st, label=f"sett line, Takes from standing, bodies x{st}")
    for st in (1.0, 1.31, 1.5):
        run(merged, marks, st, label=f"merged sett+Grizel+Agnes+Laird (to 12 Feast, 7 marks), bodies x{st}")
    run(sett, four, 1.0, mirror=True, label="sett line against an equal Hunter board every round")
    run(merged, marks, 1.0, mirror=True, label="merged line against an equal Hunter board every round")


# ------------------------------------------------------------------ probe 4: Ermeline, all gold to refresh
def probe_ermeline():
    print("Probe 4. Carry design: Ermeline when spare gold all goes to paid refreshes (designer's model and its after-the-fight convention).")
    def run(label, buys, refresh, k=1, glut=10, ermelines=1):
        S = 1.0
        a = 2.0
        g = None
        owned = {}
        res = {}
        for r in range(1, 16):
            for rr, c, n in buys:
                if rr == r:
                    owned[c] = owned.get(c, 0) + n
            if glut and r == glut:
                g = 5.0
            nt = 0.6 * owned.get("nip", 0) + 1.5 * owned.get("wick", 0) + 1.0 * owned.get("lodger", 0) + 0.9 * owned.get("lutra", 0)
            nt += refresh(r) * owned.get("ermeline", 0)
            gain = nt * S * (2 if g is not None else 1)
            if g is not None:
                g += gain
            else:
                a += gain
            S += k * owned.get("grizel", 0)
            if r in (9, 12, 15):
                res[r] = int(g if g is not None else a)
        print(f"   {label:58s} Alpha (one side) R9 {res[9]}, R12 {res[12]}, R15 {res[15]}")
    typ = [(1, "nip", 1), (2, "wick", 1), (5, "lodger", 1), (6, "lutra", 1), (8, "grizel", 1), (8, "ermeline", 1), (11, "grizel", 1)]
    design = lambda r: 0 if r < 8 else (2 if r < 10 else (3 if r < 13 else 5))
    allin = lambda r: 0 if r < 8 else (4 if r < 10 else (8 if r < 13 else 11))
    run("designer's refresh schedule (2/3/5 a turn)", typ, design)
    run("all spare gold to refresh (4/8/11 a turn)", typ, allin)
    run("all-in, with a second Ermeline from R10", typ + [(10, "ermeline", 1)], allin)
    slots = [(1, "nip", 1), (2, "wick", 1), (6, "lutra", 1), (8, "grizel", 1), (8, "ermeline", 1), (11, "grizel", 1)]
    run("slot-honest (no Lodger: Brother Wolf, Young Brock need slots)", slots, design)
    run("slot-honest, one Grizel only", [(1, "nip", 1), (2, "wick", 1), (6, "lutra", 1), (8, "grizel", 1), (8, "ermeline", 1)], design)
    print("   Stats per gold through Ermeline on the Glutton (2 x Titbit x 2), at the doc's Titbit sizes +3, +7, +13:"
          " R9 %d, R12 %d, R15 %d; a 3-gold T5 body is about 12 stats." % (2 * 3 * 2, 2 * 7 * 2, 2 * 13 * 2))


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("takes", "all"):
        probe_takes(); print()
    if what in ("carry", "all"):
        probe_carry(); print()
    if what in ("engine", "all"):
        probe_engine(); print()
    if what in ("ermeline", "all"):
        probe_ermeline(); print()
