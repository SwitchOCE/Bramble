import sys, json, random; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
hl=boards['hedgerow_low']
def wr(b, scope='low', x='hedgerow_low'):
    opp=[y for y in names if y!=x and (scope=='all' or y.endswith(scope))]
    rs=[match(b,boards[y],n=400,seed=9) for y in opp]
    return sum(r['win'] for r in rs)/len(rs), sum(r['surv_when_win']*r['win'] for r in rs)/max(1e-9,sum(r['win'] for r in rs))
print('hedgerow_low plain: F1 4/5 F2 4/6 F3 5/5 F4 empty B1 2/3 B2 2/3 B3 Dozey 10/16 (65 stats, 6 units)')
variants={
 'as built (Dozey B3)':hl,
 'Dozey moved to F4':[hl[0],hl[1],hl[2],(10,16),hl[4],hl[5],None],
 'Dozey swapped to F1':[(10,16),hl[1],hl[2],None,hl[4],hl[5],hl[0]],
 'Dozey split into two 5/8s (B3, F4)':[hl[0],hl[1],hl[2],(5,8),hl[4],hl[5],(5,8)],
 'same 65 stats spread evenly over 6 (5/6 or 6/5)':[(5,6),(5,6),(5,6),None,(6,5),(6,5),(6,5)],
 'Dozey 10/16 -> 10/12 (-4 Health)':[hl[0],hl[1],hl[2],None,hl[4],hl[5],(10,12)],
 'Dozey 10/16 -> 7/16 (-3 Attack)':[hl[0],hl[1],hl[2],None,hl[4],hl[5],(7,16)],
 'Dozey 10/16 -> 14/20 (+4/+4)':[hl[0],hl[1],hl[2],None,hl[4],hl[5],(14,20)],
}
for k,b in variants.items():
    w,s=wr(b); wa,_=wr(b,'all')
    print(f'  {k:48s} vs low boards {100*w:5.1f}%  (survivors when winning {s:.2f})   vs all 11 {100*wa:5.1f}%')
