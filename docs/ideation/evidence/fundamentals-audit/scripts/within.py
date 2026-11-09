import csv, statistics as st
from collections import defaultdict, Counter
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players={}
with open(D+'free_choice_plain.players.csv') as f:
    for r in csv.DictReader(f): players[(r['seed'],r['seat'])]=r
boards=defaultdict(list)
with open(D+'free_choice_plain.cards.csv') as f:
    for r in csv.DictReader(f): boards[(r['seed'],r['seat'])].append(r)
def has(k,c): return any(x['card']==c for x in boards[k])
def summ(ks):
    if not ks: return 'n=0'
    return f"n={len(ks)} place={st.mean(int(players[k]['place']) for k in ks):.2f} first={100*sum(players[k]['place']=='1' for k in ks)/len(ks):.1f}% top4={100*sum(int(players[k]['place'])<=4 for k in ks)/len(ks):.1f}%"
for tribe,cards in [('Hedgerow folk',['squire_lollop','standing_committee','old_mother_mast','alderman_dozey','goodman_hayward','mrs_mallow','honorary_treasurer','mr_pym','dr_urchin']),('Hunters',['old_isegrim','grizel','little_nip','old_lutra','laird_of_sett','madame_ermeline','lodger','squire_lollop','standing_committee']),('Oozes',['granny_stir_up','elder_ooze','wee_wobbly','bubble_and_squeak','mr_syllabub','figgy_duff','squire_lollop'])]:
    ks=[k for k in players if players[k]['final_tribe']==tribe]
    print('====',tribe, summ(ks))
    for c in cards:
        w=[k for k in ks if has(k,c)]; wo=[k for k in ks if not has(k,c)]
        print(f"  {c:20s} with: {summ(w)} | without: {summ(wo)}")
# Lollop + Committee together on any board
ks=list(players)
both=[k for k in ks if has(k,'squire_lollop') and has(k,'standing_committee')]
print('Lollop+Committee any tribe', summ(both))
print('Lollop no Committee', summ([k for k in ks if has(k,'squire_lollop') and not has(k,'standing_committee')]))
print('Isegrim no Lollop', summ([k for k in ks if has(k,'old_isegrim') and not has(k,'squire_lollop')]))
print('Isegrim + Lollop', summ([k for k in ks if has(k,'old_isegrim') and has(k,'squire_lollop')]))
# any T6 on board baseline
import json,glob
U={}
for f in glob.glob('/home/alex/code/Bramble-ideation-balance/content/units/*.json'):
    d=json.load(open(f)); U[d['id']]=d
t6=[k for k in ks if any(U.get(x['card'],{}).get('tier')==6 for x in boards[k])]
print('any T6 on final board', summ(t6))
t6nl=[k for k in t6 if not has(k,'squire_lollop')]
print('T6 but no Lollop', summ(t6nl))
# final units distribution
cnt=Counter(int(players[k]['final_units']) for k in ks)
print('final units dist',sorted(cnt.items()))
