import sys, gzip
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *
V = "/home/alex/code/Bramble-ideation/docs/ideation/evidence/damage-v05"
G = [json.loads(l) for f in sorted(glob.glob(V + "/B.*.jsonl.gz")) for l in gzip.open(f, "rt")]
out=[]; W=out.append
# arm B: per place, base taken, survivors taken, total, overkill, Last Stand
rows=[]
surv_by_round=collections.defaultdict(list)
for g in G:
    for f in g["fights"]:
        if f["winner"]<0: continue
        for ch in f["charges"]:
            surv_by_round[f["round"]].append(ch["performance"])
sm={r:mean(v) for r,v in surv_by_round.items()}
per=collections.defaultdict(lambda: collections.defaultdict(list))
for g in G:
    place={p["seat"]:p["place"] for p in g["players"]}
    acc=collections.defaultdict(lambda: collections.Counter())
    for f in g["fights"]:
        for ch in f["charges"]:
            s=ch["seat"]
            if f["winner"]>=0:
                acc[s]["base"]+=ch["base"]; acc[s]["surv"]+=ch["performance"]; acc[s]["losses"]+=1
                if ch["health_after"]<=0: acc[s]["over"]+= -ch["health_after"]
        for s in f["last_stand_sides"]:
            seat=f["players"][s]; acc[seat]["ls"]+=1
    for s,a in acc.items():
        pl=place[s]
        for k in ("base","surv","losses","over","ls"): per[pl][k].append(a[k])
for pl in range(1,9):
    d=per[pl]
    rows.append([pl, mean(d["losses"]), mean(d["base"]), mean(d["surv"]), mean(d["base"])+mean(d["surv"]), mean(d["surv"])/mean(d["losses"]), mean(d["over"]), "%.0f%%"%(100*mean([x>0 for x in d["ls"]]))])
W("## A. Arm B by final place: losses and what they cost\n")
W(table(["place","losses","base taken","survivor dmg taken","total","survivors per loss","overkill","used Last Stand"],rows))
overk={pl:mean(per[pl]["over"]) for pl in range(1,9)}

P,R,C,byp=load()
W("\n\n## B. Pass 2 by final place: base taken (exact) and survivor damage implied\n")
W("Places 5-8 die with 5+ alive, so Last Stand cannot fire: total taken = 40 + overkill. Overkill taken from arm B by place.\n")
rows=[]; ratio=[]
for pl in range(1,9):
    ks=[(p["seed"],p["seat"]) for p in P if p["place"]==pl]
    nl=[sum(1 for r in byp[k] if r["result"]=="loss") for k in ks]
    b=[sum(base(r["round"]) for r in byp[k] if r["result"]=="loss") for k in ks]
    exp_surv_B=[sum(sm.get(r["round"],1.6) for r in byp[k] if r["result"]=="loss") for k in ks]
    # Last Stand certain: base before the final loss already >= 40 (for places 2-4), or winners with base >=40
    certain=0
    for k in ks:
        L=[r for r in byp[k] if r["result"]=="loss"]
        pre=sum(base(r["round"]) for r in (L[:-1] if pl>1 else L))
        if pre>=40: certain+=1
    need = (40+overk[pl]-mean(b)) if pl>=5 else float("nan")
    if pl>=5: ratio.append((need, mean(exp_surv_B)))
    rows.append([pl, mean(nl), mean(b), mean(exp_surv_B), need, (need/mean(nl)) if pl>=5 else float("nan"), "%.0f%%"%(100*certain/len(ks))])
W(table(["place","losses","base taken","survivor dmg if arm B rates","survivor dmg implied (40+overkill-base)","implied survivors per loss","Last Stand certain (base alone >=40 before last loss)"],rows))
k=sum(a for a,b in ratio)/sum(b for a,b in ratio)
W("\nImplied scale on arm B survivor rates, places 5-8: %.2f"%k)
open("out_a2b.md","w").write("\n".join(out)+"\n")
json.dump({"kscale":k,"surv_mean":sm},open("model.json","w"))
print("\n".join(out))
