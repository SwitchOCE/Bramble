"""Breaker probes for the Hedgerow pass 3 engine design (9 Nov 2026). Run: python3 -I hedgerow-breaker-fight.py
Rough Bramble combat: 4-3 board, reading order F1-F4,B1-B3, back-row protection,
random target among attackable row, simultaneous exchange, Hunker (defender, ceil half),
Bristle X (enemy that hits this in an attack takes X), Last Blow to attacker on mutual wipe.
Start of Combat: optional 'halve' (Sergeant Stash) on enemy slot across. No summons."""
import random, math
ORDER = ["F1","F2","F3","F4","B1","B2","B3"]
def unit(total, a_share=0.5, **kw):
    a = max(1, round(total*a_share)); h = max(1, total-a)
    return dict(a=a, h=h, **kw)
def fight(A, B, rng, soc=None):
    A = {s: dict(u) for s,u in A.items()}; B = {s: dict(u) for s,u in B.items()}
    sides = [A, B]
    if soc: soc(A, B)
    n = [len(A), len(B)]
    turn = 0 if n[0] > n[1] else 1 if n[1] > n[0] else rng.randrange(2)
    ptr = [0, 0]; flags = [set(), set()]
    for _ in range(400):
        me, op = sides[turn], sides[1-turn]
        if not me: return 1-turn
        if not op: return turn
        can = [s for s in ORDER if s in me and me[s]["a"] > 0]
        if not can:
            if not [s for s in ORDER if s in op and op[s]["a"]>0]: return -1
            turn = 1-turn; continue
        cand = [s for s in can if s not in flags[turn]]
        if not cand:
            flags[turn] = set(); cand = can
        s = cand[0]; i = ORDER.index(s)
        flags[turn] |= {x for x in ORDER[:i+1]}
        front = [t for t in ORDER[:4] if t in op]
        pool = front if front else [t for t in ORDER[4:] if t in op]
        t = rng.choice(pool)
        att, dfn = me[s], op[t]
        dmg_to_def = att["a"]
        if dfn.get("hunker"): dmg_to_def = math.ceil(dmg_to_def/2)
        dmg_to_att = dfn["a"] + dfn.get("bristle", 0)
        dmg_to_def += att.get("bristle", 0) if False else 0
        dfn["h"] -= dmg_to_def; att["h"] -= dmg_to_att
        if att.get("bristle"): pass
        # bristle on attacker: the defender hits it, takes bristle back
        if att.get("bristle"): dfn["h"] -= att["bristle"]
        dead_me = att["h"] <= 0; dead_op = dfn["h"] <= 0
        if dead_me: del me[s]
        if dead_op: del op[t]
        if not me and not op: return turn  # Last Blow
        turn = 1-turn
    return -1
def rate(A, B, n=4000, soc=None, seed=1):
    rng = random.Random(seed); w=l=t=0
    for _ in range(n):
        r = fight(A, B, rng, soc)
        if r == 0: w+=1
        elif r == 1: l+=1
        else: t+=1
    return w/n, t/n, l/n
def even(total, k=7):
    slots = ORDER[:k] if k<=7 else ORDER
    per = total/k
    return {s: unit(per) for s in ORDER[:k]}
def supper(dozey, rest, hunker=True, slots=None):
    # rest: list of totals for F1,F2(Urchin, bristle 2),F3,B1,B2 ; Dozey in B3, F4 empty
    lay = ["F1","F2","F3","B1","B2"] if slots is None else slots
    b = {}
    for s, v in zip(lay, rest):
        b[s] = unit(v)
    if "F2" in b: b["F2"]["bristle"] = 2
    b["B3"] = unit(dozey, hunker=hunker)
    return b
def part1():
    # R9 on time: Dozey 174, Pym 12 F1, Urchin 14 F2, Mallow 8 F3, Partner 13 B1, Sorrel 10 B2
    S9 = supper(174, [12,14,8,13,10]); S9n = supper(174, [12,14,8,13,10], hunker=False)
    L9 = supper(86, [12,7,8,17,10]); L9n = supper(86, [12,7,8,17,10], hunker=False)
    for name, S in [("R9 on-time Supper (231) Hunker", S9), ("R9 on-time no Hunker", S9n),
                    ("R9 late Supper (140) Hunker", L9), ("R9 late no Hunker", L9n)]:
        for tot in (140, 158, 213, 231):
            print(f"{name:34s} vs even 7x{tot/7:5.1f} ({tot}): win/tie/loss", tuple(round(x,2) for x in rate(S, even(tot))))
    # Sergeant Stash halves Dozey (enemy has Sergeant across B3)
    def halve(A, B):
        d = A["B3"]; d["a"] = d["a"]//2; d["h"] = max(1, d["h"]//2)
    for tot in (158, 213):
        print(f"R9 on-time, Dozey halved by a Stash vs even {tot}:", tuple(round(x,2) for x in rate(S9, even(tot), soc=halve)))


