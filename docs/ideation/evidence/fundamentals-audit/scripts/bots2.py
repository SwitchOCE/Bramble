import csv, collections, statistics as st, json, glob
D='/home/alex/code/Bramble-ideation-balance/build/sim/pass2-followup/lobbies/'
players=list(csv.DictReader(open(D+'free_choice_plain.players.csv')))
tribe={(p['seed'],p['seat']):p['final_tribe'] for p in players}
cards=list(csv.DictReader(open(D+'free_choice_plain.cards.csv')))
defs={}
for f in glob.glob('/home/alex/code/Bramble-ideation-balance/content/units/*.json'):
    d=json.load(open(f)); defs[d['id']]=d
cnt=collections.Counter(); places=collections.defaultdict(list); gold=collections.Counter(); boards=collections.defaultdict(set)
win=collections.Counter(); top4=collections.Counter()
for c in cards:
    k=(c['seed'],c['seat'])
    cnt[c['card']]+=1; places[c['card']].append(int(c['place'])); gold[c['card']]+=int(c['golden'])
    boards[c['card']].add(k)
    if c['place']=='1': win[c['card']]+=1
nseats=len(players)
for t in ['Birds','Bog folk','Fairies','Hedgerow folk']:
    print('=====',t)
    ids=[i for i,d in defs.items() if d.get('set')=='slice' and t in d.get('tribes',[])]
    ids.sort(key=lambda i:(defs[i]['tier'],i))
    for i in ids:
        n=cnt[i]
        if n==0: print(f"  {i:22s} T{defs[i]['tier']} copies=0"); continue
        bs=boards[i]
        intr=sum(1 for b in bs if tribe.get(b)==t)
        print(f"  {i:22s} T{defs[i]['tier']} copies={n:4d} boards={len(bs):4d} ({len(bs)/nseats*100:4.1f}% of seats) on-{t[:4]}-boards={intr:4d} meanplace={st.mean(places[i]):.2f} golden={gold[i]:3d} in-1st={win[i]:3d}")
