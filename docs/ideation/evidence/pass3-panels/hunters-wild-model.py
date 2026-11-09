"""Hunters pass 3 (hunters-wild.md): expected-value growth calculator behind the R6/R9/R12/R15 boards.
Not a combat sim, and no Godot. Usage:
    python3 -I hunters-wild-model.py [f=0.5] [glutton=0.5] [pelt=0.25] [pack=0.25] [laird=2]
    python3 -I hunters-wild-model.py sweep
    python3 -I hunters-wild-model.py rolls

Why a calculator can do this: every Hunter payoff is a share of an ENEMY unit's stats (the quarry,
the pack's kill, the pounced quarry). So the Hunter board is a sum of shares of the field, and the
field is given by the target shape: level with today's bots to R7, then x1.5 a round.

Round t = recruit turn t -> fight t. Gains from fight t are on the recruit board from turn t+1.
Field board E[t]; from R7 the field's carry holds a third of it (Battlegrounds' share), so a typical
other enemy unit is m(t) = (2/3 E)/6 and the carry is E/3.
Take chance per Quarry Hunter: p = clamp(0.5 * rho^0.8, 0.2, 0.85), rho = Hunter board / field
board at that fight (0.5 when level; costing-3 measured 0.55 on even boards).
Quarry size by aim: Nip 1.0 m, Sable 1.4 m with a 15% shot at the carry (she trades up),
Lutra 1.5 m (back row), Russet 1.0 m, Toll-Bard keeps his alive (Take 0.2).
Old Brock's sett: one shared Take on their B2, chance 0.7, size 1.3 m.
Pack: each Pack unit joins jr(t) kills a fight (Brother Wolf twice that); leaders share Grizel's feed.
Isegrim's gang (Isegrim, Brother Wolf, Glutton) hunts the biggest enemy: it falls with chance
0.35 + 0.3*min(rho, 1.5); that is a Take (Glutton, Pelts) and a pack kill (Grizel) for three.
Laird: all units have Quarry (unit with no Take text Takes at 0.8 p), and Take: text triggers twice.
Ermeline's Pelts go on the carry (the Glutton) until it holds 35% of the board, then on the
smallest Quarry Hunter.
Harvest Supper +1/+1 to Hunters at R7, R9, R11, as any tribe would buy."""
import math, sys

ARGS = [a for a in sys.argv[1:] if a not in ('sweep', 'rolls')]
def arg(i, d): return float(ARGS[i]) if len(ARGS) > i else d
F, GL, PE, PK, LM = arg(0, 0.5), arg(1, 0.5), arg(2, 0.25), arg(3, 0.25), arg(4, 2)

def up(x): return int(math.ceil(x - 1e-9))

E = {1: 5, 2: 9, 3: 19, 4: 30, 5: 42, 6: 52, 7: 64}
for t in range(8, 17): E[t] = E[t - 1] * 1.5
NU = {1: 1, 2: 2, 3: 3, 4: 5, 5: 6}
def nu(t): return NU.get(t, 7)
def m(t):     return E[t] / nu(t) if t < 7 else (E[t] * 2 / 3) / 6
def carry(t): return E[t] / nu(t) * 1.3 if t < 7 else E[t] / 3
def jr(t):    return 0.5 if t < 6 else 0.7 if t < 10 else 0.9
AF = 0.45  # Attack share of a unit's stats

class U:
    def __init__(s, n, a, h, t0, t1=99, **k):
        s.n, s.a, s.h, s.t0, s.t1, s.k = n, float(a), float(h), t0, t1, k
    def on(s, t): return s.t0 <= t < s.t1
    def gain(s, x): s.a += x * AF; s.h += x * (1 - AF)
    def tot(s): return s.a + s.h

