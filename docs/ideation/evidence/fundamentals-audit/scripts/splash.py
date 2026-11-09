import csv, statistics as st
from collections import defaultdict, Counter
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f): players[(r['seed'],r['seat'])]=r
boards=defaultdict(list)
with open(D+'free_choice_plain.cards.csv') as f:
    for r in csv.DictReader(f): boards[(r['seed'],r['seat'])].append(r)
for card in ['squire_lollop','standing_committee','old_mother_mast','goodman_hayward','alderman_dozey','old_isegrim','grizel','little_nip','old_lutra','whirligig_beetle','granny_stir_up','elder_ooze','wee_wobbly','mrs_mallow','honorary_treasurer','madame_ermeline','lodger']:
    ks=[k for k in boards if any(c['card']==card for c in boards[k])]
    byt=Counter(players[k]['final_tribe'] for k in ks)
    byplural=Counter(players[k]['plurality_tribe'] for k in ks)
    firsts=[k for k in ks if players[k]['place']=='1']
    print(card, 'boards',len(ks),'avgplace',round(st.mean(int(players[k]['place']) for k in ks),2),'firsts',len(firsts),'by final_tribe',dict(byt.most_common(7)))
    print('   firsts by final_tribe',dict(Counter(players[k]['final_tribe'] for k in firsts).most_common(7)))
# first place boards: tribe distribution and lollop+isegrim combos
firsts=[k for k in players if players[k]['place']=='1']
print('first place final_tribe', Counter(players[k]['final_tribe'] for k in firsts))
def has(k,c): return any(x['card']==c for x in boards[k])
combo=Counter((has(k,'squire_lollop'),has(k,'old_isegrim'),has(k,'standing_committee')) for k in firsts)
print('firsts (lollop,isegrim,committee):',combo)
# top cards on first place boards overall
cc=Counter()
for k in firsts:
    for c in set(x['card'] for x in boards[k]): cc[c]+=1
print('top cards on 400 first boards:', cc.most_common(25))
