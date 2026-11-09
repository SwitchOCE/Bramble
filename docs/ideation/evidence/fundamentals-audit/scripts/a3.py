import csv, collections, statistics as st, json, glob, os
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
U='/home/alex/code/Bramble-ideation-balance/content/units/'
units={}
for f in glob.glob(U+'*.json'):
    d=json.load(open(f)); units[d['id']]=d
players=[p for p in csv.DictReader(open(D+'free_choice_plain.players.csv')) if p['place']]
key={(p['seed'],p['seat']):p for p in players}
cards=[c for c in csv.DictReader(open(D+'free_choice_plain.cards.csv')) if (c['seed'],c['seat']) in key and c['card']]
print('card rows',len(cards))
boards=collections.defaultdict(list)
for c in cards: boards[(c['seed'],c['seat'])].append(c)
# overall
allplace=st.mean(int(p['place']) for p in players)
tribes=['Birds','Bog folk','Fairies','Hedgerow folk']
out=[]
for tr in tribes:
    ids=sorted([i for i,d in units.items() if d.get('set')=='slice' and tr in d.get('tribes',[])], key=lambda i:(units[i]['tier'],i))
    out.append(f"\n## {tr}: card on final boards (all 3200 boards). n_boards=boards containing it; mean place; share golden; n on boards labelled {tr}; mean copies per {tr} board")
    trboards=[k for k,p in key.items() if p['final_tribe']==tr]
    for i in ids:
        bs=[k for k,L in boards.items() if any(c['card']==i for c in L)]
        g=sum(1 for c in cards if c['card']==i and c['golden']=='1'); n=sum(1 for c in cards if c['card']==i)
        pl=st.mean(int(key[k]['place']) for k in bs) if bs else float('nan')
        win=sum(1 for k in bs if key[k]['place']=='1')
        intr=sum(1 for k in trboards if any(c['card']==i for c in boards[k]))
        out.append(f"{units[i]['tier']} {i:22s} boards={len(bs):4d} place={pl:.2f} firsts={win:3d} golden={g}/{n} on_{tr[:4]}_boards={intr}/{len(trboards)} pool={units[i].get('pool')}")
print('\n'.join(out))
