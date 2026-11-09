import csv, collections, statistics as st
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=list(csv.DictReader(open(D+'free_choice_plain.players.csv')))
P={(p['seed'],p['seat']):p for p in players}
cards=list(csv.DictReader(open(D+'free_choice_plain.cards.csv')))
board=collections.defaultdict(list)
for c in cards: board[(c['seed'],c['seat'])].append(c['card'])
def report(tribe, groups):
    seats=[k for k,p in P.items() if p['final_tribe']==tribe]
    print('====',tribe,len(seats),'seats mean place',round(st.mean(int(P[k]['place']) for k in seats),2))
    for name,fn in groups:
        a=[int(P[k]['place']) for k in seats if fn(set(board[k]))]
        b=[int(P[k]['place']) for k in seats if not fn(set(board[k]))]
        fa=sum(1 for x in a if x==1)
        print(f"  {name:45s} with n={len(a):3d} place {st.mean(a) if a else 0:.2f} first {fa/len(a)*100 if a else 0:4.1f}% | without n={len(b):3d} place {st.mean(b) if b else 0:.2f}")
report('Birds',[
 ('cuckoo',lambda s:'cuckoo' in s),
 ('cuckoo + (redwing|lump|ratchet)',lambda s:'cuckoo' in s and bool(s&{'redwing','great_lump','gabble_ratchet'})),
 ('stork',lambda s:'mrs_stork' in s),
 ('mother_goose',lambda s:'mother_goose' in s),
 ('seven_whistlers',lambda s:'seven_whistlers' in s),
 ('gabble_ratchet',lambda s:'gabble_ratchet' in s),
 ('any T6 Bird',lambda s:bool(s&{'seven_whistlers','gabble_ratchet'})),
 ('any T6 at all (proxy: reached T6)',lambda s:True),
])
report('Bog folk',[
 ('lantern_man',lambda s:'lantern_man' in s),
 ('peat_king',lambda s:'peat_king' in s),
 ('prima_donna',lambda s:'prima_donna' in s),
 ('tiddy_mun',lambda s:'tiddy_mun' in s),
 ('ranocchio',lambda s:'signor_ranocchio' in s),
 ('lantern + prima_donna',lambda s:{'lantern_man','prima_donna'}<=s),
 ('spitfire_sal',lambda s:'spitfire_sal' in s),
])
report('Hedgerow folk',[
 ('squire_lollop',lambda s:'squire_lollop' in s),
 ('standing_committee',lambda s:'standing_committee' in s),
 ('alderman_dozey',lambda s:'alderman_dozey' in s),
 ('old_mother_mast',lambda s:'old_mother_mast' in s),
])
# T6 presence by tribe and mean place for those with T6 on board
t6={'seven_whistlers','gabble_ratchet','lantern_man','peat_king','fairy_monarch','queen_of_elfland','old_mother_mast','squire_lollop'}
for t in ['Birds','Bog folk','Fairies','Hedgerow folk','Hunters','Oozes']:
    seats=[k for k,p in P.items() if p['final_tribe']==t]
    own=[k for k in seats if any(c in t6 for c in board[k])]
    t6turn=[int(P[k]['tier6_turn']) for k in seats if int(P[k]['tier6_turn'])>0]
    print(t, 'reached T6:',len(t6turn),'/',len(seats),'median T6 turn',st.median(t6turn) if t6turn else None)
