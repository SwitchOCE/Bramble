import sys, json, random; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
def ceil(a,b): return -(-a//b)
units=[u for b in boards.values() for u in b if u]
rng=random.Random(2)
for k in (1,10):
    def sc(u): return u if k==1 else (max(1,u[0]*k+rng.randint(-(k//2),k//2)), max(1,u[1]*k+rng.randint(-(k//2),k//2)))
    us=[sc(u) for u in units]
    pa=ph=n=0
    for (a,h) in us:
        for (A,H) in us:
            if A==0 or a==0: continue
            n+=1
            if ceil(H,a+1)<ceil(H,a): pa+=1      # +1 Attack saves a hit on this enemy
            if ceil(h+1,A)>ceil(h,A): ph+=1      # +1 Health survives one more hit from this enemy
    print(f'scale x{k}: of {n} unit-vs-unit pairs, +1 Attack cuts the hits needed in {100*pa/n:.1f}%; +1 Health adds a hit survived in {100*ph/n:.1f}%')
a_=[u[0] for u in units]; h_=[u[1] for u in units]
import statistics as st
print('R9 board units: attack median',st.median(a_),'range',min(a_),max(a_),'; health median',st.median(h_),'range',min(h_),max(h_))
