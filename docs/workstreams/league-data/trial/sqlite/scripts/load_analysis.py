"""Load the analysis layer from /data/dbtest/sample into analysis.db (SQLite)."""
import gzip, json, sqlite3, sys, time, os

S = '/data/dbtest/sample'
OUT = sys.argv[1] if len(sys.argv) > 1 else '/data/dbtest/sqlite/analysis.db'
if os.path.exists(OUT):
    os.remove(OUT)
db = sqlite3.connect(OUT)
db.execute('PRAGMA journal_mode=OFF'); db.execute('PRAGMA synchronous=OFF')
db.executescript(open('/data/dbtest/sqlite/scripts/schema.sql').read())
t0 = time.time()
B = lambda x: None if x is None else int(bool(x))

lib = json.load(open(f'{S}/library.json'))
db.executemany('INSERT INTO cards VALUES(?,?,?,?,?,?,?)',
               [(c['id'], c['name'], c['tier'], c['attack'], c['health'], B(c['spell']), B(c['token'])) for c in lib])
db.executemany('INSERT INTO card_tribes VALUES(?,?)', [(c['id'], t) for c in lib for t in c['tribes']])

cpu = {}
for l in open(f'{S}/cpu.jsonl'):
    d = json.loads(l)
    for s in d['seats']:
        cpu[(d['game'], s['seat'])] = s['cpu_ms']

def jtxt(x):
    return None if x is None else (x if isinstance(x, str) else json.dumps(x))

for l in open(f'{S}/games.jsonl'):
    g = json.loads(l); gid = g['game']
    db.execute('INSERT INTO games VALUES(?,?,?,?,?)', (gid, g['seed'], B(g['swapped']), g['rounds'], B(g['round_limit_hit'])))
    for s in g['seats']:
        st = s['seat']
        db.execute('INSERT INTO seats VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
                   (gid, st, s['colour'], s['bot'], s['place'], s['main_tribe'], s['commit_round'], s.get('died_round'),
                    s['refused'], jtxt(s['fault']), jtxt(s['panic']), jtxt(s['clock_out']), cpu.get((gid, st))))
        for u in s['final_board']:
            db.execute('INSERT INTO board_units VALUES(?,?,?,?,?,?,?,?)', (gid, st, 0, u['slot'], u['card'], B(u['golden']), u['attack'], u['health']))
        for r in s['rounds']:
            rd = r['round']; tr = r['tribes']
            lead = max(tr.items(), key=lambda kv: (kv[1], kv[0]))[0] if tr else None
            db.execute('INSERT INTO seat_rounds VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                       (gid, st, rd, r['tier'], r['board_attack'], r['board_health'], len(r['board']), r['gold_start'], r['gold_left'],
                        r['gold_from_cards'], B(r['triple']), B(r['golden_gained']), B(r['slot_buff']), lead))
            db.executemany('INSERT INTO seat_round_tribes VALUES(?,?,?,?,?)', [(gid, st, rd, k, v) for k, v in tr.items()])
            db.executemany('INSERT INTO seat_round_counters VALUES(?,?,?,?,?,?)',
                           [(gid, st, rd, 'counter', k, v) for k, v in r['counters'].items()] +
                           [(gid, st, rd, 'heap', k, v) for k, v in r['heaps'].items()])
            db.executemany('INSERT INTO board_units VALUES(?,?,?,?,?,?,?,?)',
                           [(gid, st, rd, u['slot'], u['card'], B(u['golden']), u['attack'], u['health']) for u in r['board']])
    for fr in g['fights']:
        rd = fr['round']
        for i, f in enumerate(fr['fights']):
            res = f['result']
            db.execute('INSERT INTO fights VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                       (gid, rd, i, f['a'], f['b'], f['winner'], f['loser'], f['damage'], res['attacks'], res['triggers'], res['reason'],
                        res['deaths'][0], res['deaths'][1], res['killed'][0], res['killed'][1], res['starting'][0], res['starting'][1],
                        jtxt(f['ghost_of'])))
            for side in (0, 1):
                db.executemany('INSERT INTO fight_kills VALUES(?,?,?,?,?,?,?,?,?,?,?)',
                               [(gid, rd, i, side, n, k['card'], B(k['golden']), k.get('slot'), k['origin'], k['source'], k['kills'])
                                for n, k in enumerate(f['kills'][side])])
                db.executemany('INSERT INTO fight_summons VALUES(?,?,?,?,?,?,?,?)',
                               [(gid, rd, i, side, n, k['source'], k['card'], k['count']) for n, k in enumerate(f['summons'][side])])
