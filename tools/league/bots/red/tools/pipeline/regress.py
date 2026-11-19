# Ridge regression: placement ~ card presence on board at given rounds. Prints per-card effect
# (negative = better placement). usage: regress.py <dir> [<dir>...] --bot NAME
import json,sys,numpy as np
from collections import defaultdict
A=sys.argv[1:]; dirs=[a for i,a in enumerate(A) if not a.startswith('--') and (i==0 or not A[i-1].startswith('--'))]
bot=None
if '--bot' in sys.argv: bot=sys.argv[sys.argv.index('--bot')+1]
ROUNDS=[4,7,10]
rows=[];ys=[];cards=set()
lib={}
for d in dirs:
  for c in json.load(open(d+'/library.json')): lib[c['id']]=c
  for l in open(d+'/games.jsonl'):
    try: g=json.loads(l)
    except: continue
    for s in g['seats']:
      if bot and not s['bot'].startswith(bot): continue
      f={}
      byr={r['round']:r for r in s['rounds']}
      for R in ROUNDS:
        r=byr.get(R)
        if r is None:
          # dead before R: carry last board
          rs=[x for x in s['rounds'] if x['round']<R]
          r=rs[-1] if rs else None
        if r is None: continue
        for u in r['board']:
          k=(R,u['card']); f[k]=1.0; cards.add(u['card'])
      rows.append(f); ys.append(s['place'])
keys=sorted({k for f in rows for k in f})
idx={k:i for i,k in enumerate(keys)}
X=np.zeros((len(rows),len(keys)))
for i,f in enumerate(rows):
  for k,v in f.items(): X[i,idx[k]]=v
y=np.array(ys,float); ym=y.mean()
Xm=X.mean(0); Xc=X-Xm
lam=float(sys.argv[sys.argv.index('--lam')+1]) if '--lam' in sys.argv else 30.0
beta=np.linalg.solve(Xc.T@Xc+lam*np.eye(len(keys)),Xc.T@(y-ym))
print('seats',len(rows),'mean',round(ym,3))
out={}
for c in sorted(cards,key=lambda c:(lib.get(c,{}).get('tier',0),c)):
  vals=[]
  for R in ROUNDS:
    k=(R,c)
    if k in idx: vals.append(f"{beta[idx[k]]:+.2f}({int(X[:,idx[k]].sum())})")
    else: vals.append('      -     ')
  out[c]={str(R):(float(beta[idx[(R,c)]]),int(X[:,idx[(R,c)]].sum())) for R in ROUNDS if (R,c) in idx}
  print(f"{lib.get(c,{}).get('tier',0)} {c:28s}"+' '.join(f'{v:14s}' for v in vals))
if '--out' in sys.argv: json.dump(out,open(sys.argv[sys.argv.index('--out')+1],'w'),indent=0)
