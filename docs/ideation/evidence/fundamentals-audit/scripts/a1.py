import csv, sys, collections, statistics as st
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=list(csv.DictReader(open(D+'free_choice_plain.players.csv')))
def complete(r): return all(v is not None for v in r.values()) and r['place']!=''
players=[p for p in players if complete(p)]
seeds=set(p['seed'] for p in players)
print('players',len(players),'seeds',len(seeds))
key={(p['seed'],p['seat']):p for p in players}
# by final tribe
by=collections.defaultdict(list)
for p in players: by[p['final_tribe']].append(p)
print('tribe n place rounds units atk hp stats/unit tier6_turn')
for t,ps in sorted(by.items()):
    u=[int(p['final_units']) for p in ps]; a=[int(p['final_attack']) for p in ps]; h=[int(p['final_health']) for p in ps]
    spu=[(int(p['final_attack'])+int(p['final_health']))/max(1,int(p['final_units'])) for p in ps]
    t6=[int(p['tier6_turn']) for p in ps if p['tier6_turn'] not in ('','0','-1')]
    print(f"{t:14s} {len(ps):4d} {st.mean(int(p['place']) for p in ps):.2f} {st.mean(int(p['rounds']) for p in ps):.1f} {st.mean(u):.2f} {st.mean(a):.1f} {st.mean(h):.1f} {st.mean(spu):.1f} {st.mean(t6) if t6 else 0:.1f} n6={len(t6)}")
# winners
print('winners by tribe')
for t,ps in sorted(by.items()):
    w=[p for p in ps if p['place']=='1']
    if not w: continue
    spu=[(int(p['final_attack'])+int(p['final_health']))/max(1,int(p['final_units'])) for p in w]
    print(t,len(w),round(st.mean(spu),1), round(st.mean(int(p['final_attack']) for p in w),1), round(st.mean(int(p['final_health']) for p in w),1), round(st.mean(int(p['rounds']) for p in w),1))
