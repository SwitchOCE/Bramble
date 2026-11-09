import csv, sys, collections, statistics as st
B = sys.argv[1]
players = list(csv.DictReader(open(B + '/free_choice_plain.players.csv')))
seats = collections.Counter(p['seed'] for p in players)
seeds = {s for s, n in seats.items() if n == 8}
rows = [r for r in csv.DictReader(open(B + '/free_choice_plain.rounds.csv')) if r['seed'] in seeds and all(r[k] != '' for k in ('round', 'units', 'attack', 'health'))]
print('complete lobbies', len(seeds), 'round rows', len(rows))
def q(v, p): v = sorted(v); return v[min(len(v) - 1, int(p * len(v)))]
by = collections.defaultdict(list)
for r in rows:
    by[int(r['round'])].append((int(r['attack']) + int(r['health']), int(r['units'])))
print('round   n  tot_p10 tot_p25 tot_p50 tot_mean tot_p75 tot_p90 tot_max  units_p50  per_unit_p50  p90/p10')
for t in sorted(by):
    if t > 20: continue
    v = by[t]; tot = [a for a, _ in v]
    pu = [a / u for a, u in v if u]
    print(f"{t:>5} {len(v):>5} {q(tot,.1):>7} {q(tot,.25):>7} {q(tot,.5):>7} {st.mean(tot):>8.1f} {q(tot,.75):>7} {q(tot,.9):>7} {max(tot):>7} {q([u for _, u in v],.5):>9} {q(pu,.5):>12.1f} {q(tot,.9)/max(1,q(tot,.1)):>8.1f}")
fin = [int(p['final_attack']) + int(p['final_health']) for p in players if p['seed'] in seeds]
print('final board total (death or win): p50', q(fin, .5), 'p90', q(fin, .9), 'max', max(fin))
w = [int(p['final_attack']) + int(p['final_health']) for p in players if p['seed'] in seeds and p['place'] == '1']
print('winners final total: p10', q(w, .1), 'p50', q(w, .5), 'p90', q(w, .9), 'max', max(w), ' winners rounds p50', q([int(p['rounds']) for p in players if p['seed'] in seeds and p['place'] == '1'], .5))
