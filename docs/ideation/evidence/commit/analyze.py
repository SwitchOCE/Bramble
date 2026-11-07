import json,glob,sys,collections as C,statistics as st
rows=[]
for f in glob.glob(sys.argv[1]+'/hard*.txt'):
    for l in open(f):
        if l.startswith('commit_row: '): rows.append(json.loads(l[12:]))
def tribes_of(board):
    c=C.Counter()
    for u in board:
        for t in u['tribes']: c[t]+=1
    return c
print("== tribes held (count of distinct tribes with >=1 unit; main tribe share)")
for rnd in [10,15,'final']:
    for grp,cond in [('top4',lambda p:p<=4),('bot4',lambda p:p>4),('win',lambda p:p==1)]:
        R=[r for r in rows if r['round']==rnd and cond(r['place'])]
        if not R: continue
        nt=[len(tribes_of(r['board'])) for r in R]
        main=[ (max(tribes_of(r['board']).values()) if tribes_of(r['board']) else 0)/max(1,len(r['board'])) for r in R]
        neut=[sum(1 for u in r['board'] if not u['tribes'])/max(1,len(r['board'])) for r in R]
        tw=[sum(1 for v in tribes_of(r['board']).values() if v>=2) for r in R]
        print(rnd,grp,'n=%d'%len(R),'tribes=%.2f'%st.mean(nt),'tribes_with2+=%.2f'%st.mean(tw),'main_share=%.2f'%st.mean(main),'neutral_share=%.2f'%st.mean(neut), 'units=%.1f'%st.mean(len(r['board']) for r in R))
print("== main tribe count distribution, final, top4 vs bot4")
for grp,cond in [('top4',lambda p:p<=4),('bot4',lambda p:p>4),('win',lambda p:p==1)]:
    R=[r for r in rows if r['round']=='final' and cond(r['place'])]
    d=C.Counter(max(tribes_of(r['board']).values()) if tribes_of(r['board']) else 0 for r in R)
    print(grp,sorted(d.items()))
print("== stat split by source (share of board total), round 10/15")
for rnd in [10,15]:
  for grp,cond in [('all',lambda p:True),('top4',lambda p:p<=4)]:
    tot=C.Counter(); spl=C.Counter()
    for r in rows:
        if r['round']==rnd and cond(r['place']):
            for u in r['board']:
                for k,v in u['parts'].items(): tot['spell' if k.startswith('spell:') else k]+=v; spl[k]+=v if k.startswith('spell:') else 0
    s=sum(tot.values())
    print('  spells:',[(k,round(100*v/sum(tot.values()),1)) for k,v in spl.most_common(6)])
    print(rnd,grp,' '.join('%s=%.0f%%'%(k,100*v/s) for k,v in tot.most_common()))
print("== stats per unit by tier on boards (atk+hp), r10/r15/final; printed avg")
for rnd in [10,15,'final']:
    by=C.defaultdict(list)
    for r in rows:
        if r['round']==rnd:
            for u in r['board']: by[u['tier']].append(u['attack']+u['health'])
    print(rnd,' '.join('T%d:%.1f(n%d)'%(t,st.mean(v),len(v)) for t,v in sorted(by.items())))
print("== biggest unit share of board stats, r15 and final, winners of fight? use place")
for rnd in [15,'final']:
    for grp,cond in [('top4',lambda p:p<=4),('bot4',lambda p:p>4),('win',lambda p:p==1)]:
        R=[r for r in rows if r['round']==rnd and cond(r['place']) and r['board']]
        sh=[max(u['attack']+u['health'] for u in r['board'])/sum(u['attack']+u['health'] for u in r['board']) for r in R]
        tot=[sum(u['attack']+u['health'] for u in r['board']) for r in R]
        print(rnd,grp,'top-unit share=%.2f'%st.mean(sh),'board total=%.0f'%st.mean(tot))
print("== builds of winners / tribe of biggest unit on winning final boards")
print(C.Counter(r['build'] for r in rows if r['round']=='final' and r['place']==1).most_common())
big=C.Counter()
for r in rows:
    if r['round']=='final' and r['place']<=2 and r['board']:
        u=max(r['board'],key=lambda u:u['attack']+u['health']); big[(u['id'],tuple(u['tribes']))]+=1
print(big.most_common(15))
print("== most common units on top4 final boards")
c=C.Counter()
for r in rows:
    if r['round']=='final' and r['place']<=4:
        for u in r['board']: c[u['id']]+=1
print(c.most_common(20))
print("== build share among all seats")
print(C.Counter(r['build'].split(':')[-1] for r in rows if r['round']=='final').most_common())
print("== placement by main-tribe count (final boards)")
d=C.defaultdict(list)
for r in rows:
    if r['round']=='final':
        tc=tribes_of(r['board']); m=max(tc.values()) if tc else 0
        d[min(m,7)].append(r['place'])
for k in sorted(d): print(k,'n=%d'%len(d[k]),'avg place=%.2f'%st.mean(d[k]),'win%%=%.0f'%(100*sum(1 for p in d[k] if p==1)/len(d[k])))
print("== placement by main-tribe count at round 10 (who reached it)")
d=C.defaultdict(list)
for r in rows:
    if r['round']==10:
        tc=tribes_of(r['board']); m=max(tc.values()) if tc else 0
        d[min(m,7)].append(r['place'])
for k in sorted(d): print(k,'n=%d'%len(d[k]),'avg place=%.2f'%st.mean(d[k]))
print("== golden share by tier, r15")
g=C.defaultdict(lambda:[0,0])
for r in rows:
    if r['round']==15:
        for u in r['board']: g[u['tier']][0]+=u['golden']; g[u['tier']][1]+=1
print({t:'%.0f%%'%(100*a/b) for t,(a,b) in sorted(g.items())})
print("== r15 per-tier: printed vs buffs (non-golden only)")
for rnd in [10,15]:
    by=C.defaultdict(list); pr=C.defaultdict(list)
    for r in rows:
        if r['round']==rnd:
            for u in r['board']:
                if u['golden']: continue
                by[u['tier']].append(u['attack']+u['health']); pr[u['tier']].append(u['parts']['printed'])
    print(rnd,' '.join('T%d:%.1f/printed %.1f'%(t,st.mean(by[t]),st.mean(pr[t])) for t in sorted(by)))
