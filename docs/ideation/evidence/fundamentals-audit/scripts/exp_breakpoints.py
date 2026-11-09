import sys, json; sys.path.insert(0,'.')
from bramble_combat import *
print('Breakpoint scan: 7 x A/H against 7 x 10/10 (win % of the scanned board)')
print('  H\\A ' + ' '.join(f'{a:>5}' for a in range(7,14)))
for h in range(7,23):
    row=[]
    for a in range(7,14):
        row.append(100*match([(a,h)]*7,[(10,10)]*7,n=200,seed=a*100+h)['win'])
    print(f'  {h:>3} ' + ' '.join(f'{x:5.0f}' for x in row))
# scale test on the plain R9 boards
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
def scaled(b,k): return [None if u is None else (u[0]*k,u[1]*k) for u in b]
def plus(b,da,dh): return [None if u is None else (u[0]+da,u[1]+dh) for u in b]
print('\nMean |change| in same-roll win % from a buff to every unit of one board, plain R9 stat lines scaled by k')
for k in (1,2,4,10):
    for label,fa in (('+1/+1',lambda b:plus(b,1,1)),('+10%',lambda b:[None if u is None else (round(u[0]*1.1),round(u[1]*1.1)) for u in b]),('+1 Attack only',lambda b:plus(b,1,0)),('+1 Health only',lambda b:plus(b,0,1))):
        ch=[]
        for x in names:
            opp=[y for y in names if y!=x and y.split('_')[1]==x.split('_')[1]]
            bx=scaled(boards[x],k)
            b0=sum(match(bx,scaled(boards[y],k),n=100,seed=3)['win'] for y in opp)/len(opp)
            b1=sum(match(fa(bx),scaled(boards[y],k),n=100,seed=3)['win'] for y in opp)/len(opp)
            ch.append(100*(b1-b0))
        print(f'  k={k:<3} {label:15s} mean change {sum(ch)/len(ch):+5.1f} pp   range {min(ch):+5.1f} to {max(ch):+5.1f}')
