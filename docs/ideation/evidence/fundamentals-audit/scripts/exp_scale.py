import sys, json, random; sys.path.insert(0,'.')
from bramble_combat import *
exec(open('exp_r9_plain.py').read().split("names=list(boards)")[0])
names=list(boards)
def plus(b,da,dh): return [None if u is None else (u[0]+da,u[1]+dh) for u in b]
rng=random.Random(11)
print('Plain R9 stat lines scaled by k with jitter (each stat x k, then +/- up to k/2 at random; 4 jitter draws).')
print('Mean change in same-roll win % when one board gets the buff on every unit.')
for k in (1,2,4,10):
    for label,fa in (('+1/+1',lambda b:plus(b,1,1)),('+10% both',lambda b:[None if u is None else (round(u[0]*1.1),round(u[1]*1.1)) for u in b]),('+1 Attack',lambda b:plus(b,1,0)),('+1 Health',lambda b:plus(b,0,1))):
        ch=[]
        for draw in range(4 if k>1 else 1):
            def sc(b):
                if k==1: return b
                return [None if u is None else (max(1,u[0]*k+rng.randint(-(k//2),k//2)), max(1,u[1]*k+rng.randint(-(k//2),k//2))) for u in b]
            bd={x:sc(boards[x]) for x in names}
            for x in names:
                opp=[y for y in names if y!=x and y.split('_')[1]==x.split('_')[1]]
                b0=sum(match(bd[x],bd[y],n=60,seed=3)['win'] for y in opp)/len(opp)
                b1=sum(match(fa(bd[x]),bd[y],n=60,seed=3)['win'] for y in opp)/len(opp)
                ch.append(100*(b1-b0))
        print(f'  k={k:<3} {label:10s} mean change {sum(ch)/len(ch):+5.1f} pp   range {min(ch):+5.1f} to {max(ch):+5.1f}')
