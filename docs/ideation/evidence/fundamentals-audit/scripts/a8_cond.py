import sys
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *
P,R,C,byp=load()
out=[];W=out.append
lob=collections.defaultdict(list)
for r in R: lob[(r["seed"],r["round"])].append(r)
rel={}
for (s,x),rs in lob.items():
    m=statistics.median([y["stats"] for y in rs])
    for y in rs: rel[(s,y["seat"],x)]=y["stats"]/m if m else 0
W("## Early wins (R1-6) against final place, split by board size at R6 (stats / lobby median): mean place (n)\n")
grid=collections.defaultdict(list)
for p in P:
    k=(p["seed"],p["seat"])
    e=sum(1 for r in byp[k] if r["round"]<=6 and r["result"]=="win")
    eb="0-2" if e<=2 else ("3-4" if e<=4 else "5-6")
    x=rel[(p["seed"],p["seat"],6)]
    xb="<0.95" if x<0.95 else ("0.95-1.05" if x<1.05 else ">=1.05")
    grid[(eb,xb)].append(p["place"])
cols=["<0.95","0.95-1.05",">=1.05"]
W(table(["R1-6 wins \\ R6 size"]+cols,[[eb]+["%.2f (%d)"%(mean(grid[(eb,c)]),len(grid[(eb,c)])) for c in cols] for eb in ("0-2","3-4","5-6")]))
W("\n\n## Does a result predict the next one? P(win in round r | result in r-1), decided fights, rounds 3+\n")
c=collections.Counter()
for k,rs in byp.items():
    for a,b in zip(rs,rs[1:]):
        if b["round"]<3 or a["result"]=="tie" or b["result"]=="tie": continue
        c[(a["result"],b["result"])]+=1
pw=c[("win","win")]/(c[("win","win")]+c[("win","loss")]); pl=c[("loss","win")]/(c[("loss","win")]+c[("loss","loss")])
W("After a win: %.1f%% win. After a loss: %.1f%% win." % (100*pw,100*pl))
# Early Spoils gold
W("\n\n## Early Spoils: wins in rounds 1-4 (1 gold each next turn) against place\n")
rows=[]
for e in range(0,5):
    ps=[p for p in P if sum(1 for r in byp[(p["seed"],p["seat"])] if r["round"]<=4 and r["result"]=="win")==e]
    rows.append([e,len(ps),mean([p["place"] for p in ps]),"%.0f%%"%(100*mean([p["place"]<=4 for p in ps]))])
W(table(["wins R1-4","players","mean place","top 4"],rows))
# Round 1 empty boards
r1=[r for r in R if r["round"]==1]
W("\nRound 1: %.0f%% of players field no unit (spent: %s)." % (100*mean([r["units"]==0 for r in r1]), collections.Counter(r["spent"] for r in r1 if r["units"]==0).most_common(3)))
open("out_a8.md","w").write("\n".join(out)+"\n"); print("\n".join(out))
