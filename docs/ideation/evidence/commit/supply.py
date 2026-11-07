import json,sys,collections as C,statistics as st
for t in sys.argv[2:]:
    f=sys.argv[1]+'/t%s/hard0.txt'%t
    rows=[];shops=[]
    for l in open(f):
        if l.startswith('commit_row: '): rows.append(json.loads(l[12:]))
        if l.startswith('commit_shop: '): shops.append(json.loads(l[13:]))
    # supply: per player-game, own build tribe units seen per shop by band
    sup=C.defaultdict(list); pertribe=C.defaultdict(list)
    for g in shops:
        for pid,seen in g['seen'].items():
            for band in ['early','mid','late']:
                n=seen.get('shops|'+band,0)
                if not n: continue
                for tr in g['lobby']:
                    pertribe[(tr,band)].append(seen.get(tr+'|'+band,0)/n)
    def tribes_of(b):
        c=C.Counter()
        for u in b:
            for x in u['tribes']: c[x]+=1
        return c
    fin=[r for r in rows if r['round']=='final']
    main=[max(tribes_of(r['board']).values() or [0]) for r in fin]
    top=[max(tribes_of(r['board']).values() or [0]) for r in fin if r['place']<=4]
    d=C.defaultdict(list)
    for r in fin:
        m=max(tribes_of(r['board']).values() or [0]); d['<=4' if m<=4 else ('5' if m==5 else '6+')].append(r['place'])
    pick=C.Counter(r['build'].split('_')[0] for r in fin)
    win=C.Counter(r['build'].split('_')[0] for r in fin if r['place']==1)
    r15=[r for r in rows if r['round']==15]
    tot15=st.mean(sum(u['attack']+u['health'] for u in r['board']) for r in r15) if r15 else 0
    print('== tribes per lobby',t,'| final main-tribe units %.2f, top4 %.2f'%(st.mean(main),st.mean(top)),'| place by main:',{k:'%.2f(n%d)'%(st.mean(v),len(v)) for k,v in sorted(d.items())},'| r15 board stats %.0f'%tot15,'| rounds %.1f'%st.mean(max(x['round'] for x in rows if x['seed']==s and x['round']!='final') for s in set(r['seed'] for r in rows)))
    print('   picks',dict(pick),' wins',dict(win))
    bt=C.defaultdict(dict)
    for (tr,band),v in pertribe.items(): bt[tr][band]='%.2f'%st.mean(v)
    print('   units of each tribe per shop view:',{k:bt[k] for k in sorted(bt)})
