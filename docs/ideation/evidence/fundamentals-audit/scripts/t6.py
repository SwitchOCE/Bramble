import csv, json, glob, statistics as st
from collections import defaultdict, Counter
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
U={}
for f in glob.glob('/home/alex/code/Bramble-ideation-balance/content/units/*.json'):
    d=json.load(open(f))
    if d.get('set')=='slice': U[d['id']]=d
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f): players[(r['seed'],r['seat'])]=r
boards=defaultdict(list)
with open(D+'free_choice_plain.cards.csv') as f:
    for r in csv.DictReader(f): boards[(r['seed'],r['seat'])].append(r)
# lobby tribe availability
def offered(k,t): return t in players[k]['lobby_tribes'].split('+')
for tier in [6,5]:
    print('--- tier',tier)
    ids=[i for i,d in U.items() if d['tier']==tier and d.get('pool')]
    res=[]
    for i in ids:
        ks=[k for k in boards if any(c['card']==i for c in boards[k])]
        if not ks: continue
        tr='/'.join(U[i].get('tribes',[])) or 'NONE'
        # lobbies where card was available
        lob=[k for k in players if tr=='NONE' or offered(k,tr)]
        res.append((st.mean(int(players[k]['place']) for k in ks), i, tr, len(ks), len(ks)/len(lob)*100, sum(1 for k in ks if players[k]['place']=='1')))
    for r in sorted(res): print(f"{r[1]:22s} {r[2]:14s} boards={r[3]:4d} on%ofeligible={r[4]:5.1f} avgplace={r[0]:.2f} firsts={r[5]}")
