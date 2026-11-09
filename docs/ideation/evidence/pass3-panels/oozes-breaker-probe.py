"""Oozes pass 3 breaker: growth probes on the three designers' own models.

Run:  python3 -I oozes-breaker-probe.py [engine|carry|wild]   (no argument: all three)

Each section re-plays a designer's model with the line a committed player would
take, or with a card the design treats as rare arriving when it really can.
Growth only; nothing here fights (see oozes-breaker-fight.py for fights).

- engine: the Back Burner model (embedded copy of the designer's final_model.py,
  logic unchanged) with Track B's End of Turn doubler, which is a tier 3 neutral
  ("Second Helping", content/levers/scale_doubler.json on ideation/mechanics).
- carry: routes.py line2 (embedded, unchanged) plus probes for two Aspics,
  Figgy's golden Soup, golden Elder, and eating Elder-grown Oozes.
- wild: oozes-wild-model.py imported as is; probes put Cut-and-Come-Again's
  slices into ovens instead of the front row, and add Pies.
"""
import math
import sys
import os
import importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
TGT = {6: 53, 9: 194, 12: 759, 15: 2600}   # BG Sep 2025 means (R15 extrapolated)


# --------------------------------------------------------------------------
# ENGINE: embedded copy of the designer's model (final_model.py), unchanged logic
R = 0.5


def sim(u, times=1):
    for _ in range(times):
        u['a'] += math.floor(u['a'] * R)
        u['h'] += math.floor(u['h'] * R)


def mk(n, a, h, ooze=False):
    return {'n': n, 'a': a, 'h': h, 'ooze': ooze}


class Board:
    def __init__(s):
        s.units = []; s.supper = 0; s.soup = None; s.eotx = 1

    def get(s, n): return [u for u in s.units if u['n'] == n][0]

    def add(s, n, a, h, oven=False, belly=1):
        u = mk(n, a, h, True); u.update(oven=oven, inside=[], belly=belly); s.units.append(u); return u

    def feed(s, n, unit):
        s.get(n)['inside'].append(unit)
        if s.soup: s.soup['a'] += 1; s.soup['h'] += 1
        if s.get(n)['n'].startswith('Granny'): unit['a'] *= 2; unit['h'] *= 2

    def move(s, a, b):
        u = s.get(a)['inside'].pop(); s.units.remove(s.get(a)); s.feed(b, u)

    def eot(s):
        for u in s.units:
            if u['oven']:
                for i in u['inside']: sim(i, s.eotx)

    def total(s):
        t = 0; big = 0
        for u in s.units:
            for x in [u] + u['inside']:
                st = x['a'] + x['h'] + (2 * s.supper if x['ooze'] else 0); t += st; big = max(big, st)
        return t, big


def erun(plan):
    b = Board(); out = {}
    for rd in range(1, 16):
        for f in plan.get(rd, []): f(b)
        b.eot(); out[rd] = b.total()
    return out


L = lambda *fs: list(fs)
def soup(b): b.soup = b.add('Stone Soup', 2, 3)
def sup(b): b.supper += 1
def heat(n):
    def f(b):
        best = max((i for u in b.units for i in u['inside']), key=lambda i: i['a'] + i['h']); best['a'] += n; best['h'] += n
    return f
def doubler(x):
    def f(b): b.eotx = x
    return f


typical_engine = {
    1: L(lambda b: b.add('Little Dollop', 2, 2)),
    3: L(soup, lambda b: b.feed('Little Dollop', mk('t1', 2, 3))),
    5: L(lambda b: b.add('Aunt Aspic', 2, 4, True), lambda b: b.feed('Aunt Aspic', mk('dough1', 3, 4)), lambda b: b.add('Dishwater Nell', 1, 3, belly=0)),
    7: L(lambda b: b.add('Frumenty', 2, 4, True), lambda b: b.feed('Frumenty', mk('dough2', 3, 6)), lambda b: b.add('Sixpenny Pie', 2, 5, belly=2), lambda b: b.feed('Sixpenny Pie', mk('t4', 4, 6))),
    8: L(lambda b: b.feed('Sixpenny Pie', mk('nell', 2, 3))),
    9: L(sup, lambda b: b.add('Moss Ooze', 2, 4)),
    10: L(sup, heat(4)),
    11: L(lambda b: b.add('Granny Stir-Up', 6, 10, True), lambda b: b.move('Aunt Aspic', 'Granny Stir-Up'), lambda b: b.units.remove(b.get('Dishwater Nell')),
          lambda b: b.add('Aunt Aspic', 2, 4, True), lambda b: b.feed('Aunt Aspic', mk('dough3', 6, 8)), sup),
    12: L(sup, lambda b: b.units.remove(b.get('Moss Ooze')), lambda b: b.add('Elder Ooze', 4, 8, True), lambda b: b.feed('Elder Ooze', mk('t5', 5, 8)),
          lambda b: b.get('Sixpenny Pie').update(oven=True), heat(8)),
    13: L(sup), 14: L(sup), 15: L(sup)}


