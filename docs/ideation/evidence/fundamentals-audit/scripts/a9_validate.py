import sys
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *
P,R,C,byp=load()
M=json.load(open("model.json")); k=M["kscale"]; sm={int(a):b for a,b in M["surv_mean"].items()}
def d(r): return base(r)+k*sm.get(r,1.6)
out=[];W=out.append
W("## Model check: replay each player's real results through the Health model\n")
W("Predicted death = first round modelled Health <= 0 (places 5-8: no Last Stand; places 2-4: one save allowed once 4 or fewer are alive, which we approximate as rounds after the 5th-place exit).\n")
rows=[]
fifth={p["seed"]:p["rounds"] for p in P if p["place"]==5}
for pl in range(1,9):
    err=[]; survived=0
    for p in P:
        if p["place"]!=pl: continue
        h=40.0; used=False; pred=None
        for r in byp[(p["seed"],p["seat"])]:
            if r["result"]=="loss":
                h-=d(r["round"])
                if h<=0:
                    if pl<=4 and r["round"]>fifth[p["seed"]] and not used and h+d(r["round"])>=2:
                        used=True; h=1
                    else:
                        pred=r["round"]; break
        if pred is None:
            survived+=1
            if pl>1: err.append(None)
        else:
            err.append(pred-p["rounds"])
    e=[x for x in err if x is not None]
    rows.append([pl, len([p for p in P if p["place"]==pl]), "%.0f%%"%(100*mean([x==0 for x in e])) if e else "-", "%.0f%%"%(100*mean([abs(x)<=1 for x in e])) if e else "-", mean(e) if e else float('nan'), survived])
W(table(["place","players","predicted round exact","within 1","mean error (pred-actual)","model says still alive at end"],rows))
open("out_a9.md","w").write("\n".join(out)+"\n"); print("\n".join(out))
