import sys, json, random; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
def spread(b,k):
    return [None if u is None else (u[0]+k,u[1]+k) for u in b]
def on_one(b,k,pick):
    idx=[i for i,u in enumerate(b) if u]
    if pick=='biggest': i=max(idx,key=lambda i:b[i][0]+b[i][1])
    elif pick=='smallest': i=min(idx,key=lambda i:b[i][0]+b[i][1])
    elif pick=='front_biggest':
        fr=[i for i in idx if i<4] or idx; i=max(fr,key=lambda i:b[i][0]+b[i][1])
    out=list(b); u=b[i]; out[i]=(u[0]+k,u[1]+k); return out
def avg(bx,x,scope):
    opp=[y for y in names if y!=x and (scope=='all' or y.split('_')[1]==x.split('_')[1])]
    return sum(match(bx,boards[y],n=100,seed=5)['win'] for y in opp)/len(opp)
for k in (1,2):
    print(f'\nBuff worth {14*k} stats on one plain R9 board; win % vs the other 11 boards (vs same-roll in brackets)')
    print(f'board          base        +{k}/+{k} all      +{7*k}/+{7*k} biggest   +{7*k}/+{7*k} smallest   ')
    tot={'base':[0,0],'spread':[0,0],'big':[0,0],'small':[0,0]}
    for x in names:
        b=boards[x]
        n_units=sum(1 for u in b if u)
        # spread buff covers only existing units: give the same stat total
        per=k*7/n_units
        rows={}
        rows['base']=b
        rows['spread']=[None if u is None else (u[0]+round(per),u[1]+round(per)) for u in b] if n_units==7 else spread(b,k)
        rows['big']=on_one(b,7*k,'biggest'); rows['small']=on_one(b,7*k,'smallest')
        cells=[]
        for key in ('base','spread','big','small'):
            a=avg(rows[key],x,'all'); s=avg(rows[key],x,'same')
            tot[key][0]+=a; tot[key][1]+=s
            cells.append(f'{100*a:5.1f} ({100*s:5.1f})')
        print(f'{x:14s} '+'   '.join(cells))
    print('MEAN           '+'   '.join(f'{100*tot[k2][0]/12:5.1f} ({100*tot[k2][1]/12:5.1f})' for k2 in ('base','spread','big','small')))
