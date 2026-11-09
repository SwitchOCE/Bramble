import sys, json, random; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
lb=0; n=0; close=0
for x in names:
    for y in names:
        if x>=y: continue
        m=match(boards[x],boards[y],n=200,seed=1)
        lb+=m['last_blow']; n+=1
        if 0.1<m['win']<0.9: close+=1
print(f'plain R9 pairs: mean share of fights ending in a mutual wipe settled by Last Blow: {100*lb/n:.1f}%; pairs between 10% and 90%: {close} of {n}')
# survivors distribution when winning, plain R9
s=[];
for x in names:
    for y in names:
        if x==y: continue
        m=match(boards[x],boards[y],n=100,seed=2)
        if m['win']>0: s.append(m['surv_when_win'])
print(f'mean starting survivors when a plain R9 board wins: {sum(s)/len(s):.2f}')
