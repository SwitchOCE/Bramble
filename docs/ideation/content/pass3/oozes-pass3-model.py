"""Oozes pass 3 synthesis: growth and R12 fights for the synthesized cards.

Run:  python3 -I oozes-pass3-model.py            (growth table, sweeps, fights)
      python3 -I oozes-pass3-model.py growth     (growth only)
      python3 -I oozes-pass3-model.py fights     (fights only)

Paper model only. Nothing runs in Godot. Read it for direction.

GROWTH. A turn-by-turn line with gold accounting (income 3..10, carry-over,
upgrade costs 5/7/8/11/11 with the 1-a-turn discount, 3-gold buys, sell for 1).
The carry is kept square (A = H = C/2). A shop unit is BASE[tier] + Soup's share.
Cards modelled (synthesis text):
  Little Dollop   Belly 1. Digest. Units you buy into this cost 1 gold less.
  Stone Soup      Units in your shop gain a tenth of your biggest Ooze's stats.
                  Golden: ... of your two biggest Oozes' stats.  Only the best Soup counts.
  Dishwater Nell  Start of Turn: the biggest Ooze next to this eats your shop's lowest-tier unit.
                  Golden: the two biggest Oozes next to her each eat one.
  Aunt Aspic      Oozes in front of this gain 50% more when they eat a non-Ooze.
                  Golden: double.  Only one Aspic counts for an eater.
  Bubble/Squeak   Belly 1. Digest. split (fights only).
  Elder Ooze      After your biggest Ooze eats a non-Ooze: your other Oozes gain half of it.
                  Golden: all of it.
  Hasty Pudding   Start of Combat: if empty, swallow the biggest enemy.
                  Your biggest Ooze permanently gains a fifth of it.
  Cut-and-Come    Start of Turn: get a Slice with a fifth of your biggest Ooze's stats (a token, not an Ooze).
  Moss Ooze       When a unit comes out of your Oozes: it gains Shield (fights only).
  Doubler         Track B's tier 3 "Second Helping" doubles End of Turn text; no Ooze card has any.
  Second stomach  From R8 a fresh Dollop in F1 (also in front of Aspic) takes one 2-gold meal a turn;
                  the carry eats it every 3 turns (an Ooze: stats pass whole, no bonus).
Meals into the carry: Belly 1 (golden 2). Digest at Start of Turn. Eating an Ooze gets no Aspic
bonus and no Elder share. Turducken (eating a full Pie) is cut: no nesting.

FIGHTS. The carry designer's combat model (oozes-carry-model/ooze_combat3.py, an
extension of the audit's bramble_combat.py), loaded with patches, not edited:
  - a Belly may hold a list (as the breaker's patch);
  - Hasty's swallowed unit also comes back after 3 friendly deaths, or when its side
    has nobody else (today's release, restored);
  - "split_after_damage": Bubble splits only after a hit that dealt damage (a hit
    Shield stops doesn't count) -- the synthesis rule;
  - "halve_big": Start of Combat, halve the biggest enemy (Track B's answer), for the
    answer test.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TGT = {6: 53, 7: 79, 8: 123, 9: 194, 10: 305, 11: 482, 12: 759, 13: 1177, 14: 1751, 15: 2600, 16: 3900}
BASE = {1: 5, 2: 6.5, 3: 8, 4: 9.5, 5: 11, 6: 13}          # a typical shop unit's A+H at a tier
INCOME = {1: 3, 2: 4, 3: 5, 4: 6, 5: 7, 6: 8, 7: 9}
UPCOST = {2: 5, 3: 7, 4: 8, 5: 11, 6: 11}
BODY = {  # printed A+H of the engine cards (synthesis bodies)
    'little_dollop': 3, 'stone_soup': 5, 'dishwater_nell': 5, 'moss_ooze': 6, 'aunt_aspic': 6,
    'bubble_and_squeak': 7, 'sixpenny_pie': 7, 'frumenty': 5, 'figgy_duff': 8, 'mr_syllabub': 9,
    'elder_ooze': 12, 'hasty_pudding': 12, 'granny_stir_up': 12, 'cut_and_come_again': 10,
    'wee_wobbly': 5, 'mrs_posset': 3}


def income(t):
    return INCOME.get(t, 10)


class Line:
    def __init__(self, **kw):
        self.kw = kw
        self.r = kw.get('r', 0.1)
        self.climb = kw.get('climb', [3, 5, 7, 9, 11])
        self.cards = kw.get('cards', {})          # round -> list of engine card ids bought that round
        self.route = kw.get('route', 'carry')
        self.aspic = kw.get('aspic', 0.5)         # bonus share when Aspic stands behind the eater
        self.e = kw.get('e', 0.25)                # Elder share of each non-Ooze meal
        self.h = kw.get('h', 0.1)                 # Hasty share of the swallowed enemy
        self.sl = kw.get('s', 0.2)                # slice share
        self.belly = kw.get('belly', 1)           # meals a turn into the carry
        self.golden = kw.get('golden', {})        # card -> round it turns golden
        self.doubler = kw.get('doubler', 99)      # round the tier 3 doubler lands
        self.biggest_share = kw.get('field_biggest', 0.34)
        self.slice_food = kw.get('slice_food', True)   # the slice is a Slice token, not an Ooze (synthesis)
        self.feeder_from = kw.get('feeder_from', 99)   # a second Digest Ooze in F1 (also in front of Aspic)
        self.feeder_every = kw.get('feeder_every', 3)  # the carry eats the feeder every N turns
        self.nell_sot = kw.get('nell_sot', True)       # synthesis: Start of Turn, eats the lowest-tier unit
        self.nell_golden_widens = kw.get('nell_golden_widens', True)

    def has(self, card, t):
        return any(card in v for k, v in self.cards.items() if k <= t)

    def gold_at(self, card, t):
        return self.golden.get(card, 99) <= t


def run(L, verbose=False):
    tier = 1
    gold = 0
    upc = UPCOST[2] + 1
    C = BODY['little_dollop']           # the carry (Dollop from R1)
    carry_is_dollop = True
    inside = []                          # meals waiting in the carry's Belly (non-Ooze unless flagged)
    sup = []                             # supports on the board: [stats, is_ooze, card]
    reserves = []                        # pot route: units inside front Bellies
    hasty_gain_next = 0.0
    feeder = None                        # [stats, meal waiting, turns held]
    out = {}
    for t in range(1, 17):
        gold += income(t)
        if t >= 2:
            upc = max(0, upc - 1)
        # ---------- Start of Turn ----------
        C += hasty_gain_next
        hasty_gain_next = 0.0
        aspic_on = L.route == 'carry' and L.has('aunt_aspic', t - 1)
        bonus = (1 + (2 * L.aspic if L.gold_at('aunt_aspic', t) else L.aspic)) if aspic_on else 1.0
        elder_on = L.has('elder_ooze', t - 1)
        e = (2 * L.e if L.gold_at('elder_ooze', t) else L.e) if elder_on else 0.0

        def eat(stats, ooze):
            nonlocal C
            if ooze:
                C += stats
                return
            C += stats * bonus
            if e:
                for u in sup:
                    if u[1]:
                        u[0] += e * stats
                if feeder is not None:
                    feeder[0] += e * stats
        for m, ooze in inside:
            eat(m, ooze)
        inside = []
        if feeder is not None:
            if feeder[1]:
                feeder[0] += feeder[1] * (bonus if L.route == 'carry' else 1.0)
                feeder[1] = 0.0
            feeder[2] += 1

        def share():
            if L.has('stone_soup', t) or L.has('stone_soup', t - 1):
                if L.gold_at('stone_soup', t):
                    oo = sorted([u[0] for u in sup if u[1]], reverse=True)
                    return L.r * (C + (oo[0] if oo else 0))
                return L.r * C
            return 0.0
        # Cut-and-Come-Again slice (a Drip, an Ooze) to hand
        slices = []
        if L.has('cut_and_come_again', t - 1):
            n = 2 if L.gold_at('cut_and_come_again', t) else 1
            slices = [L.sl * C] * n
        if L.nell_sot and L.has('dishwater_nell', t - 1):
            per = 2 if L.gold_at('dishwater_nell', t) else 1
            for i in range(per):
                meal = BASE[1] + share()
                if i == 1 and L.nell_golden_widens:
                    # the second biggest Ooze next to her eats: the feeder if there is one, else the biggest support Ooze
                    if feeder is not None:
                        feeder[0] += meal * (bonus if L.route == 'carry' else 1.0)
                    else:
                        oo = [u for u in sup if u[1]]
                        if oo:
                            max(oo, key=lambda u: u[0])[0] += meal
                else:
                    eat(meal, False)
        # ---------- Recruit ----------
        if tier < 6 and L.climb[tier - 1] <= t and gold >= upc:
            gold -= upc
            tier += 1
            upc = UPCOST.get(tier + 1, 99)
        S = share()
        shop_unit = BASE[tier] + S
        for card in L.cards.get(t, []):
            if gold < 3:
                break
            gold -= 3
            body = BODY[card] + S
            if card == 'bubble_and_squeak' and carry_is_dollop and L.route == 'carry':
                # the carry move: Bubble eats the Dollop (an Ooze: no bonus) next Start of Turn
                inside.append((C, True))
                C = body
                carry_is_dollop = False
                continue
            sup.append([body, True, card])
        meals = 2 if (L.gold_at('bubble_and_squeak', t) or (carry_is_dollop and L.gold_at('little_dollop', t))) else L.belly
        room = meals - len(inside)
        # slices first (free), then bought meals
        if L.route == 'carry':
            # the carry eats the feeder every few turns (an Ooze: stats pass whole, no bonus)
            if feeder is not None and feeder[2] >= L.feeder_every and room > 0:
                inside.append((feeder[0], True))
                room -= 1
                feeder = None
            for sl in sorted(slices, reverse=True):
                if room > 0 and sl > shop_unit:
                    inside.append((sl, not L.slice_food))
                    room -= 1
                else:
                    sup.append([sl, not L.slice_food, 'drip'])
        else:
            for sl in slices:
                sup.append([sl, True, 'drip'])
        while room > 0:
            cost = 2 if carry_is_dollop else 3
            keep = 3 if (tier < 6 and L.climb[tier - 1] == t + 1) else 0
            if gold - cost < keep and t > 2:
                break
            if gold < cost:
                break
            gold -= cost
            inside.append((shop_unit, False))
            room -= 1
        # supports: fill to 6, then replace the smallest if bigger; pot route keeps reserves
        sup.sort(key=lambda u: -u[0])
        n_slots = 6
        while gold >= 3:
            keep = 3 if (tier < 6 and L.climb[tier - 1] == t + 1) else 0
            if gold - 3 < keep:
                break
            if len(sup) < n_slots:
                gold -= 3
                sup.append([shop_unit, len(sup) % 2 == 0, 'filler'])
            elif L.route == 'pot' and len(reserves) < (4 if t >= 6 else 2):
                gold -= 3
                reserves.append(shop_unit)
            else:
                small = min(range(len(sup)), key=lambda i: (sup[i][2] != 'filler' and sup[i][2] != 'drip', sup[i][0]))
                if sup[small][0] < shop_unit and sup[small][2] in ('filler', 'drip'):
                    gold -= 3
                    gold += 1
                    sup[small] = [shop_unit, True, 'filler']
                else:
                    break
        # second stomach: a fresh Dollop as the feeder, then one meal a turn into it
        if L.route == 'carry' and t >= L.feeder_from:
            if feeder is None and gold >= 3:
                gold -= 3
                feeder = [BODY['little_dollop'] + S, 0.0, 0]
                # it takes the smallest filler's slot
                fill = [i for i in range(len(sup)) if sup[i][2] in ('filler', 'drip')]
                if fill and len(sup) >= 6:
                    sup.pop(min(fill, key=lambda i: sup[i][0])); gold += 1
            if feeder is not None and not feeder[1] and gold >= 2:
                gold -= 2
                feeder[1] = shop_unit
        # board is 6 supports + carry; extra supports go to reserves in the pot route, else are sold
        sup.sort(key=lambda u: -u[0])
        while len(sup) > n_slots:
            u = sup.pop()
            if L.route == 'pot' and len(reserves) < 4:
                reserves.append(u[0])
            else:
                gold += 1
        # ---------- End of Turn ----------
        if not L.nell_sot and L.has('dishwater_nell', t):
            fires = 2 if L.doubler <= t else 1
            per = 2 if L.gold_at('dishwater_nell', t) else 1
            for _ in range(fires * per):
                S = share()
                eat(BASE[tier] + S, False)
        # ---------- combat snapshot ----------
        n_sup = min(len(sup), 5 if feeder is not None else 6)
        board = C + sum(u[0] for u in sup[:n_sup]) + (feeder[0] if feeder is not None else 0)
        total = board + sum(m for m, _ in inside) + sum(reserves) + (feeder[1] if feeder is not None else 0)
        if L.has('hasty_pudding', t):
            hasty_gain_next = L.h * L.biggest_share * TGT.get(t, 3900)
        out[t] = dict(total=total, board=board, C=C, share=C / max(1, total), S=share(), gold=gold,
                      sup=sorted([u[0] for u in sup[:n_sup]] + ([feeder[0]] if feeder is not None else []), reverse=True),
                      inside=sum(m for m, _ in inside), reserves=list(reserves))
    return out


# ------------------------------------------------------------------ lines
CORE = {1: [], 3: ['stone_soup'], 6: ['dishwater_nell', 'bubble_and_squeak'], 7: ['moss_ooze'],
        10: ['elder_ooze'], 12: ['cut_and_come_again'], 13: ['granny_stir_up']}


def plan(base, **add):
    p = {k: list(v) for k, v in base.items()}
    for k, v in add.items():
        rd = int(k[1:])
        p.setdefault(rd, [])
        p[rd] = p[rd] + v
    return p


LINES = {
    'A typical (no Aspic)': dict(cards=CORE),
    'B with Aspic R6': dict(cards=plan(CORE, R6=['aunt_aspic'])),
    'C low roll (late Nell R8, no Aspic, late pieces)': dict(cards={3: [], 4: ['stone_soup'], 7: ['bubble_and_squeak'], 8: ['moss_ooze', 'dishwater_nell'],
                                                                    11: ['elder_ooze'], 13: ['cut_and_come_again']}),
    'C2 floor: no Nell, no Aspic': dict(cards={3: [], 4: ['stone_soup'], 7: ['bubble_and_squeak'], 8: ['moss_ooze'],
                                               11: ['elder_ooze'], 13: ['cut_and_come_again']}),
    'D Aspic + Hasty R10': dict(cards=plan(CORE, R6=['aunt_aspic'], R10=['hasty_pudding'])),
    'E Aspic + golden Soup R9 (Figgy)': dict(cards=plan(CORE, R6=['aunt_aspic'], R8=['figgy_duff']), golden={'stone_soup': 9}),
    'F Aspic + golden Aspic R9 (Figgy)': dict(cards=plan(CORE, R6=['aunt_aspic'], R8=['figgy_duff']), golden={'aunt_aspic': 9}),
    'J Aspic + golden Nell R9 (Figgy)': dict(cards=plan(CORE, R6=['aunt_aspic'], R8=['figgy_duff']), golden={'dishwater_nell': 9}),
    'G Aspic + doubler R8': dict(cards=plan(CORE, R6=['aunt_aspic'], R8=['scale_doubler']), doubler=8),
    'H golden Soup + golden Aspic R9': dict(cards=plan(CORE, R6=['aunt_aspic'], R8=['figgy_duff']),
                                            golden={'stone_soup': 9, 'aunt_aspic': 9}),
    'I 1%: golden Soup R8, Aspic R9, Nell R10, Elder R12 + Hasty': dict(cards=plan(CORE, R5=['aunt_aspic'], R7=['figgy_duff'], R10=['hasty_pudding']),
                                                           golden={'stone_soup': 8, 'aunt_aspic': 9, 'dishwater_nell': 10, 'elder_ooze': 12}),
    'P pot route (Pot Luck)': dict(route='pot', cards={3: ['stone_soup'], 5: ['sixpenny_pie'], 6: ['dishwater_nell', 'bubble_and_squeak'],
                                                        8: ['figgy_duff'], 9: ['elder_ooze'], 10: ['hasty_pudding'],
                                                        12: ['granny_stir_up', 'cut_and_come_again']}, climb=[3, 5, 7, 9, 11]),
}
BODY['scale_doubler'] = 6


def growth(r=0.1, e=0.5, h=0.2, s=0.2, aspic=0.5, rounds=(6, 9, 12, 15), lines=None, show=True, feeder_from=8, slice_food=True, nell_sot=True, widen=True):
    res = {}
    for name, kw in LINES.items():
        if lines and not any(name.startswith(x) for x in lines):
            continue
        kw = dict(kw)
        kw.setdefault('r', r); kw.setdefault('nell_sot', nell_sot); kw.setdefault('nell_golden_widens', widen); kw.setdefault('feeder_from', feeder_from); kw.setdefault('slice_food', slice_food); kw.setdefault('e', e); kw.setdefault('h', h); kw.setdefault('s', s); kw.setdefault('aspic', aspic)
        o = run(Line(**kw))
        res[name] = o
        if show:
            cells = " / ".join(f"{o[k]['total']:>7,.0f}" for k in rounds)
            xs = " / ".join(f"{o[k]['total'] / TGT[k]:.1f}" for k in rounds)
            g = (o[15]['total'] / o[8]['total']) ** (1 / 7)
            print(f"  {name:46s} {cells}   (x {xs})  carry R12 {o[12]['C'] / 2:>5.0f}/{o[12]['C'] / 2:<5.0f} {100 * o[12]['share']:3.0f}%  "
                  f"shop+ R12 {o[12]['S']:4.0f}  R8-15 x{g:.2f}/rd  gold left R15 {o[15]['gold']:.0f}")
    return res


# ------------------------------------------------------------------ fights
def load_combat():
    src = open(os.path.join(HERE, "oozes-carry-model", "ooze_combat3.py")).read()
    patches = [
        # a Belly may hold a list
        ('                    sp=u.kw["inside"]; nu=U(sp[0],sp[1],src,sp[2] if len(sp)>2 else None,start=False)\n'
         '                    place(s,nu,src,src)\n',
         '                    specs=u.kw["inside"] if isinstance(u.kw["inside"],list) else [u.kw["inside"]]\n'
         '                    for sp in specs:\n'
         '                        nu=U(sp[0],sp[1],src,sp[2] if len(sp)>2 else None,start=False)\n'
         '                        place(s,nu,src,src)\n'),
        # damage taken flag (for split_after_damage)
        ('        if t.shield: t.shield=False; return\n        t.h-=amt\n',
         '        if t.shield: t.shield=False; return\n        t.h-=amt; t.took=True\n'),
        ('            if u.kw.get("bubble") and u.h>0 and',
         '            if u.kw.get("split_after_damage") and not getattr(u,"took",False): continue\n'
         '            u.took=False\n'
         '            if u.kw.get("bubble") and u.h>0 and'),
        # Hasty: today's release after 3 friendly deaths or an empty side; Track B halving answer
        ('                    del en[big.slot]; u.held=(1-s,big)\n',
         '                    del en[big.slot]; u.held=(1-s,big); u.deaths0=deaths[s]\n'
         '    for s in (first,1-first):\n'
         '        for k in sorted(sides[s]):\n'
         '            u=sides[s].get(k)\n'
         '            if u and u.kw.get("halve_big"):\n'
         '                en=sides[1-s]\n'
         '                if en:\n'
         '                    big=max(en.values(),key=lambda v:(v.a+v.h,-v.slot))\n'
         '                    big.a=max(0,big.a-big.a//2); big.h=max(1,big.h-big.h//2); big.maxh=big.h\n'),
        ('    pointer=[-1,-1]; attacks=0; last_blow=-1; active=first\n',
         '    pointer=[-1,-1]; attacks=0; last_blow=-1; active=first; deaths=[0,0]\n'),
        ('            for u in dead: del sides[s][u.slot]\n',
         '            for u in dead: del sides[s][u.slot]\n'
         '            deaths[s]+=len(dead)\n'
         '            for hs in (0,1):\n'
         '                for hu in list(sides[hs].values()):\n'
         '                    if hu.held is not None and (deaths[hs]-getattr(hu,"deaths0",0)>=3 or len(sides[hs])==1):\n'
         '                        side_i,v=hu.held; hu.held=None\n'
         '                        v.flag = v.slot < pointer[side_i]\n'
         '                        place(side_i,v,v.slot,v.slot)\n'),
    ]
    for old, new in patches:
        assert old in src, "combat model changed; patch point not found: " + old[:60]
        src = src.replace(old, new)
    ns = {}
    exec(compile(src, "ooze_combat3_pass3", "exec"), ns)
    return ns["match"]


def total(board):
    t = 0
    for spec in board:
        if spec is None:
            continue
        t += spec[0] + spec[1]
        kw = spec[2] if len(spec) > 2 else {}
        ins = kw.get("inside")
        if ins:
            for sp in (ins if isinstance(ins, list) else [ins]):
                t += sp[0] + sp[1]
    return t


def scaled(board, k):
    out = []
    for spec in board:
        if spec is None:
            out.append(None)
            continue
        out.append((max(1, round(spec[0] * k)), max(1, round(spec[1] * k))) + tuple(spec[2:]))
    return out


EVEN = [(54, 54)] * 7
BG_FRONT = [(42, 42), (130, 130)] + [(42, 42)] * 5
BG_BACK = [(42, 42)] * 5 + [(130, 130), (42, 42)]


def sq(x):
    return (max(1, round(x / 2)), max(1, round(x / 2)))


def carry_board(o, t, granny=False, release_shield=True, carry_shield=False, layout='front'):
    """Place a carry-line snapshot on the 4-3 board. 'front': carry F2 (Aspic B1 behind it);
    'back': carry B2. Supports are the six biggest. The carry's waiting meal is inside it and
    comes out with Shield (Moss) when the carry dies."""
    x = o[t]
    sp = list(x['sup']) + [4] * 6
    ckw = {"ooze": 1, "bubble": 1, "split_after_damage": 1}
    if carry_shield:
        ckw["shield"] = 1
    if x['inside']:
        ckw["inside"] = sq(x['inside']) + (({"shield": 1},) if release_shield else ())
    carry = sq(x['C']) + (ckw,)
    sup = [sq(v) + ({"ooze": 1},) for v in sp[:6]]
    if granny:
        sup[1] = sup[1][:2] + ({"ooze": 1, "gather": 1, "cleave": 1},)
    if layout == 'front':
        return [sup[0], carry, sup[1], sup[3], sup[4], sup[2], sup[5]]
    return [sup[0], sup[1], sup[3], sup[4], sup[2], carry, sup[5]]


def pot_board(o, t, granny=True, release_shield=True, hasty=True):
    """Pot Luck: four front Bellies holding reserves (Granny takes F2 when present),
    Hasty in B1 outside the run, the pot (Bubble) in B2."""
    x = o[t]
    sp = list(x['sup']) + [4] * 6
    rv = list(x['reserves']) + [4] * 4
    rs = ({"shield": 1},) if release_shield else ()
    f = [sq(sp[1]) + ({"ooze": 1, "inside": sq(rv[0]) + rs},), sq(sp[2]) + ({"ooze": 1, "inside": sq(rv[1]) + rs},),
         sq(sp[3]) + ({"ooze": 1, "inside": sq(rv[2]) + rs},), sq(sp[4]) + ({"ooze": 1, "inside": sq(rv[3]) + rs},)]
    if granny:
        f[1] = sq(sp[2]) + ({"ooze": 1, "gather": 1, "cleave": 1},)
    b1 = sq(sp[0]) + (({"swallow": 1},) if hasty else ({"ooze": 1},))
    return f + [b1, sq(x['C']) + ({"ooze": 1, "bubble": 1, "split_after_damage": 1},), sq(sp[5]) + ({"ooze": 1},)]


def fights(n=1500):
    match = load_combat()
    res = growth(show=False)
    TG = {12: 760, 15: 2600}

    def row(label, board, t):
        k_t = TG[t] / 760
        opps = [scaled(EVEN, k_t), scaled(BG_FRONT, k_t), scaled(BG_BACK, k_t)]
        tb = total(board)
        eq = [match(board, scaled(o_, tb / total(o_)), n)[0] for o_ in opps]
        tg = [match(board, o_, n)[0] for o_ in opps]
        k = tb / total(BG_FRONT)
        ans = [match(board, scaled(BG_FRONT[:6] + [(42, 42, {"halve_big": 1})], k), n)[0],
               match(board, scaled(BG_FRONT[:6] + [(42, 42, {"swallow": 1})], k), n)[0]]
        print(f"  R{t} {label:50s} {tb:6d} ({tb / TG[t]:.2f}x) | equal {eq[0]:5.1f} {eq[1]:5.1f} {eq[2]:5.1f} "
              f"| target {tg[0]:5.1f} {tg[1]:5.1f} {tg[2]:5.1f} | answer: halve {ans[0]:5.1f} swallow {ans[1]:5.1f}")

    print("Fights. Win % for the Ooze board. 'equal': against even / BG carry F2 / BG carry B2 boards of the same total.")
    print("'target': against those boards at the target total (760 at R12, 2,600 at R15).")
    print("'answer': against a BG-shaped board of the same total whose B3 halves, or swallows, the biggest enemy at Start of Combat.")
    A = res['A typical (no Aspic)']
    B = res['B with Aspic R6']
    P = res['P pot route (Pot Luck)']
    for t in (12, 15):
        row("A no Aspic: carry B2, split", carry_board(A, t, layout='back'), t)
        row("B Aspic: carry F2, split, meal comes out Shielded", carry_board(B, t), t)
        row("B with the carry design's Shield ON the carry", carry_board(B, t, carry_shield=True), t)
        row("B + Granny (touching, Attack, Cleave)", carry_board(B, t, granny=True), t)
        row("P Pot Luck: Bellies, Moss, Hasty, Granny", pot_board(P, t), t)
        row("P Pot Luck without Granny", pot_board(P, t, granny=False), t)
        row("P Pot Luck without Moss", pot_board(P, t, release_shield=False), t)


def sweeps():
    def x(o, t):
        return o[t]['total'] / TGT[t]
    print("Sweep r (Stone Soup's share). R12/R15 x target:")
    for r in (1 / 12, 1 / 10, 1 / 8):
        res = growth(r=r, show=False)
        print(f"  r={r:.3f}  " + "  ".join(f"{k.split()[0]} {x(v, 12):.2f}/{x(v, 15):.2f}" for k, v in res.items()))
    print("Sweep e (Elder's share of a meal), line B: R12/R15 x target, carry share R12")
    for e in (0.25, 1 / 3, 0.5):
        o = growth(e=e, show=False)['B with Aspic R6']
        print(f"  e={e:.3f}: {x(o, 12):.2f} / {x(o, 15):.2f}   carry {100 * o[12]['share']:.0f}%")
    print("Sweep h (Hasty's share to your biggest Ooze), line D:")
    for h in (0.1, 0.2, 0.25):
        o = growth(h=h, show=False)['D Aspic + Hasty R10']
        print(f"  h={h:.2f}: {x(o, 12):.2f} / {x(o, 15):.2f}")
    print("Sweep s (the Slice), line B:")
    for s_ in (0.1, 0.2, 0.25):
        o = growth(s=s_, show=False)['B with Aspic R6']
        print(f"  s={s_:.2f}: {x(o, 12):.2f} / {x(o, 15):.2f}")
    print("Ablations, line B, R12/R15 x target:")
    for label, kw in (("synthesis", {}), ("Nell at End of Turn, golden doubles (carry design)", dict(nell_sot=False, widen=False)),
                      ("Slice is an Ooze (no Aspic, no Elder)", dict(slice_food=False)), ("no second stomach", dict(feeder_from=99))):
        res = growth(show=False, **kw)
        b, g, j = res['B with Aspic R6'], res['G Aspic + doubler R8'], res['J Aspic + golden Nell R9 (Figgy)']
        print(f"  {label:52s} B {x(b, 12):.2f}/{x(b, 15):.2f}   doubler G {x(g, 12):.2f}/{x(g, 15):.2f}   golden Nell J {x(j, 12):.2f}/{x(j, 15):.2f}")


if __name__ == "__main__":
    which = sys.argv[1:] or ["growth", "fights"]
    if "growth" in which:
        print("Board at combat start, insides counted (R6 / R9 / R12 / R15), x target means 53/194/759/2600")
        growth()
        print()
        sweeps()
        print()
    if "fights" in which:
        fights()
