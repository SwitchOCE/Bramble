import csv, statistics as st
from collections import defaultdict
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f): players[(r['seed'],r['seat'])]=r
agg=defaultdict(lambda: defaultdict(list))
with open(D+'free_choice_plain.rounds.csv') as f:
    for r in csv.DictReader(f):
        k=(r['seed'],r['seat']); p=players.get(k)
        if not p: continue
        t=p['final_tribe']; rnd=int(r['round'])
        for g in (t,'ALL'):
            a=agg[(g,rnd)]
            a['tier'].append(int(r['tier'])); a['bank'].append(int(r['bank'])); a['spent'].append(int(r['spent']))
            a['refresh'].append(int(r['paid_refreshes'])); a['larder'].append(int(r['larder'])); a['left'].append(int(r['gold_left']))
            a['win'].append(1 if r['result']=='win' else 0)
print('tribe,round,n,tier,bank_start,spent,paid_refreshes,larder,gold_left,winrate')
for g in ['Hedgerow folk','Hunters','Oozes','ALL']:
    for rnd in [2,4,6,8,10,12,14,16]:
        a=agg[(g,rnd)]
        print(f"{g},{rnd},{len(a['tier'])},{st.mean(a['tier']):.2f},{st.mean(a['bank']):.1f},{st.mean(a['spent']):.1f},{st.mean(a['refresh']):.1f},{st.mean(a['larder']):.2f},{st.mean(a['left']):.1f},{st.mean(a['win']):.3f}")
# acorns per player by tribe
for g in ['Hedgerow folk','Hunters','Oozes']:
    ps=[p for p in players.values() if p['final_tribe']==g]
    print(g,'acorns/game',round(st.mean(int(p['acorns']) for p in ps),2),'acorn_gold',round(st.mean(int(p['acorn_gold']) for p in ps),2),'rounds',round(st.mean(int(p['rounds']) for p in ps),1),'t6turn',round(st.mean(int(p['tier6_turn']) for p in ps if int(p['tier6_turn'])>0),1), 'reach t6 %', round(100*sum(1 for p in ps if int(p['tier6_turn'])>0)/len(ps),1))
