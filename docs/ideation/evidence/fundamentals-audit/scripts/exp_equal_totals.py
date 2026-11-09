import sys; sys.path.insert(0,'.')
from bramble_combat import *
def even(S, n):
    # split S stats over n units, attack = health as near as possible, remainder spread
    per = S // n; rem = S % n
    out=[]
    for i in range(n):
        t = per + (1 if i < rem else 0)
        a = t // 2; h = t - a
        out.append((a, h))
    return out
def B(units):
    # placement: bots' rule 'hitters in front, biggest first' -> biggest in front
    units = sorted(units, key=lambda u: -(u[0]+u[1]))
    b=[None]*7
    for s,u in zip([0,1,2,3,4,5,6], units): b[s]=u
    return b
for S in (840, 70, 160):
    print(f'\n== total stats {S}: row board win % vs column board (ties in brackets)')
    print('n  units   ' + '  '.join(f'n={j}' for j in range(1,8)))
    for i in range(1,8):
        cells=[]
        for j in range(1,8):
            if i==j: cells.append('  -- '); continue
            m=match(B(even(S,i)),B(even(S,j)),n=1000,seed=i*10+j)
            cells.append(f'{100*m["win"]:5.1f}')
        print(i, even(S,i)[0], ' '.join(cells))
