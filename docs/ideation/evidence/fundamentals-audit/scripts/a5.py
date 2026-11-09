import csv, collections, statistics as st
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=[p for p in csv.DictReader(open(D+'free_choice_plain.players.csv')) if p['place']]
key={(p['seed'],p['seat']):p for p in players}
boards=collections.defaultdict(list)
for c in csv.DictReader(open(D+'free_choice_plain.cards.csv')):
    if (c['seed'],c['seat']) in key: boards[(c['seed'],c['seat'])].append(c)
by=collections.defaultdict(list)
for k,p in key.items(): by[p['final_tribe']].append(k)
for t,ks in sorted(by.items()):
    g=[sum(c['golden']=='1' for c in boards[k]) for k in ks]
    n=[len(boards[k]) for k in ks]
    tier=[st.mean(int(c['tier']) for c in boards[k]) for k in ks if boards[k]]
    gw=[sum(c['golden']=='1' for c in boards[k]) for k in ks if key[k]['place']=='1']
    print(f"{t:14s} goldens/board={st.mean(g):.2f} units={st.mean(n):.2f} mean_card_tier={st.mean(tier):.2f} winners_goldens={st.mean(gw) if gw else 0:.2f}")
# final stats per unit by place
print('place: mean final SP/unit, mean rounds')
for pl in range(1,9):
    ps=[p for p in players if p['place']==str(pl)]
    print(pl, round(st.mean((int(p['final_attack'])+int(p['final_health']))/max(1,int(p['final_units'])) for p in ps),1), round(st.mean(int(p['rounds']) for p in ps),1))
