# 40 health. Big loss = small + 3. Small if the loser killed at least half the winner's starting units.
# avoid = share of would-be big losses the loser turns into small ones by playing properly (not greeding).
import random, statistics as st
UNITS=lambda t: min(7,t+1)
def lobby(sm,avoid,rng,H=40,delta=0.11):
    skill=[rng.gauss(0,.6) for _ in range(8)]; walk=[0.]*8; hp=[float(H)]*8; alive=set(range(8)); loss=[0]*8; out={}; t=0; nb=nl=0
    while len(alive)>1 and t<40:
        t+=1
        for i in alive: walk[i]+=rng.gauss(0,.35)
        A=list(alive); rng.shuffle(A)
        pairs=[(A[k],A[k+1]) for k in range(0,len(A)-1,2)]+([(A[-1],None)] if len(A)%2 else [])
        for x,y in pairs:
            py=(skill[y]+walk[y]) if y is not None else rng.gauss(0,.6)
            m=skill[x]+walk[x]-py+rng.gauss(0,1)
            if abs(m)<delta: continue
            lose=y if m>0 else x
            if lose is None: continue
            n=UNITS(t); s=max(1,min(n,round(abs(m)*2.2+rng.uniform(0,1.5))))
            big = s*2>n and rng.random()>=avoid
            d=sm(t)+(3 if big else 0); hp[lose]-=d; loss[lose]+=1; nl+=1; nb+=big
        for i in list(alive):
            if hp[i]<=0: alive.discard(i); out[i]=t
    return t,min(out.values()),[loss[i] for i in out],nb/max(1,nl)
def run(sm,avoid,n=2500):
    rng=random.Random(9); R=[lobby(sm,avoid,rng) for _ in range(n)]
    L=sorted(r[0] for r in R); F=sorted(r[1] for r in R); q=lambda v,p: v[int(p*len(v))]
    lo=[x for r in R for x in r[2]]
    return f"game {q(L,.1)}/{q(L,.5)}/{q(L,.9)} first-out {q(F,.1)}/{q(F,.5)}/{q(F,.9)} out<=2 {sum(l<=2 for l in lo)/len(lo):.1%} out<=3 {sum(l<=3 for l in lo)/len(lo):.1%} big {st.mean(r[3] for r in R):.0%}"
table=[2,2,3,4,5,6,6,7,8,8]
C={
 "Table 2 2 3 4 5 6 6 7 8 8, max 8": lambda t: table[min(t,10)-1],
 "Round + 1, max 8":                 lambda t: min(8,t+1),
 "Stage + 1 (stage = 2 rounds), no max": lambda t: (t+1)//2+1,
 "Stage + 1, max 8":                 lambda t: min(8,(t+1)//2+1),
 "Stage + 2, no max":                lambda t: (t+1)//2+2,
 "Round + 1, no max":                lambda t: t+1,
}
for name,f in C.items():
    print(name, "| rounds 1-14:", " ".join(str(f(t)) for t in range(1,15)))
    for av,lab in ((1.0,"everyone avoids big losses"),(0.5,"half of big losses avoided"),(0.0,"toy mix, nobody avoids")):
        print(f"   {lab:28s} {run(f,av)}")
