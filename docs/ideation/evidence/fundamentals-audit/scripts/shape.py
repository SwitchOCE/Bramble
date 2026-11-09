import json, sys, collections, statistics as st, csv
games = [json.loads(l) for l in open(sys.argv[1])]
opp = collections.defaultdict(list); me = collections.defaultdict(list)
for g in games:
    c = g['combats']
    if not c or c[0]['combat'] != 1 or sum(m[1] + m[2] for m in c[0]['me']) > 15 or abs(len(c) - g['turns']) > 1: continue
    for x in c:
        t = x['combat']
        if (x.get('opp_hero') or {}).get('hp', 1) > 0 and x['opp']: opp[t].append(sum(m[1] + m[2] for m in x['opp']))
        if x['me']: me[t].append(sum(m[1] + m[2] for m in x['me']))
print('BG (Nov 2026). Ordinary boards (opponents): share at >=2x, >=3x, >=10x the ordinary median; perfect-game winners median and p90 as multiples of the ordinary median')
for t in range(4, 16):
    o = opp[t]; m = st.median(o)
    print(f"T{t:<3} med {m:>7.0f}  >=2x {sum(v >= 2*m for v in o)/len(o):5.0%}  >=3x {sum(v >= 3*m for v in o)/len(o):5.0%}  >=10x {sum(v >= 10*m for v in o)/len(o):5.0%}  p90/p50 {sorted(o)[int(.9*len(o))]/m:4.1f}  | winners med x{st.median(me[t])/m:4.1f}  p90 x{sorted(me[t])[int(.9*len(me[t]))]/m:5.1f}  n_opp {len(o)}")
B = sys.argv[2]
players = list(csv.DictReader(open(B + '/free_choice_plain.players.csv')))
seats = collections.Counter(p['seed'] for p in players); seeds = {s for s, n in seats.items() if n == 8}
by = collections.defaultdict(list)
for r in csv.DictReader(open(B + '/free_choice_plain.rounds.csv')):
    if r['seed'] in seeds and r['attack'] != '' and r['health'] != '': by[int(r['round'])].append(int(r['attack']) + int(r['health']))
print('\nBramble bots: same measures')
for t in range(4, 21, 2):
    o = by[t]; m = st.median(o)
    print(f"R{t:<3} med {m:>5.0f}  >=2x {sum(v >= 2*m for v in o)/len(o):5.1%}  >=3x {sum(v >= 3*m for v in o)/len(o):5.1%}  p90/p50 {sorted(o)[int(.9*len(o))]/m:4.2f}  max/med {max(o)/m:4.1f}")
