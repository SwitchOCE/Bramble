import sys, random; sys.path.insert(0,'.')
from bramble_combat import *
def board(units, carry_slot=0):
    b=[None]*7
    order=[carry_slot]+[s for s in range(7) if s!=carry_slot]
    for s,u in zip(order,units): b[s]=u
    return b
print('Head to head. Spread = 7 x (b+k)/(b+k). Concentrated = 6 x b/b + one (b+7k)/(b+7k). Equal stats.')
print('Win % of the CONCENTRATED board (carry at F1 | carry at B2), ties shown as t')
for k in (1,2):
    print(f'\n-- k={k}: +{k}/+{k} on all seven vs +{7*k}/+{7*k} on one')
    for b in [2,3,4,5,6,8,10,12,15,20,30,50,100]:
        spread=board([(b+k,b+k)]*7)
        cf=board([(b+7*k,b+7*k)]+[(b,b)]*6,0)
        cb=board([(b+7*k,b+7*k)]+[(b,b)]*6,5)
        m1=match(cf,spread,n=1000,seed=b); m2=match(cb,spread,n=1000,seed=b+1)
        print(f' base {b:>3}/{b:<3}: conc@F1 {100*m1["win"]:5.1f}  conc@B2 {100*m2["win"]:5.1f}')
# vs a heterogeneous reference board drawn from a realistic spread: same total as spread board
print('\nAgainst 300 random heterogeneous reference boards with the same total stats as the spread board')
rng=random.Random(7)
for k in (1,):
    for b in [3,5,8,12,20]:
        tot=14*(b+k)
        wins_s=wins_c=0; n=0
        for r in range(300):
            # random 7 units with stats around b+k, total fixed
            parts=[rng.uniform(0.5,1.5) for _ in range(7)]
            sc=sum(parts)
            sizes=[max(2,round(tot*p/sc)) for p in parts]
            units=[]
            for s in sizes:
                a=max(1,round(s*rng.uniform(0.35,0.55))); units.append((a,max(1,s-a)))
            units.sort(key=lambda u:-u[0])
            ref=board(units)
            spread=board([(b+k,b+k)]*7)
            cf=board([(b+7*k,b+7*k)]+[(b,b)]*6,0)
            wins_s+=match(spread,ref,n=40,seed=r)['win']
            wins_c+=match(cf,ref,n=40,seed=r+999)['win']
            n+=1
        print(f' base {b}: spread +{k}/+{k} wins {100*wins_s/n:.1f}%  |  +{7*k}/+{7*k} on one wins {100*wins_c/n:.1f}%')
