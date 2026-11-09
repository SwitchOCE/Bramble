import csv, collections, statistics as st
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=list(csv.DictReader(open(D+'free_choice_plain.players.csv')))
tribe={(p['seed'],p['seat']):p['final_tribe'] for p in players}
place={(p['seed'],p['seat']):int(p['place']) for p in players}
rounds=list(csv.DictReader(open(D+'free_choice_plain.rounds.csv')))
# curve shape: per round, all seats alive, total stats; ratio p99/p50, max/p50; lobby max / lobby median
for rd in (8,12,16):
    rows=[r for r in rounds if int(r['round'])==rd and int(r['units'])>0]
    tot=sorted(int(r['attack'])+int(r['health']) for r in rows)
    p=lambda q: tot[min(len(tot)-1,int(q*len(tot)))]
    # within-lobby: max/median among alive
    bylob=collections.defaultdict(list)
    for r in rows: bylob[r['seed']].append(int(r['attack'])+int(r['health']))
    ratios=[max(v)/st.median(v) for v in bylob.values() if len(v)>=3]
    ratios.sort()
    print(f"R{rd}: n={len(tot)} p10 {p(.1)} p50 {p(.5)} p90 {p(.9)} p99 {p(.99)} max {tot[-1]}  p99/p50={p(.99)/p(.5):.2f} max/p50={tot[-1]/p(.5):.2f} | within-lobby max/median: p50 {ratios[len(ratios)//2]:.2f} p90 {ratios[int(.9*len(ratios))]:.2f} max {ratios[-1]:.2f}")
# bank distribution (economy)
for rd in (6,8,10,12):
    rows=[r for r in rounds if int(r['round'])==rd]
    b=sorted(int(r['bank']) for r in rows)
    print(f"R{rd} gold at start: p10 {b[int(.1*len(b))]} p50 {b[len(b)//2]} p90 {b[int(.9*len(b))]} p99 {b[int(.99*len(b))]} max {b[-1]}")
# tier at R8 distribution and place by tier at R8
rows=[r for r in rounds if int(r['round'])==8]
c=collections.Counter(int(r['tier']) for r in rows); print('tier at R8',sorted(c.items()))
pl=collections.defaultdict(list)
for r in rows: pl[int(r['tier'])].append(place[(r['seed'],r['seat'])])
print('mean place by R8 tier',{k:round(st.mean(v),2) for k,v in sorted(pl.items())})
# streaks: win rate by board-stat rank at R8 within lobby -> final place
