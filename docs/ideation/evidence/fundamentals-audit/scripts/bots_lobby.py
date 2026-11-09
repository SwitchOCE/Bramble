import csv, sys, statistics as st, collections, json, glob, os
D = sys.argv[1]
OUT = sys.argv[2]
UNITS = sys.argv[3]
def rows(name):
    with open(os.path.join(D, name)) as f:
        r = csv.DictReader(f)
        for row in r:
            if any(v is None or v == '' for k, v in row.items() if k in REQ.get(name, [])):
                continue
            yield row
REQ = {
 'free_choice_plain.players.csv': ['seed','seat','place','rounds'],
 'free_choice_plain.rounds.csv': ['seed','seat','round','tier','units','attack','health','bank','spent','paid_refreshes','larder','result','gold_left'],
 'free_choice_plain.cards.csv': ['seed','seat','place','card','tier','golden'],
}
players = list(rows('free_choice_plain.players.csv'))
seeds = set(p['seed'] for p in players)
# keep only seeds with 8 seats
cnt = collections.Counter(p['seed'] for p in players)
seeds = set(s for s in seeds if cnt[s] == 8)
players = [p for p in players if p['seed'] in seeds]
out = []
def P(*a):
    out.append(' '.join(str(x) for x in a))
P('lobbies', len(seeds), 'players', len(players))
rnd = [r for r in rows('free_choice_plain.rounds.csv') if r['seed'] in seeds]
P('round rows', len(rnd))
by_round = collections.defaultdict(list)
for r in rnd:
    by_round[int(r['round'])].append(r)
P('\n## Economy and shop behaviour per round (all living seats)')
P('round n mean_bank mean_spent mean_gold_left P(left>=3) P(left>=5) mean_paid_refresh P(refresh>=1) mean_larder mean_tier tier_sd')
for k in sorted(by_round):
    v = by_round[k]
    if len(v) < 50: continue
    gl = [int(x['gold_left']) for x in v]
    pr = [int(x['paid_refreshes']) for x in v]
    tiers = [int(x['tier']) for x in v]
    P(k, len(v), round(st.mean(int(x['bank']) for x in v),2), round(st.mean(int(x['spent']) for x in v),2),
      round(st.mean(gl),2), round(sum(g>=3 for g in gl)/len(gl),3), round(sum(g>=5 for g in gl)/len(gl),3),
      round(st.mean(pr),2), round(sum(p>=1 for p in pr)/len(pr),3), round(st.mean(int(x['larder']) for x in v),2),
      round(st.mean(tiers),2), round(st.pstdev(tiers),2))
# tier timing: first round reaching each tier per seat
first = collections.defaultdict(dict)
for r in rnd:
    key=(r['seed'],r['seat']); t=int(r['tier']); k=int(r['round'])
    for tt in range(2,t+1):
        if tt not in first[key] or k < first[key][tt]:
            first[key][tt]=k
P('\n## Round first reaching tier T (seats that reached it)')
P('tier n p10 p50 p90 sd')
for tt in range(2,7):
    vals=sorted(v[tt] for v in first.values() if tt in v)
    if not vals: continue
    q=lambda p: vals[min(len(vals)-1,int(p*len(vals)))]
    P(tt, len(vals), q(.1), q(.5), q(.9), round(st.pstdev(vals),2))
# ghost fights: alive per round
P('\n## Ghost fights (odd number alive -> one player fights the last-eliminated board)')
ghost=0; fights=0; lob_ghost=[]
rounds_of = collections.defaultdict(dict)
for p in players:
    rounds_of[p['seed']][p['seat']]=int(p['rounds'])
for s, d in rounds_of.items():
    g=0
    maxr=max(d.values())
    for k in range(1,maxr+1):
        alive=sum(1 for v in d.values() if v>=k)
        if alive<=1: break
        fights+=alive
        if alive%2==1:
            g+=1; ghost+=1
    lob_ghost.append(g)
P('player-fights', fights, 'ghost player-fights', ghost, 'share', round(ghost/fights,4), 'mean ghost rounds per lobby', round(st.mean(lob_ghost),2))
# early record vs final place (losses afforded)
res = collections.defaultdict(dict)
for r in rnd:
    res[(r['seed'],r['seat'])][int(r['round'])]=r['result']
place = {(p['seed'],p['seat']):int(p['place']) for p in players}
P('\n## Losses in rounds 1-6 vs final place (seats alive through R6)')
P('losses n mean_place P(top4) P(first)')
grp=collections.defaultdict(list)
for key,d in res.items():
    if all(k in d for k in range(1,7)):
        l=sum(1 for k in range(1,7) if d[k]=='loss')
        grp[l].append(place[key])
for l in sorted(grp):
    v=grp[l]
    P(l, len(v), round(st.mean(v),2), round(sum(x<=4 for x in v)/len(v),3), round(sum(x==1 for x in v)/len(v),3))
# board stat distribution per round: shape of curve
P('\n## Board stat total (Attack+Health on board) by round: shape across living seats')
P('round n p10 p50 p90 p99 max max/p50 p90/p50 mean_per_unit_p50 mean_per_unit_max')
for k in sorted(by_round):
    v=by_round[k]
    if len(v)<100: continue
    tot=sorted(int(x['attack'])+int(x['health']) for x in v)
    per=sorted((int(x['attack'])+int(x['health']))/max(1,int(x['units'])) for x in v)
    q=lambda a,p: a[min(len(a)-1,int(p*len(a)))]
    P(k,len(v),q(tot,.1),q(tot,.5),q(tot,.9),q(tot,.99),tot[-1],round(tot[-1]/max(1,q(tot,.5)),2),round(q(tot,.9)/max(1,q(tot,.5)),2),round(q(per,.5),1),round(per[-1],1))
# engine cards on final boards
units={}
for f in glob.glob(os.path.join(UNITS,'*.json')):
    d=json.load(open(f))
    for u in (d if isinstance(d,list) else [d]):
        if u.get('set')=='slice': units[u['id']]=u
SCALING_KEYS=['End of Turn','Start of Turn','permanently','Every 3','After 3 turns','Each turn on','Take: gain','gain +2/+2','gain +1/+1','Pass']
def is_scaling(u):
    t=u.get('text','')
    return any(k in t for k in SCALING_KEYS)
cards=[c for c in rows('free_choice_plain.cards.csv') if c['seed'] in seeds]
seat_cards=collections.defaultdict(list)
for c in cards: seat_cards[(c['seed'],c['seat'])].append(c['card'])
P('\n## Final boards: count of scaling/engine cards vs final place')
P('scalers_on_final_board n mean_place P(first)')
g2=collections.defaultdict(list)
for key,cl in seat_cards.items():
    n=sum(1 for c in cl if c in units and is_scaling(units[c]))
    g2[min(n,4)].append(place[key])
for n in sorted(g2):
    v=g2[n]; P(n,len(v),round(st.mean(v),2),round(sum(x==1 for x in v)/len(v),3))
P('\n## Per scaling card: share of final boards, mean place of holders')
tot_seats=len(seat_cards)
per=collections.defaultdict(list)
for key,cl in seat_cards.items():
    for c in set(cl): per[c].append(place[key])
lines=[]
for c,u in units.items():
    if not is_scaling(u): continue
    v=per.get(c,[])
    lines.append((u['tier'],c,len(v),round(len(v)/tot_seats,3),round(st.mean(v),2) if v else None, u['text'][:70]))
for l in sorted(lines): P(*l)
open(OUT,'w').write('\n'.join(out)+'\n')
print('\n'.join(out))
