import sys, json; sys.path.insert(0,'.')
from bramble_combat import *
d=json.load(open('/home/alex/code/Bramble-ideation-balance/docs/ideation/evidence/pass2-followup-boards.json'))
LBL=['F1','F2','F3','F4','B1','B2','B3']
boards={}
for b in d['boards']:
    slots=b['slots']; rings=b.get('rings',{})
    arr=[None]*7
    for i,l in enumerate(LBL):
        u=slots.get(l)
        if u:
            a,h=u['attack'],u['health']
            if l in rings: a+=rings[l][0]; h+=rings[l][1]
            arr[i]=(a,h)
    # Eggs on empty Nests (birds): use the assumption text values
    if b['id']=='birds_high': arr[1]=(9,10); arr[3]=(9,9)
    if b['id']=='birds_low': arr[1]=(2,4)
    boards[b['id']]=arr
names=list(boards)
for n in names:
    arr=boards[n]
    tot=sum(a+h for a,h in [x for x in arr if x])
    print(f'{n:14s} units {sum(1 for x in arr if x)}  total {tot:3d}  ', ' '.join(f'{LBL[i]}:{x[0]}/{x[1]}' for i,x in enumerate(arr) if x))
def rr(bd, n=200):
    res={}
    for x in names:
        tot=0
        for y in names:
            if x==y: continue
            res[(x,y)]=match(bd[x],bd[y],n=n,seed=hash((x,y))%100000)['win']
    return res
base=rr(boards)
print('\nPlain-stats round robin (win % vs the other 11 / vs same roll):')
real=json.load(open('/home/alex/code/Bramble-ideation-balance/docs/ideation/evidence/pass2-followup/r9-results.json'))
for x in names:
    allv=[base[(x,y)] for y in names if y!=x]
    same=[base[(x,y)] for y in names if y!=x and y.split('_')[1]==x.split('_')[1]]
    print(f'{x:14s} all {100*sum(allv)/len(allv):5.1f}  same-roll {100*sum(same)/len(same):5.1f}')
# +1/+1 sensitivity (same roll, like the R9 doc)
print('\nPlain +1/+1 sensitivity (same roll; +1/+1 on every unit of one board):')
for x in names:
    up=[None if u is None else (u[0]+1,u[1]+1) for u in boards[x]]
    opp=[y for y in names if y!=x and y.split('_')[1]==x.split('_')[1]]
    b0=sum(base[(x,y)] for y in opp)/len(opp)
    b1=sum(match(up,boards[y],n=200,seed=7)['win'] for y in opp)/len(opp)
    print(f'{x:14s} base {100*b0:5.1f}  +1/+1 {100*b1:5.1f}  change {100*(b1-b0):+5.1f}')
json.dump({f'{a}|{b}':v for (a,b),v in base.items()}, open('r9_plain_rr.json','w'))
