import csv, sys, statistics as st
from collections import defaultdict
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f):
        if any(v is None for v in r.values()): continue
        players[(r['seed'],r['seat'])]=r
print('players',len(players),'seeds',len({k[0] for k in players}))
rows=defaultdict(list)
with open(D+'free_choice_plain.rounds.csv') as f:
    for r in csv.DictReader(f):
        k=(r['seed'],r['seat'])
        if k not in players: continue
        if any(v in (None,'') for k2,v in r.items() if k2!='strategy'): continue
        rows[k].append(r)
def q(xs,p):
    xs=sorted(xs); 
    if not xs: return float('nan')
    i=min(len(xs)-1,int(p*len(xs))); return xs[i]
groups=['Hedgerow folk','Hunters','Oozes','Bog folk','Birds','Fairies','no_tribe','ALL']
print('tribe,round,n_alive,units,stats_total,stats_per_unit,p90_total,p90_per_unit,top4_total,first_total')
for g in groups:
    for rnd in [4,6,8,10,12,14,16,18]:
        tot=[];per=[];un=[];t4=[];t1=[]
        for k,rs in rows.items():
            p=players[k]
            if g!='ALL' and p['final_tribe']!=g: continue
            for r in rs:
                if int(r['round'])==rnd:
                    u=int(r['units']); s=int(r['attack'])+int(r['health'])
                    un.append(u); tot.append(s); per.append(s/u if u else 0)
                    if int(p['place'])<=4: t4.append(s)
                    if int(p['place'])==1: t1.append(s)
        if not tot: continue
        print(f"{g},{rnd},{len(tot)},{st.mean(un):.2f},{st.mean(tot):.1f},{st.mean(per):.2f},{q(tot,0.9)},{q(per,0.9):.1f},{st.mean(t4) if t4 else 0:.1f},{st.mean(t1) if t1 else 0:.1f}")