def part2():
    S9 = supper(174, [12,14,8,13,10])
    print("R9 on-time Hunker: even-board totals")
    for tot in (260, 300, 340, 380, 420):
        print(" ", tot, tuple(round(x,2) for x in rate(S9, even(tot), n=2000)))
    # R12 on time: Dozey 505 in F4 (Hunker), Committee F1 94, Urchin F2 96 (bristle), Mallow F3 98, Partner B1 95, Lollop B2 125, Hayward B3 93
    def r12(dz, others, hunker=True):
        b = {"F1": unit(others[0]), "F2": unit(others[1], bristle=2), "F3": unit(others[2]),
             "F4": unit(dz, hunker=hunker), "B1": unit(others[3]), "B2": unit(others[4]), "B3": unit(others[5])}
        return b
    S12 = r12(505, [94,96,98,95,125,93])
    print("R12 on-time (1105) vs even")
    for tot in (531, 717, 1105, 1400):
        print(" ", tot, tuple(round(x,2) for x in rate(S12, even(tot), n=2000)))
    def halveF4(A,B):
        d=A["F4"]; d["a"]//=2; d["h"]=max(1,d["h"]//2)
    print("R12 on-time, Dozey halved vs even 717:", tuple(round(x,2) for x in rate(S12, even(717), n=2000, soc=halveF4)))
    # R12 late: Dozey 227 in B3 (pre-wake), others small
    L12 = supper(227, [19,21,23,24,27,18][:5]) ; L12["F4"]=unit(18)
    print("R12 late (359) vs even 359/531:", [tuple(round(x,2) for x in rate(L12, even(t), n=2000)) for t in (359,531)])
    # Parish R12 758 even-ish vs typical
    return r12


def part3(r12):
    S12 = r12(505, [94,96,98,95,125,93])
    def zero(A,B):
        d=A["F4"]; d["a"]=0; d["h"]=1
    for tot in (531, 717, 900):
        print("R12 on-time, Dozey 0/1 vs even", tot, tuple(round(x,2) for x in rate(S12, even(tot), n=2000, soc=zero)))
    # R9 typical boards: how big must an even board be to beat R9 Hunker Dozey ALONE (no friends)?
    solo = {"B3": unit(174, hunker=True)}
    for tot in (200, 260, 300, 340):
        print("Dozey 174 alone + Hunker vs even", tot, tuple(round(x,2) for x in rate(solo, even(tot), n=2000)))


def treasury():
    # Treasury line: hold everything from R1; Partner stash every 3 turns from R1; back Sorrel from R5 (1/fight, 1.5 from R9);
    # Mast from R12 (mult=1 or 2 for golden); Treasurer from R8: +1/+1 per gold held each End of Turn (k=1 or 2)
    def run(mast_mult=1, mast_from=12, treas_k=1, partners=1):
        a=s=h=0; due=0.0; treas=8; out={}
        def gain(kind,n):
            nonlocal a,s,h
            if kind=='a': a+=n
            else: s+=n
            while a>=3: a-=3; s+=1
            while s>=3: s-=3; h+=1
        for r in range(1,17):
            if r>=mast_from: gain('a', mast_mult*(s+3*h))
            w=int(due); due-=w; gain('a',w)
            L=a+5*s+16*h
            if r>=8: treas += 2*treas_k*L
            if r%3==0: gain('s',partners)
            if r>=5: due += 1.0 if r<9 else 1.5
            out[r]=(a+5*s+16*h, treas)
        return out
    for args in [(1,12,1,1),(2,12,1,1),(1,12,2,1),(2,12,2,2)]:
        o=run(*args); print(args, {r:o[r] for r in (9,12,13,14,15,16)})


if __name__ == '__main__':
    part1(); r12 = part2(); part3(r12); print('Treasury hold line (args: mast_mult, mast_from, treasurer_k, partners) -> {round: (larder gold, Treasurer stats)}'); treasury()
