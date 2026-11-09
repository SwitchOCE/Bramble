import csv, collections, statistics as st, sys
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=list(csv.DictReader(open(D+'free_choice_plain.players.csv')))
def complete(r): return all(v not in (None,) for v in r.values())
players=[p for p in players if complete(p)]
seeds=set(p['seed'] for p in players)
print('players',len(players),'seeds',len(seeds))
tribe={(p['seed'],p['seat']):p['final_tribe'] for p in players}
place={(p['seed'],p['seat']):int(p['place']) for p in players}
# final board stats by tribe
by=collections.defaultdict(list)
for p in players:
    u=int(p['final_units']); a=int(p['final_attack']); h=int(p['final_health'])
    by[p['final_tribe']].append((int(p['place']),u,a,h,int(p['rounds'])))
print('\nFinal board (at elimination or end): tribe n meanplace units  totalstats  stats/unit  median  p90 ; winners(place1) stats/unit')
for t,v in sorted(by.items()):
    spu=[(a+h)/u for pl,u,a,h,r in v if u>0]
    tot=[a+h for pl,u,a,h,r in v]
    w=[(a+h)/u for pl,u,a,h,r in v if pl==1 and u>0]
    print(f"{t:14s} {len(v):4d} {st.mean(x[0] for x in v):.2f} {st.mean(x[1] for x in v):.2f} {st.mean(tot):7.1f} {st.mean(spu):6.1f} {st.median(spu):6.1f} {sorted(spu)[int(.9*len(spu))]:6.1f} | win n={len(w)} {st.mean(w) if w else 0:.1f}")
rounds=list(csv.DictReader(open(D+'free_choice_plain.rounds.csv')))
rounds=[r for r in rounds if r['seed'] in seeds and all(v not in (None,'') for k,v in r.items() if k not in ('strategy',))]
print('round rows',len(rounds))
agg=collections.defaultdict(list)
for r in rounds:
    k=(r['seed'],r['seat'])
    if k not in tribe: continue
    u=int(r['units']);
    if u==0: continue
    agg[(tribe[k],int(r['round']))].append(((int(r['attack'])+int(r['health']))/u, int(r['attack'])+int(r['health']), u, int(r['tier'])))
print('\nPer-round board: tribe round n  mean stats/unit  p50 p90 p99  mean total  mean tier')
for t in ['Birds','Bog folk','Fairies','Hedgerow folk','Hunters','Oozes','no_tribe']:
    for rd in (4,6,8,10,12,14,16):
        v=agg.get((t,rd),[])
        if len(v)<5: 
            print(f"{t:14s} R{rd:2d} n={len(v)}"); continue
        s=sorted(x[0] for x in v); tt=sorted(x[1] for x in v)
        print(f"{t:14s} R{rd:2d} n={len(v):4d} {st.mean(s):6.1f} {s[len(s)//2]:6.1f} {s[int(.9*len(s))]:6.1f} {s[min(len(s)-1,int(.99*len(s)))]:6.1f} | tot {st.mean(tt):6.1f} p90 {tt[int(.9*len(tt))]:5d} max {tt[-1]:5d} | tier {st.mean(x[3] for x in v):.2f}")
