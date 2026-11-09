import csv
from collections import defaultdict
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
a=defaultdict(list)
with open(D+'free_choice_plain.rounds.csv') as f:
    for r in csv.DictReader(f):
        if any(v is None for v in r.values()): continue
        u=int(r['units'])
        if u: a[int(r['round'])].append((int(r['attack'])/u, int(r['health'])/u, int(r['tier'])))
assumed={3:(2.5,'A(2)'),6:(3.3,'A(3)'),9:(4.0,'A(4)'),12:(4.9,'A(5)'),14:(6.1,'A(6)')}
for R in (3,6,9,12,14,16,18):
    xs=a[R]; ma=sum(x[0] for x in xs)/len(xs); mh=sum(x[1] for x in xs)/len(xs)
    print(R, 'mean attack/unit', round(ma,1), 'health/unit', round(mh,1), 'attack share', round(ma/(ma+mh),2), 'method A(t) at tier opening:', assumed.get(R))
