# Toy vanilla combat on Bramble's 4-3 board (rulebook 9.2, 9.4.2, 9.4.5 without summons, 9.5.1, 9.5.5, 9.6).
# Slots 0-3 front F1-F4, 4-6 back B1-B3. Board = list of 7 (atk, hp) or None.
import random, sys
def fight(A, B, rng):
    a = [list(x) if x else None for x in A]; b = [list(x) if x else None for x in B]
    sides = [a, b]
    na = sum(1 for x in a if x); nb = sum(1 for x in b if x)
    turn = 0 if na > nb else 1 if nb > na else rng.randrange(2)
    ptr = [-1, -1]
    for _ in range(200):
        s = sides[turn]; o = sides[1-turn]
        if not any(s) : return 1-turn if any(o) else -1
        if not any(o): return turn
        # next attacker after pointer
        cand = [i for i in range(7) if s[i] and s[i][0] > 0]
        if not cand:
            turn = 1-turn; continue
        nxt = [i for i in cand if i > ptr[turn]]
        i = nxt[0] if nxt else cand[0]
        ptr[turn] = i
        front = [j for j in range(4) if o[j]]
        targets = front if front else [j for j in range(4,7) if o[j]]
        j = rng.choice(targets)
        att = s[i]; de = o[j]
        att[1] -= de[0]; de[1] -= att[0]
        if att[1] <= 0: s[i] = None
        if de[1] <= 0: o[j] = None
        if not any(a) and not any(b): return -1
        if not any(a): return 1
        if not any(b): return 0
        turn = 1-turn
    return -1
def wr(A, B, n=4000, seed=1):
    rng = random.Random(seed); w=l=t=0
    for _ in range(n):
        r = fight(A, B, rng)
        if r == 0: w+=1
        elif r == 1: l+=1
        else: t+=1
    return (w + 0.5*t)/n
def even(total, k=7, ashare=0.5):
    per = total / k; at = round(per*ashare); hp = round(per) - at
    return [(at, max(1,hp))]*k
def board(units):
    # units: list of (a,h); place first four front, rest back
    out = [None]*7
    for idx,u in enumerate(units): out[idx] = u
    return out
if __name__ == '__main__':
    print('Owner example, our rules: 3 x 10/11 vs 5 x 10/10')
    A = [(10,11),(10,11),(10,11),None,None,None,None]
    B = [(10,10),(10,10),(10,10),(10,10),(10,10),None,None]
    print(' 3 front:', wr(A,B))
    A2 = [(10,11),(10,11),None,None,(10,11),None,None]
    print(' 2 front 1 back:', wr(A2,B))
    for total in (70, 140, 700):
        per = total//7
        base = [(per//2, per - per//2)]*7
        print(f'\nTotal {total} SP, opponent 7 x {per//2}/{per-per//2}')
        # +14 SP spread vs concentrated
        add = total//5
        spread_each = add//7
        spread = [(per//2 + spread_each//2, per-per//2 + spread_each - spread_each//2)]*7
        print(f' baseline mirror {wr(board(base), board(base)):.3f}')
        print(f' +{spread_each}/each spread ({spread_each*7} SP): {wr(board(spread), board(base)):.3f}')
        for slot in (0, 4):
            conc = list(base); h = add//2
            conc[slot] = (per//2 + h, per-per//2 + add - h)
            print(f' +{add} SP on one unit in {"F1" if slot==0 else "B1"}: {wr(board(conc), board(base)):.3f}')
        # equal total, concentration share sweep
        print(' equal total, one big unit holding share f, rest even; vs even board')
        for f in (1/7, 0.25, 0.35, 0.5, 0.65, 0.8):
            big = total*f; rest = (total-big)/6
            for slot in (0,4):
                u = [(round(rest/2), max(1,round(rest/2)))]*7
                u = list(u); u[slot] = (round(big/2), round(big/2))
                print(f'   f={f:.2f} big in {"F1" if slot==0 else "B1"}: {wr(u, board(base)):.3f}', end='')
            print()
        # fewer, bigger units, same total
        print(' same total on fewer units vs 7 even')
        for k in (3,4,5,6,7):
            per2 = total/k; u=[(round(per2/2), round(per2/2))]*k + [None]*(7-k)
            print(f'   {k} units of {round(per2/2)}/{round(per2/2)}: {wr(u, board(base)):.3f}')
