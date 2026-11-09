import csv, json, glob, statistics as st
from collections import defaultdict
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
C='/home/alex/code/Bramble-ideation-balance/content/units/'
names={}
for f in glob.glob(C+'*.json'):
    try: d=json.load(open(f)); names[d['id']]=(d['name'], d.get('tribes') or ['Neutral'], d['tier'])
    except: pass
def rows(fn):
    with open(D+fn) as f:
        for x in csv.DictReader(f):
            if any(v is None for v in x.values()): continue
            yield x
pl={(p['seed'],p['seat']):p for p in rows('free_choice_plain.players.csv')}
ftier={}; 
for r in rows('free_choice_plain.rounds.csv'):
    k=(r['seed'],r['seat']); ftier[k]=max(ftier.get(k,0), int(r['tier']))
has=defaultdict(set); gold=defaultdict(int)
for c in rows('free_choice_plain.cards.csv'):
    k=(c['seed'],c['seat'])
    if k in pl: has[c['card']].add(k); gold[c['card']]+=int(c['golden'])
out=[]
for card,ks in has.items():
    nm,tr,t=names.get(card,(card,['?'],0))
    if t<3: continue
    eligible=[k for k in pl if ftier.get(k,0)>=t]
    with_=[int(pl[k]['place']) for k in ks if k in pl]
    without=[int(pl[k]['place']) for k in eligible if k not in ks]
    if len(with_)<15: continue
    out.append((st.mean(with_)-st.mean(without), nm, tr[0], t, len(with_), st.mean(with_), st.mean(without), sum(1 for x in with_ if x==1)/len(with_), gold[card]/len(with_)))
out.sort()
print('delta_place name tribe tier n place_with place_without(eligible same tier) first_rate golden_rate')
for o in out: print(f'{o[0]:+.2f} | {o[1]} | {o[2]} | T{o[3]} | n={o[4]} | {o[5]:.2f} | {o[6]:.2f} | {o[7]:.2f} | {o[8]:.2f}')
