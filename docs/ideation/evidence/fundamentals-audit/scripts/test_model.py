import random, itertools, sys
sys.path.insert(0, '.')
from bramble_combat import *

def B(units, slots=None):
    b=[None]*7
    slots = slots or [0,1,2,3,4,5,6]
    for s,u in zip(slots,units): b[s]=u
    return b

rng=random.Random(5)
# 1. Owner example: 3x 10/11 vs 5x 10/10, every placement combination for the 3-board
results=set()
for slots3 in itertools.combinations(range(7),3):
    for slots5 in [(0,1,2,3,4),(0,1,2,3,5),(0,1,4,5,6),(1,2,4,5,6)]:
        A=B([(10,11)]*3, list(slots3)); Bb=B([(10,10)]*5, list(slots5))
        for i in range(200):
            r=fight(A,Bb,rng)
            results.add((r['winner'], r['survivors'], r['reason']))
print('owner example outcomes over all 3-unit placements x 4 five-unit layouts x 200 fights:', results)

# 2. Check the deterministic 'lives' law on random uniform boards
bad=0; checked=0
for trial in range(3000):
    n0=rng.randint(1,7); n1=rng.randint(1,7)
    a0,h0,a1,h1=[rng.randint(1,20) for _ in range(4)]
    A=B([(a0,h0)]*n0); Bb=B([(a1,h1)]*n1)
    L0=n0*-(-h0//a1); L1=n1*-(-h1//a0)
    r=fight(A,Bb,rng)
    checked+=1
    if L0>L1 and r['winner']!=0: bad+=1
    if L1>L0 and r['winner']!=1: bad+=1
    if L0==L1 and r['reason']!='last_blow': bad+=1
    if L0>L1 and r['survivors']<1: bad+=1
print('lives law violations:',bad,'of',checked)

# 3. Attack order check (9.4.2/9.4.5): instrument a fight with units F1,F3,B2 vs a wall
# Use 1-attack units vs a single huge 0-attack wall so nobody dies; record attacker slots.
import bramble_combat as bc
order=[]
orig=bc.fight
A=B([(1,100),(1,100),(1,100)],[0,2,5]); W=B([(1,1000)],[0])
# monkeypatch: replicate choose order by running with attack_limit small and tracing via random seed
class R(random.Random):
    pass
# simple trace: copy of logic
def trace(board, n):
    side={k:U(v[0],v[1],k) for k,v in enumerate(board) if v}
    out=[]
    for _ in range(n):
        units=[side[k] for k in sorted(side)]
        att=next((u for u in units if not u.flag),None)
        if att is None:
            for u in units: u.flag=False
            att=units[0]
        for u in units:
            if u.slot<=att.slot: u.flag=True
        out.append(['F1','F2','F3','F4','B1','B2','B3'][att.slot])
    return out
print('attack order F1,F3,B2:',trace(A,7))
