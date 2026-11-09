import csv
from collections import defaultdict
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
seq=defaultdict(dict)
with open(D+'free_choice_plain.rounds.csv') as f:
    for r in csv.DictReader(f):
        if any(v is None for v in r.values()): continue
        seq[(r['seed'],r['seat'])][int(r['round'])]=r
def pct(xs,q):
    xs=sorted(xs); k=(len(xs)-1)*q; f=int(k); c=min(f+1,len(xs)-1); return xs[f]+(xs[c]-xs[f])*(k-f)
g=defaultdict(list); sp=defaultdict(list); ref=defaultdict(list); u=defaultdict(list)
for k,rs in seq.items():
    for R,r in rs.items():
        if R-1 in rs:
            p=rs[R-1]
            d=(int(r['attack'])+int(r['health']))-(int(p['attack'])+int(p['health']))
            sp[R].append(d); g[R].append(int(r['spent'])); ref[R].append(int(r['paid_refreshes'])); u[R].append(int(r['units']))
print('round | median board SP gain | mean SP gain | mean gold spent | mean SP per gold | mean paid refreshes | mean units')
for R in range(2,21):
    if not sp[R]: continue
    ms=sum(sp[R])/len(sp[R]); mg=sum(g[R])/len(g[R])
    print(R, pct(sp[R],.5), round(ms,1), round(mg,1), round(ms/mg,2) if mg else None, round(sum(ref[R])/len(ref[R]),1), round(sum(u[R])/len(u[R]),1))
