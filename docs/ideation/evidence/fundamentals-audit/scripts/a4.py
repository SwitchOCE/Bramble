import csv, collections, statistics as st, json, glob
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
U='/home/alex/code/Bramble-ideation-balance/content/units/'
units={json.load(open(f))['id']:json.load(open(f)) for f in glob.glob(U+'*.json')}
players=[p for p in csv.DictReader(open(D+'free_choice_plain.players.csv')) if p['place']]
key={(p['seed'],p['seat']):p for p in players}
boards=collections.defaultdict(list)
for c in csv.DictReader(open(D+'free_choice_plain.cards.csv')):
    if (c['seed'],c['seat']) in key: boards[(c['seed'],c['seat'])].append(c)
t6=[k for k,p in key.items() if p['tier6_turn'] not in ('','0','-1')]
print('players reaching T6',len(t6),'mean place',round(st.mean(int(key[k]['place']) for k in t6),2))
print('tier6_turn values sample',collections.Counter(p['tier6_turn'] for p in players).most_common(8))
# T6 cards among T6 boards
ids=[i for i,d in units.items() if d.get('set')=='slice' and d['tier']==6 and d.get('pool')]
res=[]
for i in ids:
    bs=[k for k in t6 if any(c['card']==i for c in boards[k])]
    if not bs: continue
    res.append((st.mean(int(key[k]['place']) for k in bs), i, len(bs), sum(key[k]['place']=='1' for k in bs), units[i]['tribes']))
for r in sorted(res): print(f"{r[1]:20s} {str(r[4]):20s} n={r[2]:4d} place={r[0]:.2f} firsts={r[3]}")
# splash: card on own-tribe boards vs others
print('\nsplash check: place on own-tribe-labelled boards vs other boards')
for i in ['squire_lollop','standing_committee','queen_of_elfland','belladonna','peat_king','lantern_man','seven_whistlers','mother_goose','alderman_dozey','old_mother_mast','will_o_the_wisp','silky','reel_mistress','mag_pye','cuckoo','mrs_stork','gideon','jenny_greenteeth','prima_donna','prince_restored']:
    tr=units[i]['tribes'][0]
    own=[k for k,L in boards.items() if any(c['card']==i for c in L) and key[k]['final_tribe']==tr]
    oth=[k for k,L in boards.items() if any(c['card']==i for c in L) and key[k]['final_tribe']!=tr]
    f=lambda ks: (len(ks), round(st.mean(int(key[k]['place']) for k in ks),2) if ks else None)
    print(f"{i:20s} own {f(own)} other {f(oth)}")
