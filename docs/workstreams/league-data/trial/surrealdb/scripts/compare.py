import json
r = json.load(open('/data/dbtest/surrealdb/results/query_results.json'))
p = json.load(open('/data/dbtest/surrealdb/results/python_check.json'))
def close(a, b): return abs(a - b) < 1e-6
# Q2
rows = r['Q2'][-1]; bad = 0
for x in rows:
    e = p['q2'][x['card']]
    if not (x['seats_with'] == e['seats_with'] and close(x['avg_place_with'], e['avg_with']) is not None and abs(x['avg_place_with'] - e['avg_with']) < 1e-3
            and abs(x['avg_place_without'] - e['avg_without']) < 1e-3 and abs(x['golden_rate'] - e['golden_rate']) < 1e-3): bad += 1; print('Q2 diff', x, e)
print(f"Q2: {len(rows)} cards from DB, {len(p['q2'])} in Python, {bad} differ")
# Q1 overall (units only in DB; python counted all offers incl. spells)
rows = r['Q1'][0]; bad = 0
for x in rows:
    e = p['q1'][x['card']]
    if (x['offered'], x['bought']) != (e['offered'], e['bought']): bad += 1; print('Q1 diff', x, e)
print(f"Q1 per-card offered/bought: {len(rows)} unit cards from DB, {bad} differ")
by = {x['round']: [x['offered'], x['bought']] for x in r['Q1'][1] if x['card'] == 'sentry'}
print('Q1 sentry by round equal:', by == {int(k): v for k, v in p['q1_sentry_by_round'].items()})
# Q5
f = r['Q5'][0][0]; print('Q5 fights', f['fights'], p['q5']['fights'], 'mean deaths', round(f['deaths_mean'], 4), p['q5']['mean_deaths'])
top = sorted(((x['card'] if x['origin'] == 'start' else 'summoned:' + x['card'], x['kills']) for x in r['Q5'][1]), key=lambda t: -t[1])
from collections import Counter
agg = Counter()
for k, v in top: agg[k] += v
print('Q5 top kills DB', agg.most_common(5)); print('Q5 top kills Py', p['q5']['top_kills'])
