import sys; sys.path.insert(0,'.')
from bramble_combat import *
def place(carry, smalls, carry_slot):
    b=[None]*7
    b[carry_slot]=carry
    free=[s for s in [0,1,2,3,4,5,6] if s!=carry_slot]
    for s,u in zip(free, smalls): b[s]=u
    return b
even=[(6,6)]*7
print('Even board 7 x 6/6 (84 stats). Carry boards have the same 84 stats.')
print('carry   smalls     carry@F1 win%  surv  | carry@B2 win%  surv')
for s in [6,5,4,3,2,1]:
    c=42-6*s
    if c<=0: continue
    f=match(place((c,c),[(s,s)]*6,0),even,n=2000,seed=s)
    bk=match(place((c,c),[(s,s)]*6,5),even,n=2000,seed=s+50)
    print(f'{c:>2}/{c:<2}  6x{s}/{s}      {100*f["win"]:6.1f}  {f["surv_when_win"]:.2f}  |  {100*bk["win"]:6.1f}  {bk["surv_when_win"]:.2f}')
print('\nCarry with fewer helpers (still 84 stats), carry at F1:')
for helpers,s in [(5,6),(4,6),(3,6),(2,6),(2,8),(1,6),(0,0)]:
    c=(84-2*s*helpers)//2
    b=place((c,c),[(s,s)]*helpers,0)
    m=match(b,even,n=2000,seed=helpers*7+s)
    print(f'{c}/{c} + {helpers} x {s}/{s}: win {100*m["win"]:.1f}%  survivors when it wins {m["surv_when_win"]:.2f}')
print('\nWhat the even board needs: 7 x k/k vs carry 24/24 + 6x3/3 (84) at F1')
for k in range(6,12):
    m=match([(k,k)]*7, place((24,24),[(3,3)]*6,0),n=2000,seed=k)
    print(f'7x{k}/{k} ({14*k} stats): even board wins {100*m["win"]:.1f}%')
