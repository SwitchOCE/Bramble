# Owner's settings: small = min(20, 4 + 2*(t-1)) % of 100, big = 1.5 x small, ~5% draws.
# Find integer schedules on lower starting health that play out about the same.
import random, statistics as st, math
UNITS=lambda t: min(7,t+1)
def lobby(H,sm,bg,rng,delta=0.11):
    skill=[rng.gauss(0,.6) for _ in range(8)]; walk=[0.]*8; hp=[float(H)]*8; alive=set(range(8)); loss=[0]*8; out={}; t=0; late=[]
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
            d=bg(t) if s*2>n else sm(t); hp[lose]-=d; loss[lose]+=1
            if t>=12: late.append(d/H)
        for i in list(alive):
            if hp[i]<=0: alive.discard(i); out[i]=t
    return t,min(out.values()),[loss[i] for i in out],late
def run(name,H,sm,bg,n=3000):
    rng=random.Random(5); R=[lobby(H,sm,bg,rng) for _ in range(n)]
    L=sorted(r[0] for r in R); F=sorted(r[1] for r in R); q=lambda v,p: v[int(p*len(v))]
    lo=[x for r in R for x in r[2]]; late=sorted(x for r in R for x in r[3])
    sched=" ".join(f"{sm(t):g}/{bg(t):g}" for t in range(1,11))
    print(f"{name}\n   health {H}; small/big rounds 1-10: {sched}\n   game {q(L,.1)}/{q(L,.5)}/{q(L,.9)}  first-out {q(F,.1)}/{q(F,.5)}/{q(F,.9)}  "
          f"out<=3 losses {sum(l<=3 for l in lo)/len(lo):.1%}  out<=2 {sum(l<=2 for l in lo)/len(lo):.1%}  bad late loss {q(late,.9):.0%}")
ref_s=lambda t: min(20,4+2*(t-1))
run("REFERENCE (your settings)",100,ref_s,lambda t: 1.5*ref_s(t))
s50=lambda t: min(10,t+1)
run("50: small = round+1 (max 10), big = 1.5x rounded up",50,s50,lambda t: math.ceil(1.5*s50(t)))
run("50: small = round+1 (max 10), big = 1.5x rounded down",50,s50,lambda t: math.floor(1.5*s50(t)))
run("50: small = round+1 (max 10), big = small+3",50,s50,lambda t: s50(t)+3)
s40=lambda t: min(8,(t+3)//2+ (t>=2))   # 2,3,3,4,4,5,5,6,6,7..8
s40=lambda t: min(8, round(1.6+0.8*(t-1)+1e-9))
run("40: small rounded from 4%+2%/round (max 8), big = 1.5x rounded",40,s40,lambda t: round(1.5*s40(t)+1e-9))
s30=lambda t: min(6, round(1.2+0.6*(t-1)+1e-9))
run("30: small rounded from 4%+2%/round (max 6), big = 1.5x rounded",30,s30,lambda t: round(1.5*s30(t)+1e-9))
s25=lambda t: min(5, t//2+1)
run("25: small = half the round +1 (max 5), big = 1.5x rounded up",25,s25,lambda t: math.ceil(1.5*s25(t)))
run("25: small = half the round +1 (max 5), big = small+2",25,s25,lambda t: s25(t)+2)
s20=lambda t: min(4,(t+2)//3+ (0))  # 1,1,1,2,2,2,3,3,3,4
s20=lambda t: min(4, (t+1)//2) if t>1 else 1
run("20: small = half the round rounded up (max 4), big = small+2",20,s20,lambda t: s20(t)+2)
run("20: small = half the round rounded up (max 4), big = 1.5x rounded up",20,s20,lambda t: math.ceil(1.5*s20(t)))
