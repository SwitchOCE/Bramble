"""Recount Q1b (offered/bought/sold), Q2 (final boards) and Q5b (deaths per fight) in plain Python from the raw files; compare with results/*.csv."""
import json, gzip, csv, collections, time
S = '/data/dbtest/sample/'
def load(p): return {r['card']: r for r in csv.DictReader(open('/data/dbtest/duckdb/results/' + p))}
t = time.time()
# Q2
boards = collections.Counter(); placesum = collections.Counter(); copies = collections.Counter(); golden = collections.Counter(); n = 0; sp = 0
for l in open(S + 'games.jsonl'):
    g = json.loads(l)
    for s in g['seats']:
        n += 1; sp += s['place']
        for card in {u['card'] for u in s['final_board']}: boards[card] += 1; placesum[card] += s['place']
        for u in s['final_board']: copies[u['card']] += 1; golden[u['card']] += u['golden']
db = load('q2_final_boards.csv'); bad = 0
for c in boards:
    r = db[c]
    ok = (int(r['boards']) == boards[c] and abs(float(r['place_with']) - placesum[c] / boards[c]) < 1e-3
          and (boards[c] == n or abs(float(r['place_without']) - (sp - placesum[c]) / (n - boards[c])) < 1e-3)
          and int(r['copies']) == copies[c] and abs(float(r['golden_share']) - golden[c] / copies[c]) < 1e-3)
    bad += not ok
print(f'Q2: {len(boards)} cards, DuckDB rows {len(db)}, mismatches {bad}')
# Q1b
off = collections.Counter(); bought = collections.Counter(); sold = collections.Counter()
for l in gzip.open(S + 'shops.jsonl.gz', 'rt'):
    d = json.loads(l); b = {(x['spell'], x['index']) for x in d['bought']}
    for o in d['offers']:
        if not o['spell']: off[o['card']] += 1; bought[o['card']] += (o['spell'], o['index']) in b
for l in gzip.open(S + 'decisions.jsonl.gz', 'rt'):
    d = json.loads(l)
    if d.get('chosen') is not None and d['chosen'] >= 0 and d['legal'][d['chosen']]['type'] == 'sell': sold[d['legal'][d['chosen']].get('card')] += 1
db = load('q1b_card_summary.csv')
bad = sum(not (int(db[c]['offered']) == off[c] and int(db[c]['bought']) == bought[c] and int(db[c]['sold']) == sold[c]) for c in off)
print(f'Q1b: {len(off)} cards, DuckDB rows {len(db)}, mismatches {bad}')
# Q5b
deaths = []
for l in open(S + 'games.jsonl'):
    for r in json.loads(l)['fights']:
        for f in r['fights']: deaths.append(sum(f['result']['deaths']))
row = next(csv.DictReader(open('/data/dbtest/duckdb/results/q5_fights_b.csv')))
print(f"Q5b: python fights {len(deaths)} mean {sum(deaths)/len(deaths):.2f}; duckdb fights {row['fights']} mean {row['deaths_mean']}")
print(f'python check time {time.time()-t:.1f}s')
