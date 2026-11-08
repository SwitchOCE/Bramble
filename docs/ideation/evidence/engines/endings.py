import json,sys,glob,collections,statistics as st
d=sys.argv[1]
games=[]
for f in sorted(glob.glob(d+'/s*.txt')):
    cur=[]
    finals=[]
    for line in open(f):
        if line.startswith('eng_fight: '): cur.append(json.loads(line[11:]))
        elif line.startswith('eng_shop: '):
            games.append({'fights':cur,'finals':[]}); cur=[]
        elif line.startswith('eng_row: '):
            r=json.loads(line[9:])
            if r['round']=='final': games[-1]['finals'].append(r)
print('games',len(games))
L=[];duel=[];hp_lead=[0,0];board_lead=[0,0];duel_len=[];duel_ties=[];three=[];comeback=0;n3=0
for g in games:
    fs=g['fights']; 
    if not fs: continue
    place={r['player']:r['place'] for r in g['finals']}
    winner=[p for p,v in place.items() if v==1]
    if not winner: continue
    w=winner[0]
    L.append(max(f['round'] for f in fs))
    df=[f for f in fs if f['alive']==2 and f['sides'][1]['pid']>=0]
    if df:
        duel_len.append(len(df)); duel_ties.append(sum(f['winner']<0 for f in df))
        f0=df[0]; s=f0['sides']; 
        hps=[x['hp'] for x in s]; ids=[x['pid'] for x in s]
        tots=[sum(u[2]+u[3] for u in x['units']) for x in s]
        if hps[0]!=hps[1]:
            hp_lead[1]+=1; hp_lead[0]+= ids[hps.index(max(hps))]==w
        if tots[0]!=tots[1]:
            board_lead[1]+=1; board_lead[0]+= ids[tots.index(max(tots))]==w
        duel.append((hps,ids.index(w)))
    # at 4 alive: did HP leader win? comeback from last
    f4=[f for f in fs if f['alive']<=4]
    if f4:
        r0=f4[0]['round']; hp={}
        for f in fs:
            if f['round']==r0:
                for s in f['sides']:
                    if s['pid']>=0: hp[s['pid']]=s['hp']
        if w in hp:
            n3+=1; rank=sorted(hp.values(),reverse=True).index(hp[w])+1
            three.append(rank)
print('mean rounds %.1f (sd %.1f), range %d-%d'%(st.mean(L),st.stdev(L),min(L),max(L)))
print('duel fights per game %.2f; ties in duel %.2f/game; duel lasts >=3 fights: %.0f%%'%(st.mean(duel_len),st.mean(duel_ties),100*sum(x>=3 for x in duel_len)/len(duel_len)))
print('duel: HP leader at duel start wins %.0f%% (n=%d); board-stat leader wins %.0f%% (n=%d)'%(100*hp_lead[0]/hp_lead[1],hp_lead[1],100*board_lead[0]/board_lead[1],board_lead[1]))
print('winner HP rank when 4 alive:',collections.Counter(three))
gaps=[abs(h[0]-h[1]) for h,_ in duel]; print('HP gap at duel start: mean %.1f, median %d; duel start HP mean %.1f'%(st.mean(gaps),st.median(gaps),st.mean([x for h,_ in duel for x in h])))
# per game: rounds from first elimination
