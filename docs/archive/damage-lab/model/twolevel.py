# Two-level loss at 100 health. BIG loss if more than half of the winner's starting units survive,
# SMALL loss otherwise. Starting units = winner's board at combat start (tokens played before combat count,
# combat summons don't). Toy lobby: 8 live players, skill + drifting strength, 2 units turn 1, 7 from turn 6.
import random, statistics as st, itertools, math
UNITS=lambda t: min(7,t+1)
def lobby(big,r,rng):
    skill=[rng.gauss(0,0.6) for _ in range(8)]; walk=[0.0]*8
    hp=[100.0]*8; alive=set(range(8)); losses=[0]*8; out={}; t=0; rec=[]
    while len(alive)>1 and t<40:
        t+=1
        for i in alive: walk[i]+=rng.gauss(0,0.35)
        a=list(alive); rng.shuffle(a)
        pairs=[(a[k],a[k+1]) for k in range(0,len(a)-1,2)]+([(a[-1],None)] if len(a)%2 else [])
        for x,y in pairs:
            py=(skill[y]+walk[y]) if y is not None else rng.gauss(0,0.6)
            gap=skill[x]+walk[x]-py; m=gap+rng.gauss(0,1)
            lose=(y if m>0 else x)
            if lose is None: continue
            n=UNITS(t); surv=max(1,min(n,round(abs(m)*2.2+rng.uniform(0,1.5))))
            isbig = surv*2>n
            d=big(t)*(1 if isbig else r); hp[lose]-=d; losses[lose]+=1
            rec.append((t,d,isbig,abs(gap)))   # abs(gap): how outclassed the loser was before the fight
        for i in list(alive):
            if hp[i]<=0: alive.discard(i); out[i]=t
    return t,(min(out.values()) if out else t),[losses[i] for i in out],rec
def run(big,r,n,seed=0):
    rng=random.Random(seed); R=[lobby(big,r,rng) for _ in range(n)]
    L=sorted(x[0] for x in R); F=sorted(x[1] for x in R); q=lambda v,p:v[int(p*len(v))]
    lo=[x for z in R for x in z[2]]; rec=[x for z in R for x in z[3]]
    return dict(L=(q(L,.1),q(L,.5),q(L,.9)),F=(q(F,.1),q(F,.5),q(F,.9)),
                le2=sum(l<=2 for l in lo)/len(lo), le3=sum(l<=3 for l in lo)/len(lo), rec=rec)
def curve(e,R,ramp):  # big-loss % : e at round 1, rising linearly to 25 at round R, then +ramp per round
    return lambda t: (e+(25-e)*(t-1)/(R-1)) if t<=R else 25+ramp*(t-R)
if __name__=='__main__':
    res=[]
    for e,R,ramp,r in itertools.product([3,5,8],[9,11,13],[0,3,6],[0.4,0.5,0.6]):
        o=run(curve(e,R,ramp),r,600)
        score=abs(o['L'][1]-14)+max(0,8-o['F'][1])*2+o['le2']*100
        res.append((score,e,R,ramp,r,o['L'],o['F'],o['le2'],o['le3']))
    res.sort()
    print("big@r1  reaches25@round  ramp/round-after  small=r*big | game p10/med/p90  first-out p10/med/p90  out<=2losses  out<=3losses")
    for s,e,R,ramp,r,L,F,l2,l3 in res[:12]:
        print(f"{e:>5}%  {R:>8}  {ramp:>8}%  {r:>10} | {L}  {F}  {l2:.1%}  {l3:.1%}")
