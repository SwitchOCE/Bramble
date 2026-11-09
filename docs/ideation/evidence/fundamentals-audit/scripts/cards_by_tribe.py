import csv, json, glob, statistics as st
from collections import defaultdict, Counter
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
U={}
for f in glob.glob('/home/alex/code/Bramble-ideation-balance/content/units/*.json'):
    d=json.load(open(f))
    if d.get('set')=='slice': U[d['id']]=d
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f):
        players[(r['seed'],r['seat'])]=r
boards=defaultdict(list)
with open(D+'free_choice_plain.cards.csv') as f:
    for r in csv.DictReader(f):
        k=(r['seed'],r['seat'])
        if k in players: boards[k].append(r)
print('boards',len(boards))
for tribe in ['Hedgerow folk','Hunters','Oozes','NONE']:
    ids=[i for i,d in U.items() if ('/'.join(d.get('tribes',[])) or 'NONE')==tribe]
    ids.sort(key=lambda i:(U[i]['tier'],U[i]['name']))
    tname = tribe if tribe!='NONE' else None
    tb=[k for k in boards if players[k]['final_tribe']==tribe] if tname else []
    print(f'===== {tribe}: final-tribe boards {len(tb)}')
    print('card,tier,pool,boards_with_card_all(%),avg_place_with,avg_place_without,copies_on_tribe_boards_per_board,share_tribe_boards_with(%),golden_share,first_place_boards_with(%)')
    allk=list(boards)
    for i in ids:
        withk=[k for k in allk if any(c['card']==i for c in boards[k])]
        wo=[k for k in allk if k not in set(withk)]
        pw=st.mean(int(players[k]['place']) for k in withk) if withk else float('nan')
        pwo=st.mean(int(players[k]['place']) for k in wo) if wo else float('nan')
        cop=sum(sum(1 for c in boards[k] if c['card']==i) for k in tb)/len(tb) if tb else 0
        tw=sum(1 for k in tb if any(c['card']==i for c in boards[k]))/len(tb)*100 if tb else 0
        gl=[c['golden'] for k in allk for c in boards[k] if c['card']==i]
        g=sum(1 for x in gl if x=='1')/len(gl) if gl else 0
        firsts=[k for k in allk if players[k]['place']=='1']
        fw=sum(1 for k in firsts if any(c['card']==i for c in boards[k]))/len(firsts)*100
        print(f"{i},{U[i]['tier']},{U[i].get('pool')},{len(withk)/len(allk)*100:.1f},{pw:.2f},{pwo:.2f},{cop:.2f},{tw:.1f},{g:.2f},{fw:.1f}")
