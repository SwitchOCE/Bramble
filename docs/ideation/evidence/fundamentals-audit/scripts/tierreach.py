import csv
from collections import defaultdict
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
first=defaultdict(dict); place={}
with open(D+'free_choice_plain.players.csv') as f:
    for p in csv.DictReader(f): place[(p['seed'],p['seat'])]=int(p['place'])
with open(D+'free_choice_plain.rounds.csv') as f:
    for r in csv.DictReader(f):
        if any(v is None for v in r.values()): continue
        k=(r['seed'],r['seat']); t=int(r['tier']); R=int(r['round'])
        for tt in range(1,t+1):
            if tt not in first[k]: first[k][tt]=R
def pct(xs,q):
    xs=sorted(xs); k=(len(xs)-1)*q; f=int(k); c=min(f+1,len(xs)-1); return xs[f]+(xs[c]-xs[f])*(k-f)
for grp,flt in (('all',lambda k:True),('winners',lambda k:place.get(k)==1),('top4',lambda k:place.get(k,9)<=4)):
    ks=[k for k in first if flt(k)]
    out=[]
    for t in range(2,7):
        xs=[first[k][t] for k in ks if t in first[k]]
        out.append(f'T{t}: med {pct(xs,.5)} p25 {pct(xs,.25)} reached {len(xs)/len(ks):.0%}')
    print(grp, len(ks), ' | '.join(out))
# hold: rounds alive after reaching T4 and T5 for all
