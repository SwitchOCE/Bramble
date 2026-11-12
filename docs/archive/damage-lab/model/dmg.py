# Toy 8-player lobby: fixed skill + drifting board strength; win prob from strength gap.
# Damage on a loss = base(round) + w * winner's survivors. Survivors grow with the margin.
import random, statistics as st, sys
random.seed(1)
UNITS=lambda t: min(7, t+1)          # 2 units on turn 1, full 7 by turn 6
def lobby(H, base, w, sk=0.6, drift=0.35, noise=1.0):
    skill=[random.gauss(0,sk) for _ in range(8)]; walk=[0.0]*8
    hp=[H]*8; alive=set(range(8)); losses=[0]*8; out_round={}; fights=[0]*8
    t=0; perf_share=[]; dmg_seen=[]
    while len(alive)>1 and t<40:
        t+=1
        for i in alive: walk[i]+=random.gauss(0,drift)
        a=list(alive); random.shuffle(a)
        pairs=[(a[k],a[k+1]) for k in range(0,len(a)-1,2)]
        if len(a)%2: pairs.append((a[-1],None))  # ghost: random past-player strength
        for x,y in pairs:
            px=skill[x]+walk[x]; py=(skill[y]+walk[y]) if y is not None else random.gauss(0,sk)
            m=px-py+random.gauss(0,noise)
            fights[x]+=1
            if y is not None: fights[y]+=1
            win,lose=(x,y) if m>0 else (y,x)
            surv=max(1,min(UNITS(t),round(abs(m)*2.2+random.uniform(0,1.5))))
            if lose is None: continue
            d=base(t)+w*surv
            hp[lose]-=d; losses[lose]+=1; perf_share.append(w*surv/d); dmg_seen.append(d)
        for i in list(alive):
            if hp[i]<=0: alive.discard(i); out_round[i]=t
    win=next(iter(alive)) if alive else None
    first=min(out_round.values()) if out_round else t
    loss_at_out=[losses[i] for i in out_round]
    return dict(len=t, first=first, gap=t-first, lmin=min(loss_at_out) if loss_at_out else 99,
                l_out=loss_at_out, perf=st.mean(perf_share), out_rounds=list(out_round.values()))
def report(name,H,base,w,n=3000):
    R=[lobby(H,base,w) for _ in range(n)]
    L=[r['len'] for r in R]; F=[r['first'] for r in R]; G=[r['gap'] for r in R]
    allL=[x for r in R for x in r['l_out']]
    q=lambda v,p: sorted(v)[int(p*len(v))]
    outs=[x for r in R for x in r['out_rounds']]
    print(f"{name:34s} game {q(L,.1)}/{q(L,.5)}/{q(L,.9)}  first-out {q(F,.1)}/{q(F,.5)}/{q(F,.9)}  "
          f"out<=fight8 {sum(o<=8 for o in outs)/len(outs):.0%}  "
          f"out w/ <=2 losses {sum(l<=2 for l in allL)/len(allL):.1%} <=3 {sum(l<=3 for l in allL)/len(allL):.1%}  "
          f"losses-at-out med {st.median(allL)}  perf share {st.mean(r['perf'] for r in R):.0%}")
def ramp(*steps):  # steps: list of (from_round, value)
    def f(t):
        v=0
        for r,x in steps:
            if t>=r: v=x
        return v
    return f
print("game length / first-out shown as p10/median/p90 rounds")
report("A H30 base 1..6 +1/2rds, w1", 30, ramp((1,1),(3,2),(5,3),(7,4),(9,5),(11,6),(13,8),(15,10)), 1)
report("B H40 base 2,3,4,5,6,8,10 w1", 40, ramp((1,2),(4,3),(7,4),(9,5),(11,6),(13,8),(15,10)), 1)
report("C H40 base 3,4,5,6,8,10,12 w1", 40, ramp((1,3),(4,4),(7,5),(9,6),(11,8),(13,10),(15,12)), 1)
report("D H20 base 1,2,3,4,6 w0.5", 20, ramp((1,1),(4,1.5),(7,2),(9,2.5),(11,3),(13,4),(15,6)), 0.5)
report("E H50 base 3..14 w1", 50, ramp((1,3),(3,4),(5,5),(7,6),(9,7),(11,8),(13,10),(15,14)), 1)
