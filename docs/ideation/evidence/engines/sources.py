import json,sys,glob,collections,statistics as st
import numpy as np
d=sys.argv[1]; R=[int(x) for x in (sys.argv[2] if len(sys.argv)>2 else '10,15').split(',')]
rows=[];fights=[]
for f in sorted(glob.glob(d+'/s*.txt')):
    for line in open(f):
        if line.startswith('eng_row: '):
            r=json.loads(line[9:])
            if r['round']!='final': rows.append(r)
        elif line.startswith('eng_fight: '): fights.append(json.loads(line[11:]))
def cat(k):
    if k.startswith('spell:'): return k
    for p in ['own_tribe','cross_tribe','neutral_unit','self']:
        if k.startswith(p): return p
    return k
for rnd in R:
    tot=collections.Counter(); spells=collections.Counter(); big=[]; bigtier=collections.Counter(); bigparts=collections.Counter(); full=0
    for r in rows:
        if r['round']!=rnd or len(r['board'])<6: continue
        full+=1
        bs=0
        for u in r['board']:
            for k,v in u['parts'].items():
                tot[cat(k)]+=v
        b=max(r['board'],key=lambda u:u['attack']+u['health']); s=sum(u['attack']+u['health'] for u in r['board'])
        big.append((b['attack']+b['health'], (b['attack']+b['health'])/s)); bigtier[b['tier']]+=1
        for k,v in b['parts'].items(): bigparts[cat(k)]+=v
    T=sum(tot.values()); B=sum(bigparts.values())
    print('\n### round %d, full boards (6+ units) n=%d'%(rnd,full))
    for k,v in tot.most_common(14): print('  %-28s %5.1f%%   (biggest unit: %4.1f%%)'%(k,100*v/T,100*bigparts.get(k,0)/B))
    print('  biggest unit: mean %.1f stats, %.0f%% of board; tier mix %s'%(st.mean(x[0] for x in big),100*st.mean(x[1] for x in big),dict(sorted(bigtier.items()))))
# logistic regression on rounds 9+
X=[];y=[]
def feats(s):
    u=s['units']; stats=[x[2]+x[3] for x in u]; tr=collections.Counter(t for x in u for t in x[6])
    return np.array([np.log(max(1,sum(stats))), max(tr.values()) if tr else 0, sum(x[4] for x in u)/max(1,len(u)), len(u), max(stats)/max(1,sum(stats)), sum(x[2]+x[3] for x in u if x[1]>=4)/max(1,sum(stats))])
for f in fights:
    if f['round']<9 or f['winner']<0 or f['sides'][1]['pid']<0: continue
    a=feats(f['sides'][0]);b=feats(f['sides'][1]); X.append(a-b); y.append(1 if f['winner']==0 else 0)
X=np.array(X);y=np.array(y); mu=X.mean(0); sd=X.std(0); Z=(X)/sd
w=np.zeros(Z.shape[1])
for it in range(3000):
    p=1/(1+np.exp(-Z@w)); w+=0.1*Z.T@(y-p)/len(y)
names=['log total stats','kin count','mean tier','unit count','top-unit share','back-row share']
print('\n### logistic, decisive fights r9+, n=%d: standardized coef (per 1 sd of difference)'%len(y))
for n,c,s in zip(names,w,sd): print('  %-16s %+.2f   (sd %.2f)'%(n,c,s))
acc=((1/(1+np.exp(-Z@w))>0.5)==y).mean(); print('  accuracy %.1f%%'%(100*acc))
