import sys, gzip, csv, io
sys.path.insert(0, "/tmp/claude-1000/-home-alex-code-Bramble-ideation/5369878e-e379-478d-ac97-3201f49297d2/scratchpad/fundamentals")
from common import *
E="/home/alex/code/Bramble-ideation/docs/ideation/evidence/"
old=list(csv.DictReader(io.TextIOWrapper(gzip.open(E+"baseline-step2/free-choice.players.csv.gz"),"utf-8")))
P,R,C,byp=load()
out=[];W=out.append
def summ(ps,label):
    rows=[]
    for pl in range(1,9):
        s=[p for p in ps if int(p["place"])==pl]
        tot=[int(p["final_attack"])+int(p["final_health"]) for p in s]
        per=[(int(p["final_attack"])+int(p["final_health"]))/int(p["final_units"]) for p in s if int(p["final_units"])]
        rows.append([label,pl,len(s),mean([int(p["rounds"]) for p in s]),med(tot),med(per),mean([int(p["final_units"]) for p in s])])
    return rows
W("## Older bench comparison: final boards by place\n")
W(table(["bench","place","n","rounds","final stats med","per-unit med","units"],summ(old,"baseline-step2 (pre-pass-2 pool)")+summ([{k:str(v) for k,v in p.items()} for p in P],"pass 2 follow-up")))
seeds=collections.defaultdict(list)
for p in old: seeds[p["seed"]].append(int(p["rounds"]))
W("\nbaseline-step2: lobbies %d; first elimination median %.1f; game length median %.1f." % (len(seeds), med([min(v) for v in seeds.values()]), med([max(v) for v in seeds.values()])))
V="/home/alex/code/Bramble-ideation/docs/ideation/evidence/damage-v05"
G=[json.loads(l) for f in sorted(glob.glob(V+"/B.*.jsonl.gz")) for l in gzip.open(f,"rt")]
W("damage-v05 arm B: lobbies %d; first elimination median %.1f; game length median %.1f; ghost won %s." % (len(G), med([min(p["rounds"][-1]["round"] for p in g["players"] if not p["alive"]) for g in G]), med([g["rounds"] for g in G]), "8.2%"))
pr=json.load(open(E+"baseline-step2/provenance.json"))
W("baseline-step2 provenance: %s" % pr.get("config"))
open("out_a7.md","w").write("\n".join(out)+"\n"); print("\n".join(out))
