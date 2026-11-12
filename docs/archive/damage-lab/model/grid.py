import random, statistics as st, itertools
exec(open('dmg.py').read().split('def report')[0])
def run(H,base,w,n=800):
    R=[lobby(H,base,w) for _ in range(n)]
    med=lambda v: st.median(v)
    L=med([r['len'] for r in R]); F=med([r['first'] for r in R])
    allL=[x for r in R for x in r['l_out']]
    return L,F,sum(l<=3 for l in allL)/len(allL),st.mean(r['perf'] for r in R)
res=[]
for b0,g,R,late in itertools.product([1,2,3],[0,0.25,0.5],[9,10,11,12],[1,2,3]):
    base=lambda t,b0=b0,g=g,R=R,late=late: b0+g*(t-1)+(late*(t-R+1) if t>=R else 0)
    L,F,l3,p=run(40,base,1)
    score=abs(L-14)+abs(F-8.5)
    res.append((score,b0,g,R,late,L,F,l3,p))
res.sort()
print("b0 g ramp_from late | game first-out out<=3losses perf-share")
for s,b0,g,R,late,L,F,l3,p in res[:8]:
    print(f"{b0} {g} {R} {late} | {L} {F} {l3:.1%} {p:.0%}  e.g. base t1,5,9,12,15,18: "+
          ",".join(str(round(b0+g*(t-1)+(late*(t-R+1) if t>=R else 0),1)) for t in (1,5,9,12,15,18)))