print('games', round(time.time() - t0, 1), flush=True)

# shops + reports(kind=shop) are written in the same order, one report per shop view
reps = (json.loads(l) for l in open(f'{S}/reports.jsonl'))
reps = (r for r in reps if r['kind'] == 'shop')
shop_rows = []; misalign = 0; value_miss = 0
for sid, l in enumerate(gzip.open(f'{S}/shops.jsonl.gz', 'rt')):
    d = json.loads(l); r = next(reps)
    if (d['game'], d['seat'], d['round'], [o['card'] for o in d['offers']]) != (r['game'], r['seat'], r['round'], r['offered']):
        misalign += 1; r = None
    db.execute('INSERT INTO shops VALUES(?,?,?,?,?,?,?,?)', (sid, d['game'], d['seat'], d['round'], d['reason'], d['gold'], d['tier'], r['strategy'] if r else None))
    bought = {(b['spell'], b['index']) for b in d['bought']}
    units = [o for o in d['offers'] if not o['spell']]
    vals = r['values'] if r else []
    vmap = {}
    if len(vals) == len(units) and all(v[0] == o['card'] for v, o in zip(vals, units)):
        vmap = {o['index']: v[1] for v, o in zip(vals, units)}
    elif units:
        value_miss += 1
    for o in d['offers']:
        shop_rows.append((sid, B(o['spell']), o['index'], o['card'], B(o['buyable']), int((o['spell'], o['index']) in bought),
                          None if o['spell'] else vmap.get(o['index'])))
    if len(shop_rows) > 200000:
        db.executemany('INSERT INTO shop_offers VALUES(?,?,?,?,?,?,?)', shop_rows); shop_rows = []
db.executemany('INSERT INTO shop_offers VALUES(?,?,?,?,?,?,?)', shop_rows)
print('shops', round(time.time() - t0, 1), 'misaligned', misalign, 'shops with unit values not matching offers', value_miss, flush=True)

disc_n = {}
rows = []
for l in open(f'{S}/discovers.jsonl'):
    d = json.loads(l); k = (d['game'], d['seat'], d['round']); n = disc_n.get(k, 0); disc_n[k] = n + 1
    rows.append((*k, n, json.dumps(d['options']), d['pick'], d['card']))
db.executemany('INSERT INTO discovers VALUES(?,?,?,?,?,?,?)', rows)

rows = []
for l in gzip.open(f'{S}/decisions.jsonl.gz', 'rt'):
    d = json.loads(l); a = d['legal'][d['chosen']]
    rows.append((d['game'], d['seat'], d['round'], d['step'], a['type'], a.get('card'), d['gold'], d['tier'], d['board_n'], d['hand_n']))
    if len(rows) > 200000:
        db.executemany('INSERT INTO actions VALUES(?,?,?,?,?,?,?,?,?,?)', rows); rows = []
db.executemany('INSERT INTO actions VALUES(?,?,?,?,?,?,?,?,?,?)', rows)
print('decisions', round(time.time() - t0, 1), flush=True)

for gid in range(200):
    rows = []
    for l in open(f'{S}/records/game-{gid:05d}.jsonl'):
        if '"op":"fight_boards"' not in l:
            continue
        d = json.loads(l)
        rows += [(gid, d['turn'], p['id'], json.dumps(p, separators=(',', ':'))) for p in d['players']]
    db.executemany('INSERT INTO fight_snapshots(game,round,player,snapshot) VALUES(?,?,?,?)', rows)
print('snapshots', round(time.time() - t0, 1), flush=True)

db.executescript('''
CREATE INDEX shop_offers_card ON shop_offers(card);
CREATE INDEX shops_game ON shops(game, seat, round);
CREATE INDEX board_units_card ON board_units(card);
CREATE INDEX board_units_round ON board_units(round);
CREATE INDEX seat_rounds_round ON seat_rounds(round);
''')
db.commit()
db.execute('ANALYZE'); db.commit()
db.execute('VACUUM'); db.close()
print('done', round(time.time() - t0, 1), 'bytes', os.path.getsize(OUT))