def with_extra(plan, rd, *fs):
    p = {k: list(v) for k, v in plan.items()}
    p.setdefault(rd, [])
    p[rd] = list(fs) + p[rd]
    return p


def engine():
    print("ENGINE (Simmer, End of Turn, r = 1/2). Board total at R6 / R9 / R12 / R15, then x target (53/194/759/2600)")
    rows = [("typical engine, as designed", typical_engine),
            ("+ doubler (tier 3) bought R6", with_extra(typical_engine, 6, doubler(2))),
            ("+ doubler bought R8", with_extra(typical_engine, 8, doubler(2))),
            ("+ doubler bought R10", with_extra(typical_engine, 10, doubler(2))),
            ("+ golden or two doublers from R10", with_extra(typical_engine, 10, doubler(3)))]
    for label, plan in rows:
        o = erun(plan)
        cells = " / ".join(f"{o[k][0]:>7,}" for k in (6, 9, 12, 15))
        xs = " / ".join(f"{o[k][0] / TGT[k]:.1f}x" for k in (6, 9, 12, 15))
        print(f"  {label:34s} {cells}   ({xs})   biggest R15 {o[15][1]:,}")
    print("  (two plain doublers add two firings, the same as one golden: rulebook 'Multiple doublers add extra firings')")
    print()


# --------------------------------------------------------------------------
# CARRY: routes.py line2, embedded with three optional hooks (defaults reproduce it exactly)
BASE = {1: 5, 2: 6.5, 3: 8, 4: 9.5, 5: 11, 6: 13}


def line2(r, e, s, route, aspic=1.5, aspic_from=6, nell_mult=False, nell_from=4,
          r_late=None, r_late_from=99, e_late=None, e_late_from=99, eat_support_from=99):
    tiers = {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 4, 8: 4, 9: 5, 10: 5, 11: 6, 12: 6, 13: 6, 14: 6, 15: 6, 16: 6}
    C = 3.0; pending = 0.0; sup_ = []; rows = []
    for t in range(1, 17):
        tier = tiers[t]
        rr = r_late if (r_late is not None and t >= r_late_from) else r
        ee = e_late if (e_late is not None and t >= e_late_from) else e
        mult = aspic if (route == 'carry' and t >= aspic_from) else 1.0
        C += pending * mult; pending = 0.0
        S = rr * C if t >= 3 else 0.0
        if t >= 12:
            sl = s * C
            if route == 'carry': pending += sl
            else: sup_.append(sl)
        if route == 'carry':
            meals = {2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 2, 9: 1, 10: 2, 11: 1, 12: 2, 13: 2, 14: 2, 15: 2, 16: 2}.get(t, 0)
            buys = {3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 9: 1, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1, 16: 1}.get(t, 0)
        else:
            meals = {2: 1, 3: 1, 4: 1, 5: 1, 7: 1, 8: 1, 9: 1, 10: 1, 11: 1, 12: 1, 13: 1, 14: 1, 15: 1, 16: 1}.get(t, 0)
            buys = {1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 2, 7: 1, 8: 2, 9: 1, 10: 2, 11: 1, 12: 2, 13: 2, 14: 2, 15: 2, 16: 2}.get(t, 0)
        pending += meals * (BASE[1] + S)
        for _ in range(buys): sup_.append(BASE[tier] + S)
        if t >= nell_from:
            C += (BASE[tier] + rr * C) * (mult if nell_mult else 1.0)
        cap = 6 if route == 'carry' else 10
        sup_.sort(reverse=True); sup_ = sup_[:cap]
        if t >= 10:
            n_ooze = 4 if route == 'carry' else 7
            for i in range(min(n_ooze, len(sup_))): sup_[i] += ee * C
        # probe hook: the carry eats the biggest Elder-grown Ooze support (Digest, next Start of Turn);
        # a fresh shop unit replaces it at once (the line already buys one support a turn)
        if route == 'carry' and t >= eat_support_from and sup_:
            sup_.sort(reverse=True)
            pending += sup_.pop(0)
            sup_.append(BASE[tier] + S)
        bs = sorted(sup_, reverse=True)[:6]
        board = C + sum(bs)
        rows.append(dict(t=t, C=C, board=board, share=C / board))
    return rows


