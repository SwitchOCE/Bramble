import csv, sys, statistics as st
from collections import defaultdict
d = sys.argv[1]
players = {}
for r in csv.DictReader(open(d+'/free_choice_plain.players.csv')):
    if any(r[k]=='' for k in ('seed','seat','place')): continue
    players[(r['seed'],r['seat'])] = r
seeds = {k[0] for k in players}
by = defaultdict(list)
rows=0
for r in csv.DictReader(open(d+'/free_choice_plain.rounds.csv')):
    if r['seed'] not in seeds: continue
    if any(r[k]=='' for k in ('round','units','attack','health')): continue
    p = players.get((r['seed'],r['seat']))
    if not p: continue
    rows+=1
    rnd=int(r['round']); u=int(r['units']); a=int(r['attack']); h=int(r['health'])
    top4 = int(p['place'])<=4
    by[(rnd,'all')].append((u,a,h)); by[(rnd,'top4' if top4 else 'bot4')].append((u,a,h))
    if int(p['place'])==1: by[(rnd,'win')].append((u,a,h))
print('lobbies',len(seeds),'players',len(players),'rounds rows',rows)
def pct(xs,q):
    xs=sorted(xs); i=min(len(xs)-1,int(q*len(xs))); return xs[i]
print('round grp n  units  medTotal  p90Total  maxTotal  medPerUnit  p90PerUnit')
for rnd in (2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18):
    for g in ('top4','win','all'):
        L=by.get((rnd,g),[])
        if not L: continue
        tot=[a+h for u,a,h in L]; pu=[(a+h)/u for u,a,h in L if u]
        print(rnd,g,len(L),round(st.mean(u for u,a,h in L),1),st.median(tot),pct(tot,.9),max(tot),round(st.median(pu),1),round(pct(pu,.9),1))
