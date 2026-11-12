# New rules: small loss = 4 + a*(t-1) + b*max(0,t-K+1) (capped); big = 1.5 x small.
# Small if loser killed at least half the winner's starting units (surv*2 <= n). Draw: both take 0.
import random, statistics as st, itertools
UNITS=lambda t: min(7,t+1)
def small(t,a,K,b,cap): return min(cap, 4+a*(t-1)+b*max(0,t-K+1))
def lobby(a,K,b,cap,delta,rng):
    skill=[rng.gauss(0,.6) for _ in range(8)]; walk=[0.]*8; hp=[100.]*8; alive=set(range(8)); loss=[0]*8; out={}; t=0; draws=fights=0
    while len(alive)>1 and t<40:
        t+=1
        for i in alive: walk[i]+=rng.gauss(0,.35)
        A=list(alive); rng.shuffle(A)
        pairs=[(A[k],A[k+1]) for k in range(0,len(A)-1,2)]+([(A[-1],None)] if len(A)%2 else [])
        for x,y in pairs:
            py=(skill[y]+walk[y]) if y is not None else rng.gauss(0,.6)
            m=skill[x]+walk[x]-py+rng.gauss(0,1); fights+=1
            if abs(m)<delta: draws+=1; continue
            lose=y if m>0 else x
            if lose is None: continue
            n=UNITS(t); s=max(1,min(n,round(abs(m)*2.2+rng.uniform(0,1.5))))
            d=small(t,a,K,b,cap)*(1.5 if s*2>n else 1); hp[lose]-=d; loss[lose]+=1
        for i in list(alive):
            if hp[i]<=0: alive.discard(i); out[i]=t
    return t,min(out.values()),[loss[i] for i in out],draws/fights
def run(a,K,b,cap,delta=0.1,n=500,seed=3):
    rng=random.Random(seed); R=[lobby(a,K,b,cap,delta,rng) for _ in range(n)]
    L=sorted(r[0] for r in R); F=sorted(r[1] for r in R); lo=[x for r in R for x in r[2]]
    return st.median(L),st.median(F),sum(l<=3 for l in lo)/len(lo),st.mean(r[3] for r in R)
print("a K b | game first-out out<=3 draw-share")
for a,K,b in [(1,99,0),(1.5,99,0),(2,99,0),(1,10,2),(1,9,3),(0.75,10,3),(1,11,3),(1.25,10,2),(0.5,9,3)]:
    print(a,K,b,"|",*[f"{v:.3g}" for v in run(a,K,b,60)])
