import csv, json, glob, os, statistics as st
from collections import defaultdict, Counter
D = '/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
C = '/home/alex/code/Bramble-ideation-balance/content/units/'
cards = {}
for f in glob.glob(C+'*.json'):
    try: d=json.load(open(f))
    except: continue
    cards[d['id']] = d
def rows(fn):
    with open(D+fn) as f:
        for x in csv.DictReader(f):
            if any(v is None for v in x.values()): continue
            yield x
players = {(p['seed'],p['seat']):p for p in rows('free_choice_plain.players.csv')}
board = defaultdict(list)
missing = Counter()
for c in rows('free_choice_plain.cards.csv'):
    k=(c['seed'],c['seat'])
    if k not in players: continue
    d=cards.get(c['card'])
    if not d: missing[c['card']]+=1; continue
    g=int(c['golden'])
    board[k].append((c['card'], int(c['tier']), (d['attack']+d['health'])*(2 if g else 1), g))
print('missing ids', missing.most_common(5))
def pct(xs,q):
    xs=sorted(xs); k=(len(xs)-1)*q; f=int(k); c=min(f+1,len(xs)-1); return xs[f]+(xs[c]-xs[f])*(k-f)
byplace=defaultdict(list); bytribe=defaultdict(list); ratio=defaultdict(list)
for k,p in players.items():
    b=board.get(k,[])
    printed=sum(x[2] for x in b); fin=int(p['final_attack'])+int(p['final_health'])
    units=int(p['final_units'])
    if units==0: continue
    byplace[int(p['place'])].append((printed, fin, len(b), units, sum(x[3] for x in b)))
    bytribe[p['final_tribe']].append((printed,fin,int(p['place'])))
print('place | n | printed SP med | final SP med | text-delivered med | final/printed med | cards listed med | goldens mean')
for pl in sorted(byplace):
    v=byplace[pl]
    print(pl, len(v), pct([a for a,*_ in v],.5), pct([b for _,b,*_ in v],.5), pct([b-a for a,b,*_ in v],.5), round(pct([b/a for a,b,*_ in v if a],.5),2), pct([c for _,_,c,_,_ in v],.5), round(st.mean([g for *_,g in v]),2))
print('tribe | n | printed | final | delivered | ratio (all places)')
for t,v in sorted(bytribe.items()):
    print(t, len(v), pct([a for a,b,c in v],.5), pct([b for a,b,c in v],.5), pct([b-a for a,b,c in v],.5), round(pct([b/a for a,b,c in v if a],.5),2))
# winners only by tribe
print('winners by tribe')
for t,v in sorted(bytribe.items()):
    w=[x for x in v if x[2]==1]
    if w: print(t, len(w), pct([a for a,b,c in w],.5), pct([b for a,b,c in w],.5), round(pct([b/a for a,b,c in w if a],.5),2))
