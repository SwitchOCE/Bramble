import random, statistics as st
random.seed(2)
UNITS=lambda t: min(7,t+1)
def lobby(H,base,w):
    skill=[random.gauss(0,0.6) for _ in range(8)]; walk=[0.0]*8
    hp=[H]*8; alive=set(range(8)); losses=[0]*8; out={}; t=0; rec=[]
    while len(alive)>1 and t<40:
        t+=1
        for i in alive: walk[i]+=random.gauss(0,0.35)
        a=list(alive); random.shuffle(a)
        pairs=[(a[k],a[k+1]) for k in range(0,len(a)-1,2)]+([(a[-1],None)] if len(a)%2 else [])
        for x,y in pairs:
            py=(skill[y]+walk[y]) if y is not None else random.gauss(0,0.6)
            m=skill[x]+walk[x]-py+random.gauss(0,1)
            lose=(y if m>0 else x)
            if lose is None: continue
            surv=max(1,min(UNITS(t),round(abs(m)*2.2+random.uniform(0,1.5))))
            d=base(t)+w*surv; hp[lose]-=d; losses[lose]+=1; rec.append((t,d,w*surv,d/H))
        for i in list(alive):
            if hp[i]<=0: alive.discard(i); out[i]=t
    return t,min(out.values()),[losses[i] for i in out],rec
def step(table):
    return lambda t: next(v for r,v in sorted(table.items(),reverse=True) if t>=r)
def report(name,H,base,w=1,n=3000):
    R=[lobby(H,base,w) for _ in range(n)]
    L=sorted(r[0] for r in R); F=sorted(r[1] for r in R); q=lambda v,p:v[int(p*len(v))]
    lo=[x for r in R for x in r[2]]; rec=[x for r in R for x in r[3]]
    def ph(a,b):
        s=[x for x in rec if a<=x[0]<=b]
        if not s: return "-"
        return f"{st.mean(x[3] for x in s):.0%} avg, {sorted(x[3] for x in s)[int(.9*len(s))]:.0%} bad, units {st.mean(x[2]/x[1] for x in s):.0%}"
    print(f"\n{name}\n  game p10/med/p90 {q(L,.1)}/{q(L,.5)}/{q(L,.9)}  first-out {q(F,.1)}/{q(F,.5)}/{q(F,.9)}  out with <=3 losses {sum(l<=3 for l in lo)/len(lo):.1%}")
    for a,b in ((1,4),(5,8),(9,11),(12,40)): print(f"  rounds {a}-{b}: loss = {ph(a,b)} of health")
# TFT live: 100 HP, stage base 2/5/8/10/12/17, +1 per surviving enemy. ~5 PvP rounds per stage (not checked).
# Bramble has about half TFT's fights, so map 2 Bramble rounds to 1 TFT stage and halve health.
tftmap={1:2,3:5,5:8,7:10,9:12,11:17}
report("TFT curve, 2 rounds per stage, 50 HP", 50, step(tftmap))
report("TFT curve, 2 rounds per stage, 40 HP", 40, step(tftmap))
report("TFT curve, ramp past 17 (+4/round from round 13), 50 HP", 50, lambda t: step(tftmap)(t)+max(0,4*(t-12)))
report("Softer start, TFT mid, ramp from 11, 50 HP", 50, step({1:1,3:3,5:6,7:9,9:11,11:14,12:17,13:21,14:25,15:30}))
