import sys
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *
P,R,C,byp=load()
U={}
for f in glob.glob("/home/alex/code/Bramble-ideation-balance/content/units/*.json"):
    d=json.load(open(f)); U[d["id"]]=d
boards=collections.defaultdict(list)
for c in C: boards[(int(c["seed"]),int(c["seat"]))].append(c)
out=[];W=out.append
W("## Final boards: printed bodies (golden doubled) versus stats gained in play\n")
W("printed = sum of printed attack+health on the final board, doubled for goldens. gained = actual final stats - printed (all buffs: tribe bonus, spells, effects, Acorns).\n")
rows=[]
for pl in range(1,9):
    pr=[];ga=[];sh=[];gl=[];tier=[]
    for p in P:
        if p["place"]!=pl: continue
        cs=boards.get((p["seed"],p["seat"]),[])
        printed=sum((U[c["card"]]["attack"]+U[c["card"]]["health"])*(2 if c["golden"]=="1" else 1) for c in cs)
        actual=p["final_attack"]+p["final_health"]
        pr.append(printed); ga.append(actual-printed); sh.append((actual-printed)/actual if actual else 0)
        gl.append(sum(c["golden"]=="1" for c in cs)); tier.append(mean([U[c["card"]]["tier"] for c in cs]) if cs else 0)
    rows.append([pl,med(pr),med(ga),"%.0f%%"%(100*med(sh)),mean(gl),mean(tier)])
W(table(["place","printed med","gained med","gained share med","goldens mean","mean unit tier"],rows))
open("out_a6.md","w").write("\n".join(out)+"\n"); print("\n".join(out))