def carry():
    print("CARRY (Stock Pot, Soup r = 1/10, Elder 1/10, slice 1/5). Board total R6 / R9 / R12 / R15, then x target")
    base = dict(r=0.1, e=0.1, s=0.2, route='carry', nell_from=6)
    rows = [("designer typical, no Aspic", dict(aspic=1.0)),
            ("designer with Aspic (+50%)", dict(aspic=1.5)),
            ("two Aspics (+100%) from R7", dict(aspic=2.0, aspic_from=7)),
            ("golden Soup via Figgy from R8", dict(aspic=1.5, r_late=0.2, r_late_from=8)),
            ("golden Soup R8 + two Aspics R7", dict(aspic=2.0, aspic_from=7, r_late=0.2, r_late_from=8)),
            ("eat an Elder-grown Ooze a turn, R11+", dict(aspic=1.5, eat_support_from=11)),
            ("golden Elder from R11", dict(aspic=1.5, e_late=0.2, e_late_from=11)),
            ("two Aspics + eat Elder-grown, R11+", dict(aspic=2.0, aspic_from=7, eat_support_from=11)),
            ("golden Soup ×1.5 (3/20) R8 + 2 Aspics", dict(aspic=2.0, aspic_from=7, r_late=0.15, r_late_from=8)),
            ("Aspics don't stack, golden Soup 3/20", dict(aspic=1.5, r_late=0.15, r_late_from=8))]
    for label, kw in rows:
        o = {x['t']: x for x in line2(**base, **kw)}
        cells = " / ".join(f"{o[k]['board']:>7,.0f}" for k in (6, 9, 12, 15))
        xs = " / ".join(f"{o[k]['board'] / TGT[k]:.1f}x" for k in (6, 9, 12, 15))
        print(f"  {label:38s} {cells}   ({xs})   carry share R12 {100 * o[12]['share']:.0f}%")
    print()


# --------------------------------------------------------------------------
# WILD: import the designer's calculator unchanged, then vary the plans
def wild():
    spec = importlib.util.spec_from_file_location("oozes_wild_model", os.path.join(HERE, "oozes-wild-model.py"))
    W = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(W)

    def slices_into_ovens(st):
        """A slice goes into a back-row Rise oven with room; if none has room, it is
        played to the front as the designer's line does."""
        for sl in sorted([u for u in st.hand if u.created], key=lambda u: -u.stats()):
            ovens = [st.board[s] for s in ("B1", "B2", "B3") if st.board[s] and st.board[s].rise
                     and len(st.board[s].inside) < st.board[s].belly]
            if ovens:
                ovens[0].inside.append(sl); st.hand.remove(sl)
        return W.play_slices(st)

    def second_pie(slot_from="B2", nell_to="F4"):
        """Buy a second Sixpenny Pie for the back row; Nell (who reads no slot) moves to the front."""
        def act(st):
            if not st.can(3):
                return False
            st.pay(3)
            nell = st.board[slot_from]
            st.board[slot_from] = st.card("The Sixpenny Pie", 2, 5, belly=2, rise=True, tier=3)
            old = st.board[nell_to]
            if old is not None and not old.created:
                st.gold += 1
            st.board[nell_to] = nell
            return True
        return act

    base = W.LINES["carry"]
    plan_slices = {k: list(v) for k, v in base["plan"].items()}
    for k in range(12, 17):
        plan_slices[k] = [slices_into_ovens]
    plan_pie2 = {k: list(v) for k, v in plan_slices.items()}
    plan_pie2[12] = [second_pie()] + plan_pie2[12]
    plan_pie2_early = {k: list(v) for k, v in plan_slices.items()}
    plan_pie2_early[7] = [second_pie()] + plan_pie2_early.get(7, [])
    rows = [("carry line as designed (slices to front)", base["plan"]),
            ("slices into ovens with room", plan_slices),
            ("+ second Pie R12 (Nell to front)", plan_pie2),
            ("+ second Pie R7 (Nell to front)", plan_pie2_early)]
    print("WILD (Rise, Start of Turn, r = 1/2). Board total R6 / R9 / R12 / R15, then x target; gold unspent at R15")
    for label, plan in rows:
        W.P.update(r=(1, 2))
        o = W.run(dict(base, plan=plan))
        cells = " / ".join(f"{o[k][0]:>7,}" for k in (6, 9, 12, 15))
        xs = " / ".join(f"{o[k][0] / TGT[k]:.1f}x" for k in (6, 9, 12, 15))
        print(f"  {label:42s} {cells}   ({xs})   biggest R15 {o[15][2].a}/{o[15][2].h}")
    print("  (the designer's line ends R15 with 32 gold unspent; none of these probes spend it either)")
    print()


if __name__ == "__main__":
    which = sys.argv[1:] or ["engine", "carry", "wild"]
    for w in which:
        {"engine": engine, "carry": carry, "wild": wild}[w]()
