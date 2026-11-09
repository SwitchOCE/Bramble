import csv, collections, statistics as st
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=[p for p in csv.DictReader(open(D+'free_choice_plain.players.csv')) if p['place']]
key={(p['seed'],p['seat']):p for p in players}
rows=[r for r in csv.DictReader(open(D+'free_choice_plain.rounds.csv')) if all(v not in (None,) for v in r.values()) and (r['seed'],r['seat']) in key and r['units']!='']
print('round rows',len(rows))
def q(xs,p):
    xs=sorted(xs); 
    if not xs: return float('nan')
    i=min(len(xs)-1,int(p*len(xs))); return xs[i]
agg=collections.defaultdict(list)
for r in rows:
    p=key[(r['seed'],r['seat'])]
    t=p['final_tribe']
    R=int(r['round'])
    u=int(r['units']); a=int(r['attack']); h=int(r['health'])
    agg[(t,R)].append((u,a,h,int(p['place']),int(r['tier'])))
    agg[('ALL',R)].append((u,a,h,int(p['place']),int(r['tier'])))
out=[]
hdr='tribe round n units atk hp spu_mean spu_p90 board_total_mean board_p90 tier_mean | top2: n spu'
print(hdr)
for t in ['Birds','Bog folk','Fairies','Hedgerow folk','Hunters','Oozes','no_tribe','ALL']:
    for R in [4,6,8,10,12,14,16,18]:
        L=agg.get((t,R),[])
        if not L: continue
        spu=[(a+h)/u for u,a,h,pl,ti in L if u>0]
        tot=[a+h for u,a,h,pl,ti in L]
        top=[(a+h)/u for u,a,h,pl,ti in L if u>0 and pl<=2]
        line=f"{t:13s} {R:2d} {len(L):4d} {st.mean(x[0] for x in L):.2f} {st.mean(x[1] for x in L):6.1f} {st.mean(x[2] for x in L):6.1f} {st.mean(spu):5.1f} {q(spu,0.9):5.1f} {st.mean(tot):6.1f} {q(tot,0.9):6.1f} {st.mean(x[4] for x in L):.2f} | {len(top):4d} {st.mean(top) if top else 0:5.1f}"
        print(line)
