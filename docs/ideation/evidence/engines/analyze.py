import json,sys,glob,collections,math,statistics as st
d=sys.argv[1]
fights=[];rows=[];
for f in sorted(glob.glob(d+'/s*.txt')):
    seed=None
    for line in open(f):
        if line.startswith('eng_fight: '): fights.append(json.loads(line[11:]))
        elif line.startswith('eng_row: '): rows.append(json.loads(line[9:]))
# attach seed to fights: rows have seed; fights sequential per file; infer game boundary by round reset
games=collections.defaultdict(list)
finals=[r for r in rows if r['round']=='final']
print('games',len(set(r['seed'] for r in finals)),'fights',len(fights))
def side_feats(s):
    u=s['units']; stats=[x[2]+x[3] for x in u]
    tribes=collections.Counter()
    for x in u:
        for t in x[6]: tribes[t]+=1
    return dict(n=len(u),tot=sum(stats),mx=max(stats) if stats else 0,
        top2=sum(sorted(stats)[-2:]),kin=max(tribes.values()) if tribes else 0,
        atk=sum(x[2] for x in u),hp=sum(x[3] for x in u),tiers=sum(x[4] for x in u),
        rest=sum(stats)-(max(stats) if stats else 0))
def band(r): return '1-4' if r<=4 else '5-8' if r<=8 else '9-12' if r<=12 else '13+'
# 1 predictors
print('\n## Who wins a decisive fight: share won by the side with more of X (ties in X skipped)')
keys=['tot','mx','top2','rest','n','kin','tiers','atk','hp']
res=collections.defaultdict(lambda: collections.defaultdict(lambda:[0,0]))
for f in fights:
    if f['winner']<0 or f['sides'][1]['pid']<0: continue
    a=side_feats(f['sides'][0]);b=side_feats(f['sides'][1])
    for k in keys:
        if a[k]==b[k]: continue
        hi=0 if a[k]>b[k] else 1
        c=res[band(f['round'])][k]; c[1]+=1; c[0]+= (f['winner']==hi)
print('band | '+' | '.join(keys))
for bnd in ['1-4','5-8','9-12','13+']:
    print(bnd,'|',' | '.join('%.0f%% (%d)'%(100*res[bnd][k][0]/max(1,res[bnd][k][1]),res[bnd][k][1]) for k in keys))
# conditional: bigger mx but smaller tot
print('\n## Conflicts: side with bigger top unit but smaller total')
cc=collections.defaultdict(lambda:[0,0])
for f in fights:
    if f['winner']<0 or f['sides'][1]['pid']<0: continue
    a=side_feats(f['sides'][0]);b=side_feats(f['sides'][1])
    if (a['mx']-b['mx'])*(a['tot']-b['tot'])<0:
        hi=0 if a['mx']>b['mx'] else 1
        c=cc[band(f['round'])];c[1]+=1;c[0]+=(f['winner']==hi)
for bnd in ['5-8','9-12','13+']: print(bnd,'bigger-top-unit wins %.0f%% of %d'%(100*cc[bnd][0]/max(1,cc[bnd][1]),cc[bnd][1]))
# stat ratio curve
print('\n## Win rate by total-stat ratio (bigger/smaller), rounds 9+')
bins=[1.0,1.1,1.25,1.5,2,3,99]; bc=collections.defaultdict(lambda:[0,0,0])
for f in fights:
    if f['round']<9 or f['sides'][1]['pid']<0: continue
    a=side_feats(f['sides'][0]);b=side_feats(f['sides'][1])
    if min(a['tot'],b['tot'])==0: continue
    hi=0 if a['tot']>=b['tot'] else 1; r=max(a['tot'],b['tot'])/min(a['tot'],b['tot'])
    for i in range(len(bins)-1):
        if bins[i]<=r<bins[i+1]:
            c=bc[i];c[2]+=1
            if f['winner']==hi:c[0]+=1
            elif f['winner']<0:c[1]+=1
for i in range(len(bins)-1): c=bc[i]; print('%.2f-%.2f: bigger wins %.0f%%, tie %.0f%%, n=%d'%(bins[i],bins[i+1],100*c[0]/max(1,c[2]),100*c[1]/max(1,c[2]),c[2]))
# 2 kills by biggest unit
print('\n## Kills: share of a winning side\'s kills made by its biggest unit, and biggest unit slot')
sh=collections.defaultdict(list); slots=collections.Counter(); survive=collections.defaultdict(lambda:[0,0])
for f in fights:
    if f['winner']<0: continue
    s=f['sides'][f['winner']]; u=s['units']
    if not u: continue
    big=max(u,key=lambda x:x[2]+x[3]); uid=str(big[7])
    tk=sum(v for k,v in f['kills'].items() if any(str(x[7])==k for x in u))
    if tk: sh[band(f['round'])].append(f['kills'].get(uid,0)/tk)
    if f['round']>=9: slots['F' if big[1]<4 else 'B']+=1
    sv=survive[band(f['round'])]; sv[1]+=1; sv[0]+= big[7] not in f['deaths']
for bnd in ['5-8','9-12','13+']: print(bnd,'biggest-unit kill share %.0f%% (n=%d); biggest survives %.0f%%; units/board %s'%(100*st.mean(sh[bnd]),len(sh[bnd]),100*survive[bnd][0]/max(1,survive[bnd][1]),''))
print('biggest unit row, r9+:',dict(slots))
# 3 ties
print('\n## Ties by round band and reason (player fights, ghost excluded)')
tb=collections.defaultdict(collections.Counter)
for f in fights:
    if f['sides'][1]['pid']<0: continue
    tb[band(f['round'])]['all']+=1
    if f['winner']<0: tb[band(f['round'])][f['reason']]+=1
for bnd in ['1-4','5-8','9-12','13+']: c=tb[bnd]; print(bnd, 'n=%d'%c['all'], {k:'%.1f%%'%(100*v/c['all']) for k,v in c.items() if k!='all'})
# attacks per fight
ap=collections.defaultdict(list)
for f in fights: ap[band(f['round'])].append(f['attacks'])
print('attacks/fight', {b:round(st.mean(v),1) for b,v in ap.items()})
# ties: describe
print('\n## Tie boards r9+: mean survivors, whether one side had 0 attack units')
tl=[f for f in fights if f['winner']<0 and f['round']>=9 and f['sides'][1]['pid']>=0]
for f in tl[:6]:
    print(f['round'],f['reason'],f['attacks'],[[ (x[0],x[2],x[3]) for x in s['units']] for s in f['sides']])
# 4 damage and endings
print('\n## Damage per decisive fight by alive count')
dm=collections.defaultdict(list)
for f in fights:
    if f['winner']>=0 and f['sides'][1]['pid']>=0: dm[f['alive']].append((f['damage'],f['uncapped']))
for k in sorted(dm): print('alive',k,'dmg %.1f uncapped %.1f n=%d'%(st.mean(x[0] for x in dm[k]),st.mean(x[1] for x in dm[k]),len(dm[k])))
