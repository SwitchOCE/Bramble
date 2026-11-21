"""Plain-Python counts over the raw sample files, to check the database answers."""
import json, gzip, time
from collections import Counter, defaultdict
S = '/data/dbtest/sample'
out = {}
t0 = time.time()
# Q2: per card on final boards: seats with it, avg place with/without, golden share of copies
seats = []; units = Counter(); gold = Counter()
for l in open(f'{S}/games.jsonl'):
    g = json.loads(l)
    for s in g['seats']:
        cards = {u['card'] for u in s['final_board']}
        seats.append((s['place'], cards))
        for u in s['final_board']:
            units[u['card']] += 1; gold[u['card']] += u['golden']
q2 = {}
for c in units:
    w = [p for p, cs in seats if c in cs]; wo = [p for p, cs in seats if c not in cs]
    q2[c] = {'seats_with': len(w), 'avg_with': round(sum(w)/len(w), 4), 'avg_without': round(sum(wo)/len(wo), 4), 'golden_rate': round(gold[c]/units[c], 4)}
out['q2'] = q2
# Q1: per card offered/bought (unit offers, all shop views), and per round for sentry
off = Counter(); bou = Counter(); byr = defaultdict(lambda: [0, 0])
with gzip.open(f'{S}/shops.jsonl.gz', 'rt') as f:
    for l in f:
        s = json.loads(l); b = {(x['spell'], x['index']) for x in s['bought']}
        for o in s['offers']:
            hit = (o['spell'], o['index']) in b
            off[o['card']] += 1; bou[o['card']] += hit
            if o['card'] == 'sentry': byr[s['round']][0] += 1; byr[s['round']][1] += hit
out['q1'] = {c: {'offered': off[c], 'bought': bou[c], 'rate': round(bou[c]/off[c], 4)} for c in off}
out['q1_sentry_by_round'] = {r: v for r, v in sorted(byr.items())}
# Q5: deaths per fight, kills by source
deaths = []; ks = Counter()
for l in open(f'{S}/games.jsonl'):
    g = json.loads(l)
    for fr in g['fights']:
        for f in fr['fights']:
            deaths.append(sum(f['result']['deaths']))
            for side in f['kills']:
                for u in side: ks[u['card'] if u['origin'] == 'start' else 'summoned:' + u['card']] += u['kills']
out['q5'] = {'fights': len(deaths), 'mean_deaths': round(sum(deaths)/len(deaths), 4), 'top_kills': ks.most_common(5)}
print(json.dumps({'q2_sample': {c: q2[c] for c in ['sentry', 'husk-sentry', 'gleaner']}, 'q1_sample': {c: out['q1'][c] for c in ['sentry', 'husk-sentry']},
                  'q1_sentry_by_round': out['q1_sentry_by_round'], 'q5': out['q5']}, indent=1))
json.dump(out, open('/data/dbtest/surrealdb/results/python_check.json', 'w'), indent=1)
print('python_s', round(time.time() - t0, 2))