def run(units, line, F=F, GL=GL, PE=PE, PK=PK, LM=LM, rounds=16):
    us = {u.n: u for u in units}
    tribe = 0; out = {}
    for t in range(1, rounds + 1):
        if t in (7, 9, 11): tribe = min(3, tribe + 1)
        for u in us.values():                 # Young Brock inherits Hunters sold beside him
            if u.t1 == t and u.k.get('heir') and us['YoungBrock'].on(t): us['YoungBrock'].gain(u.tot())
        board = [u for u in us.values() if u.on(t)]
        names = {u.n for u in board}
        H = sum(u.tot() + 2 * tribe for u in board)
        out[t] = (H, {u.n: (up(u.a + tribe), up(u.h + tribe)) for u in board})
        rho = H / E[t]
        # ---- fight t ----
        p = min(0.85, max(0.2, 0.5 * rho ** 0.8))
        mult = LM if 'Laird' in names else 1
        takes = []
        for u in board:
            q = u.k.get('quarry')
            if q is None: continue
            if q == 'sable':
                c, s = min(0.9, p + 0.1), 0.85 * 1.4 * m(t) + 0.15 * carry(t)
            elif q == 'toll':
                c, s = 0.2, m(t)
            else:
                c, s = p, (1.0 if q == 'russet' else q) * m(t)
            takes.append((c, s))
            if q not in ('russet', 'toll'): u.gain(mult * F * c * s)
        if 'OldBrock' in names: takes.append((0.7, 1.3 * m(t)))
        if 'Laird' in names:
            for u in board:
                if u.k.get('quarry') is None: takes.append((0.8 * p, m(t)))
        ise = 'Isegrim' in names
        k_ise = (0.35 + 0.3 * min(rho, 1.5)) if ise else 0.0
        if ise: takes.append((k_ise, carry(t)))
        tk = sum(c * s for c, s in takes)
        if 'Glutton' in names: us['Glutton'].gain(GL * tk)
        if 'Ermeline' in names: us[line['pelt_sink'](names, us, H)].gain(PE * tk)
        # pack kills
        gang = {'Isegrim', 'BrotherWolf', 'Glutton'}
        joined_total = 0.0
        for u in board:
            w = u.k.get('pack')
            if not w: continue
            nj = jr(t) * w
            joined_total += nj
            big = k_ise if (ise and u.n in gang) else 0.0
            feed = PK * (nj * m(t) + big * carry(t))
            if u.n == 'Wick': u.gain(feed)
            if 'Grizel' in names: u.gain(feed)
        if 'Grizel' in names and joined_total:
            leaders = [u for u in board if u.k.get('quarry') in (1.0, 1.5, 'sable')]
            for u in leaders: u.gain(PK * (joined_total / 1.5) / len(leaders) * m(t))
        if 'Lodger' in names:
            us['Lodger'].gain(PK * (2.0 if 'OldBrock' in names else 1.5) * m(t))
    return out

def show(out, t, label, quiet=False):
    H, s = out[t]
    big = max(s.items(), key=lambda kv: kv[1][0] + kv[1][1])
    bt = big[1][0] + big[1][1]
    if not quiet:
        print(f"R{t:<2} {label}: {H:6.0f}  target {E[t]:5.0f}  x{H / E[t]:.2f}  biggest {big[0]} {big[1][0]}/{big[1][1]} ({100 * bt / H:.0f}%)")
        print("      " + "; ".join(f"{n} {a}/{h}" for n, (a, h) in s.items()))
    return H

# Line A, the Pack (tempo). Tier 2 R2, 3 R4, 4 R6, 5 R8, 6 R11.
def linea():
    return [U('Wick', 2, 3, 1, pack=1),
            U('Nip', 2, 3, 2, quarry=1.0),
            U('Sable', 2, 3, 3, quarry='sable'),
            U('YoungBrock', 2, 3, 3, 8),
            U('BrotherWolf', 3, 5, 4, pack=2),
            U('Lodger', 4, 4, 5, 10),
            U('Agnes', 3, 6, 6, 11, pack=1),
            U('Grizel', 5, 8, 8, pack=1),
            U('Glutton', 5, 7, 10, pack=1),
            U('Isegrim', 7, 10, 11, pack=1)]
LA = dict(pelt_sink=lambda n, us, H: 'Glutton')

# Line B, Open Season -> the Glutton (engine and carry). Tier 2 R2, 3 R5, 4 R7, 5 R9, 6 R11.
def lineb():
    return [U('Nip', 2, 3, 1, quarry=1.0, heir=True),
            U('YoungBrock', 2, 3, 2),
            U('Sable', 2, 3, 3, quarry='sable'),
            U('TollBard', 2, 4, 3, 7, quarry='toll', heir=True),
            U('Russet', 3, 3, 4, 11, quarry='russet', heir=True),
            U('Poached', 6, 7, 6, 9),      # the copy Russet took on R5, half its buffs, bought R6
            U('Lutra', 3, 4, 5, quarry=1.5),
            U('Ermeline', 3, 6, 7),
            U('Glutton', 5, 7, 9, pack=1),
            U('Laird', 6, 9, 11)]
