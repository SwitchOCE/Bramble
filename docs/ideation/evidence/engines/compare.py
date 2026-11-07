import json,sys,glob,collections,random,math
import numpy as np
def load(d):
    G=collections.defaultdict(lambda:{'f':[],'rows':[],'fin':[]})
    for fn in sorted(glob.glob(d+'/s*.txt')):
        cur=[]
        for line in open(fn):
            if line.startswith('eng_fight: '): cur.append(json.loads(line[11:]))
            elif line.startswith('eng_shop: '):
                s=json.loads(line[10:])['seed']; G[s]['f']=cur; cur=[]
            elif line.startswith('eng_row: '):
                r=json.loads(line[9:]); k='fin' if r['round']=='final' else 'rows'; G[r['seed']][k].append(r)
    return {s:g for s,g in G.items() if g['fin'] and g['f']}
def cat(k):
    if k.startswith('spell:'): return 'spell'
    for p in ['own_tribe','cross_tribe','neutral_unit','self']:
        if k.startswith(p): return p
    return k
def kin(board):
    c=collections.Counter(t for u in board for t in u['tribes']); return max(c.values()) if c else 0
def game_metrics(g):
    m={}
    fs=g['f']; place={r['player']:r['place'] for r in g['fin']}
    w=[p for p,v in place.items() if v==1][0]
    m['rounds']=max(f['round'] for f in fs)
    late=[f for f in fs if f['round']>=9 and f['sides'][1]['pid']>=0]
    m['_late_n']=len(late); m['_late_ties']=sum(f['winner']<0 for f in late)
    f4=[f for f in fs if f['alive']<=4]
    if f4:
        r0=f4[0]['round']; hp={}
        for f in fs:
            if f['round']==r0:
                for s in f['sides']:
                    if s['pid']>=0: hp[s['pid']]=s['hp']
        lead=max(hp,key=lambda p:hp[p]); m['hp_leader_at4_wins']=1.0*(lead==w)
        if w in hp: m['comeback']=1.0*(sorted(hp.values(),reverse=True).index(hp[w])>=2)
        m['rounds_after_4']=m['rounds']-r0+1
    duel=[f for f in fs if f['alive']==2 and f['sides'][1]['pid']>=0]
    m['duel_fights']=len(duel)
    # composition at fixed rounds
    for R in (10,12):
        rows=[r for r in g['rows'] if r['round']==R and len(r['board'])>=6]
        tot=collections.Counter()
        for r in rows:
            for u in r['board']:
                for k,v in u['parts'].items(): tot[cat(k)]+=v
        T=sum(tot.values())
        if T:
            m['_c%d'%R]=tot; m['_T%d'%R]=T; m['_n%d'%R]=len(rows)
            m['_stats%d'%R]=sum(sum(u['attack']+u['health'] for u in r['board']) for r in rows)
            bigs=[max(r['board'],key=lambda u:u['attack']+u['health']) for r in rows]
            m['_t1big%d'%R]=sum(b['tier']<=2 for b in bigs)
            m['_bigshare%d'%R]=sum((max(u['attack']+u['health'] for u in r['board']))/max(1,sum(u['attack']+u['health'] for u in r['board'])) for r in rows)
            # commitment at fixed round
            uniq={}
            for r in rows: uniq[r['player']]=r
            m['_kin%d'%R]=[(kin(r['board']),place.get(r['player'])) for r in uniq.values()]
    return m
def fight_X(g):
    X=[];y=[]
    for f in g['f']:
        if f['round']<9 or f['winner']<0 or f['sides'][1]['pid']<0: continue
        def ft(s):
            u=s['units']; st=[x[2]+x[3] for x in u]; tr=collections.Counter(t for x in u for t in x[6])
            return np.array([math.log(max(1,sum(st))), max(tr.values()) if tr else 0, sum(x[4] for x in u)/max(1,len(u))])
        X.append(ft(f['sides'][0])-ft(f['sides'][1])); y.append(1 if f['winner']==0 else 0)
    return X,y
def logit(X,y):
    X=np.array(X);y=np.array(y); sd=np.array([0.29,1.82,0.87]); Z=X/sd; w=np.zeros(3)
    for it in range(1500):
        p=1/(1+np.exp(-Z@w)); w+=0.2*Z.T@(y-p)/len(y)
    return w
def agg(G,seeds):
    M={s:game_metrics(G[s]) for s in seeds}
    out={}
    out['rounds per game']=np.mean([M[s]['rounds'] for s in seeds])
    out['late fights tied %']=100*sum(M[s]['_late_ties'] for s in seeds)/max(1,sum(M[s]['_late_n'] for s in seeds))
    v=[M[s]['hp_leader_at4_wins'] for s in seeds if 'hp_leader_at4_wins' in M[s]]; out['HP leader at 4 left wins %']=100*np.mean(v)
    v=[M[s]['comeback'] for s in seeds if 'comeback' in M[s]]; out['winner was bottom-2 on HP at 4 left %']=100*np.mean(v)
    out['rounds from 4 left']=np.mean([M[s]['rounds_after_4'] for s in seeds if 'rounds_after_4' in M[s]])
    out['duel fights']=np.mean([M[s]['duel_fights'] for s in seeds])
    for R in (10,12):
        C=collections.Counter(); T=0;n=0;st=0;t1=0;bs=0;K=[]
        for s in seeds:
            m=M[s]
            if '_c%d'%R in m: C+=m['_c%d'%R]; T+=m['_T%d'%R]; n+=m['_n%d'%R]; st+=m['_stats%d'%R]; t1+=m['_t1big%d'%R]; bs+=m['_bigshare%d'%R]; K+=m['_kin%d'%R]
        out['r%d board stats (full boards)'%R]=st/max(1,n)
        for k in ['printed','spell','rings','tribe_bonus','own_tribe']:
            out['r%d share %s %%'%(R,k)]=100*C.get(k,0)/max(1,T)
        out['r%d biggest unit tier 1-2 %%'%R]=100*t1/max(1,n)
        out['r%d biggest unit share %%'%R]=100*bs/max(1,n)
        hi=[p for k,p in K if k>=6 and p]; lo=[p for k,p in K if k<=4 and p]
        out['r%d place 6+ kin minus <=4 kin'%R]=(np.mean(hi) if hi else np.nan)-(np.mean(lo) if lo else np.nan)
    X=[];y=[]
    for s in seeds:
        a,b=fight_X(G[s]); X+=a;y+=b
    w=logit(X,y); out['coef log stats']=w[0]; out['coef kin']=w[1]; out['coef tier']=w[2]
    return out
base=load(sys.argv[1]); arms=sys.argv[2:]
random.seed(1)
for arm in arms:
    A=load(arm); seeds=sorted(set(base)&set(A))
    b=agg(base,seeds); a=agg(A,seeds)
    boots=collections.defaultdict(list)
    for it in range(int(__import__('os').environ.get('BOOT','60'))):
        ss=[random.choice(seeds) for _ in seeds]
        bb=agg(base,ss); aa=agg(A,ss)
        for k in a: boots[k].append(aa[k]-bb[k])
    print('\n### %s vs base, %d paired seeds'%(arm.rstrip('/').split('/')[-1],len(seeds)))
    print('| Measure | Base | Arm | Change (95% interval) |\n|---|---:|---:|---:|')
    for k in a:
        lo,hi=np.nanpercentile(boots[k],[2.5,97.5])
        print('| %s | %.2f | %.2f | %+.2f (%+.2f to %+.2f) |'%(k,b[k],a[k],a[k]-b[k],lo,hi))
