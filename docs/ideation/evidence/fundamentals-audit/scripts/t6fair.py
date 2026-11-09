import csv, statistics as st, json, glob
from collections import defaultdict, Counter
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f): players[(r['seed'],r['seat'])]=r
boards=defaultdict(list)
with open(D+'free_choice_plain.cards.csv') as f:
    for r in csv.DictReader(f): boards[(r['seed'],r['seat'])].append(r)
U={}
for f in glob.glob('/home/alex/code/Bramble-ideation-balance/content/units/*.json'):
    d=json.load(open(f)); U[d['id']]=d
def has(k,c): return any(x['card']==c for x in boards[k])
def summ(ks):
    if not ks: return 'n=0'
    return f"n={len(ks)} place={st.mean(int(players[k]['place']) for k in ks):.2f} first={100*sum(players[k]['place']=='1' for k in ks)/len(ks):.1f}%"
# Players who reached T6 by turn <=14 and survived to at least round 16
for tribe in ['Hedgerow folk','Hunters','Oozes','Bog folk','Birds','no_tribe','ALL']:
    ks=[k for k in players if (tribe=='ALL' or players[k]['final_tribe']==tribe) and 0<int(players[k]['tier6_turn'])]
    l=[k for k in ks if has(k,'squire_lollop')]; nl=[k for k in ks if not has(k,'squire_lollop')]
    print(f"{tribe:14s} reached T6: {summ(ks)} | Lollop on final: {summ(l)} | no Lollop: {summ(nl)}")
# reached T6 at same turn: stratify by tier6_turn bucket
print('--- stratified by tier6_turn, all tribes')
for lo,hi in [(9,12),(13,14),(15,16),(17,30)]:
    ks=[k for k in players if lo<=int(players[k]['tier6_turn'])<=hi]
    l=[k for k in ks if has(k,'squire_lollop')]; nl=[k for k in ks if not has(k,'squire_lollop')]
    i=[k for k in ks if has(k,'old_isegrim')]
    q=[k for k in ks if has(k,'queen_of_elfland')]
    pk=[k for k in ks if has(k,'peat_king')]
    print(f"t6 turn {lo}-{hi}: all {summ(ks)} | Lollop {summ(l)} | noLollop {summ(nl)} | Isegrim {summ(i)} | Queen {summ(q)} | PeatKing {summ(pk)}")
# Lollop count golden
g=Counter(x['golden'] for k in boards for x in boards[k] if x['card']=='squire_lollop')
print('lollop golden',g)