# Pelts go on the carry (the Glutton; Sable before it) until it holds 35% of the board,
# then on the smallest of the Quarry Hunters (even bodies beat one carry plus small units).
def _sink(n, us, H):
    if 'Glutton' not in n: return 'Sable'
    if us['Glutton'].tot() < 0.35 * H: return 'Glutton'
    return min((x for x in ('Nip', 'Sable', 'Lutra') if x in n), key=lambda x: us[x].tot())
LB = dict(pelt_sink=_sink)

if __name__ == '__main__' and 'rolls' not in sys.argv:
    if 'sweep' in sys.argv:
        print("f     A:R9   R12   R15 | B:R9   R12   R15   (board / target)")
        for f in (1/3, 0.4, 0.5, 0.6, 0.75):
            oa, ob = run(linea(), LA, F=f), run(lineb(), LB, F=f)
            row = [oa[t][0] / E[t] for t in (9, 12, 15)] + [ob[t][0] / E[t] for t in (9, 12, 15)]
            print(f"{f:.2f}  " + "  ".join(f"{x:4.2f}" for x in row))
        print("\nLaird multiplier (B, R12 / R15):",
              ", ".join(f"x{l}: {run(lineb(), LB, LM=l)[12][0] / E[12]:.2f}/{run(lineb(), LB, LM=l)[15][0] / E[15]:.2f}" for l in (1, 2, 3)))
        print("Glutton share (B, R12 / R15):",
              ", ".join(f"{g}: {run(lineb(), LB, GL=g)[12][0] / E[12]:.2f}/{run(lineb(), LB, GL=g)[15][0] / E[15]:.2f}" for g in (0.25, 0.5, 0.75)))
        sys.exit()
    print(f"f={F} glutton={GL} pelt={PE} pack={PK} laird=x{LM}.  Target: today's bots to R7, then x1.5.")
    print("=== Line A, the Pack (tempo)")
    oa = run(linea(), LA)
    for t in (6, 9, 12, 15): show(oa, t, "A")
    print("=== Line B, Open Season -> the Glutton (engine and carry)")
    ob = run(lineb(), LB)
    for t in (6, 9, 12, 15): show(ob, t, "B")

# ---------------- Strong roll and top 1% (python3 -I hunters-wild-model.py rolls) ----------------
# Line 2 with every tier a round early (T4 R6, T5 R8, T6 R10), Sable golden from R6 (doubles her
# Take), the Glutton golden from R11 (doubles its share); top 1% adds a golden Laird (x3).
def strong():
    us = [U('Nip', 2, 3, 1, quarry=1.0, heir=True), U('YoungBrock', 2, 3, 2),
          U('Sable', 2, 3, 3, quarry='sable'), U('TollBard', 2, 4, 3, 6, quarry='toll', heir=True),
          U('Russet', 3, 3, 4, 10, quarry='russet', heir=True), U('Poached', 6, 7, 5, 8),
          U('Lutra', 3, 4, 5, quarry=1.5), U('Ermeline', 3, 6, 6), U('Glutton', 5, 7, 8, pack=1),
          U('Laird', 6, 9, 10)]
    clock = {'t': 0}
    for name, frm in (('Sable', 6), ('Glutton', 11)):
        u = next(x for x in us if x.n == name); g = u.gain
        u.gain = (lambda g, frm: (lambda x: g(x * (2 if clock['t'] >= frm else 1))))(g, frm)
    return us, clock

if __name__ == '__main__' and 'rolls' in sys.argv:
    for label, lm in (("strong roll", 2), ("top 1% (golden Laird too)", 3)):
        us, clock = strong()
        om = m
        def m2(t, om=om): clock['t'] = t; return om(t)
        globals()['m'] = m2
        o = run(us, LB, LM=lm)
        globals()['m'] = om
        print(label)
        for t in (9, 12, 15): show(o, t, "S")
