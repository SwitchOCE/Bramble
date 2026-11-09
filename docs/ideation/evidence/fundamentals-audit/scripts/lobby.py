import csv, json, glob, os, statistics as st, sys
from collections import defaultdict
D = '/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
C = '/home/alex/code/Bramble-ideation-balance/content/units/'
def rows(fn):
    with open(D+fn) as f:
        r = csv.DictReader(f)
        for x in r:
            if any(v is None for v in x.values()):
                continue
            yield x
players = [p for p in rows('free_choice_plain.players.csv')]
seeds = set(p['seed'] for p in players)
# complete lobbies: 8 seats
cnt = defaultdict(int)
for p in players: cnt[p['seed']] += 1
full = {s for s,c in cnt.items() if c == 8}
print('players', len(players), 'seeds', len(seeds), 'full lobbies', len(full))
rounds = [r for r in rows('free_choice_plain.rounds.csv') if r['seed'] in full]
print('round rows', len(rounds))
# by round: board SP distribution
by = defaultdict(list); byu = defaultdict(list); tier = defaultdict(list); winners = defaultdict(list); bank=defaultdict(list)
for r in rounds:
    R = int(r['round']); sp = int(r['attack']) + int(r['health']); u = int(r['units'])
    by[R].append(sp); tier[R].append(int(r['tier'])); bank[R].append(int(r['bank']))
    if u: byu[R].append(sp/u)
    if r['result']=='win': winners[R].append(sp)
def pct(xs,q):
    xs=sorted(xs); 
    if not xs: return float('nan')
    k=(len(xs)-1)*q; f=int(k); c=min(f+1,len(xs)-1); return xs[f]+(xs[c]-xs[f])*(k-f)
print('round n medianSP p10 p90 max | SP/unit median p90 | win median | tier median mean | bank med')
for R in sorted(by):
    if R>22: break
    xs=by[R]
    print(R, len(xs), pct(xs,.5), pct(xs,.1), pct(xs,.9), max(xs), '|', round(pct(byu[R],.5),1), round(pct(byu[R],.9),1), '|', pct(winners[R],.5), '|', pct(tier[R],.5), round(st.mean(tier[R]),2), '|', pct(bank[R],.5))
# game length
rs=[int(p['rounds']) for p in players if p['seed'] in full]
pl=defaultdict(list)
for p in players:
    if p['seed'] in full: pl[int(p['place'])].append(int(p['rounds']))
print('rounds by place', {k: pct(v,.5) for k,v in sorted(pl.items())})
t6=[int(p['tier6_turn']) for p in players if p['seed'] in full and p['tier6_turn'] not in ('','0','-1')]
print('tier6 turn median', pct(t6,.5), 'p10', pct(t6,.1), 'n', len(t6), 'of', len([p for p in players if p['seed'] in full]))
# final boards
fin=defaultdict(list)
for p in players:
    if p['seed'] in full:
        u=int(p['final_units']); sp=int(p['final_attack'])+int(p['final_health'])
        fin[int(p['place'])].append((u,sp))
for k in sorted(fin):
    v=fin[k]; print('place',k,'final units med',pct([a for a,b in v],.5),'final SP med',pct([b for a,b in v],.5),'p90',pct([b for a,b in v],.9),'max',max(b for a,b in v))
