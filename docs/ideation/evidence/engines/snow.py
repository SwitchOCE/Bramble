import json,sys,glob,collections,statistics as st
d=sys.argv[1]
games=[]
for f in sorted(glob.glob(d+'/s*.txt')):
    cur={'rows':[],'finals':[]}
    for line in open(f):
        if line.startswith('eng_row: '):
            r=json.loads(line[9:])
            (cur['finals'] if r['round']=='final' else cur['rows']).append(r)
        elif line.startswith('eng_shop: '):
            games.append(cur); cur={'rows':[],'finals':[]}
    if cur['finals']: games[-1]['finals']+=cur['finals']
# eng_row finals printed after eng_shop: reassign by seed
by=collections.defaultdict(lambda:{'rows':[],'finals':[]})
for f in sorted(glob.glob(d+'/s*.txt')):
    rows=[];
    for line in open(f):
        if line.startswith('eng_row: '):
            r=json.loads(line[9:])
            if r['round']=='final': by[r['seed']]['finals'].append(r)
            else: by[r['seed']]['rows'].append(r)
def spearman(a,b):
    import math
    ra={v:i for i,v in enumerate(sorted(range(len(a)),key=lambda i:a[i]))}
    rb={v:i for i,v in enumerate(sorted(range(len(b)),key=lambda i:b[i]))}
    n=len(a); return 1-6*sum((ra[i]-rb[i])**2 for i in range(n))/(n*(n*n-1))
for rnd in [5,7,9,11]:
    rs=[];top=[0,0]
    for s,g in by.items():
        place={r['player']:r['place'] for r in g['finals']}
        st_={}
        for r in g['rows']:
            if r['round']==rnd: st_[r['player']]=sum(u['attack']+u['health'] for u in r['board'])
        ps=[p for p in st_ if p in place]
        if len(ps)<5: continue
        rs.append(spearman([-st_[p] for p in ps],[place[p] for p in ps]))
        lead=max(ps,key=lambda p:st_[p]); top[1]+=1; top[0]+=place[lead]<=2
    print('round %d: rank corr(board stats, final place) %.2f; stat leader finishes top-2 %.0f%%'%(rnd,st.mean(rs),100*top[0]/top[1]))
