import json,sys
m=sys.argv[1]
lib=json.load(open(f'{m}/library.json'))
cards = lib['cards'] if isinstance(lib,dict) and 'cards' in lib else lib
tiers={}
if isinstance(cards,dict):
    for k,u in cards.items(): tiers[u.get('id',k)]=u['tier']
else:
    for u in cards: tiers[u['id']]=u['tier']
d=json.load(open(f'{m}/deep/cards.json'))
print('==',m)
rows=[r for r in d['fight_lift_vs_other_boards'] if r['band']=='all' and tiers.get(r['card'])==6]
for sc in ['red','blue','both']:
    rr=sorted([r for r in rows if r['scope']==sc], key=lambda r:-r['mean'])
    print(' lift',sc); [print('   ',f"{r['card']:28s} {r['mean']:+.3f} [{r['ci95'][0]:+.2f},{r['ci95'][1]:+.2f}] n={r['count']}") for r in rr]
pr=[r for r in d['pick_rate'] if r['band']=='all' and r['final_tribe']=='all' and tiers.get(r['card'])==6]
for sc in ['red','blue']:
    rr=sorted([r for r in pr if r['scope']==sc], key=lambda r:-r['rate'])
    print(' pick',sc); [print('   ',f"{r['card']:28s} {r['rate']:.0%} ({r['hits']}/{r['count']})") for r in rr]
