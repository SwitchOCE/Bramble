"""Build the analysis layer from the sample's side files (games, shops, reports, decisions) and the records' fight_boards."""
import sys, os, json, gzip, time
from collections import Counter
from surrealdb import Surreal
port = sys.argv[1]; SKIP_BOARDS = len(sys.argv) > 2 and sys.argv[2] == "noboards"
S = '/data/dbtest/sample'
SCHEMA = """
DEFINE TABLE seat SCHEMALESS COMMENT 'one row per player per game: place, main tribe, rounds reached';
DEFINE TABLE final_unit SCHEMALESS COMMENT 'one row per unit on a final board, with the seat place and main tribe';
DEFINE TABLE seat_round SCHEMALESS COMMENT 'one row per player per round: board stats, tier, tribe counts, tribe counters/heaps; tribe_now = most common tribe on board that round';
DEFINE TABLE offer SCHEMALESS COMMENT 'one row per card offered in one shop view (turn_start/refresh/changed); bought = bought from that view; value = bot value (units only)';
DEFINE TABLE sell SCHEMALESS COMMENT 'one row per sell action (from decisions)';
DEFINE TABLE fight SCHEMALESS COMMENT 'one row per fight: deaths, attacks, triggers, summons, renown';
DEFINE TABLE kill SCHEMALESS COMMENT 'one row per unit per fight side with its kill count; source = card that summoned it';
DEFINE TABLE summon SCHEMALESS COMMENT 'one row per summon source per fight side';
DEFINE TABLE board SCHEMALESS COMMENT 'full engine board state of one player at one fight (from records fight_boards), for refights';
DEFINE INDEX IF NOT EXISTS board_round ON board FIELDS round;
DEFINE INDEX IF NOT EXISTS offer_card ON offer FIELDS card;
"""
def tribe_now(tribes):
    return max(sorted(tribes.items()), key=lambda kv: kv[1])[0] if tribes else None

def main():
    t0 = time.time(); counts = Counter()
    with Surreal(f"ws://127.0.0.1:{port}/rpc") as db:
        db.signin({"username": "root", "password": "root"}); db.use("bramble", "league")
        db.query(SCHEMA).execute()
        buf = {}
        def add(tbl, row):
            buf.setdefault(tbl, []).append(row); counts[tbl] += 1
            if len(buf[tbl]) >= 2000: flush(tbl)
        def flush(tbl):
            if buf.get(tbl):
                db.query(f"INSERT INTO {tbl} $rows RETURN NONE", {"rows": buf[tbl]}).execute(); buf[tbl] = []
        tribe_at = {}; main_of = {}
        for line in open(f'{S}/games.jsonl'):
            g = json.loads(line); gid = g['game']
            add('game', {'game': gid, 'seed': g['seed'], 'rounds': g['rounds'], 'swapped': g['swapped'], 'round_limit_hit': g['round_limit_hit']})
            for s in g['seats']:
                main_of[(gid, s['seat'])] = s['main_tribe']
                add('seat', {'game': gid, 'seat': s['seat'], 'colour': s['colour'], 'bot': s['bot'], 'place': s['place'],
                             'main_tribe': s['main_tribe'], 'commit_round': s['commit_round'], 'died_round': s.get('died_round'),
                             'rounds_reached': max(r['round'] for r in s['rounds']),
                             'final_cards': sorted({u['card'] for u in s['final_board']})})
                for u in s['final_board']:
                    add('final_unit', {'game': gid, 'seat': s['seat'], 'place': s['place'], 'main_tribe': s['main_tribe'], **u})
                for r in s['rounds']:
                    tn = tribe_now(r['tribes']); tribe_at[(gid, s['seat'], r['round'])] = tn
                    add('seat_round', {'game': gid, 'seat': s['seat'], 'round': r['round'], 'main_tribe': s['main_tribe'], 'tribe_now': tn,
                                       'board_attack': r['board_attack'], 'board_health': r['board_health'], 'tier': r['tier'],
                                       'n_units': len(r['board']), 'tribes': r['tribes'], 'counters': r['counters'], 'heaps': r['heaps'],
                                       'triple': r['triple'], 'golden_gained': r['golden_gained'], 'gold_left': r['gold_left']})
            for fr in g['fights']:
                for i, f in enumerate(fr['fights']):
                    res = f['result']
                    add('fight', {'game': gid, 'round': fr['round'], 'i': i, 'a': f['a'], 'b': f['b'], 'winner': f['winner'], 'damage': f['damage'],
                                  'deaths': sum(res['deaths']), 'deaths_by_side': res['deaths'], 'attacks': res['attacks'], 'triggers': res['triggers'],
                                  'reason': res['reason'], 'ghost': f['ghost_of'] is not None,
                                  'summons': sum(x['count'] for side in f['summons'] for x in side), 'renown': len(f['renown'])})
                    for side, units in enumerate(f['kills']):
                        for u in units:
                            add('kill', {'game': gid, 'round': fr['round'], 'i': i, 'side': side, **u})
                    for side, ss in enumerate(f['summons']):
                        for x in ss:
                            add('summon', {'game': gid, 'round': fr['round'], 'i': i, 'side': side, **x})
        print('games done', time.time() - t0, flush=True)
        reports = (json.loads(l) for l in open(f'{S}/reports.jsonl'))
        reports = (r for r in reports if r['kind'] == 'shop')
        with gzip.open(f'{S}/shops.jsonl.gz', 'rt') as fh:
            for line, rep in zip(fh, reports):
                sh = json.loads(line); k = (sh['game'], sh['seat'], sh['round'])
                assert k == (rep['game'], rep['seat'], rep['round'])
                vals = iter(v for _, v in rep['values'])
                bought = Counter((b['spell'], b['index']) for b in sh['bought'])
                for o in sh['offers']:
                    add('offer', {'game': k[0], 'seat': k[1], 'round': k[2], 'reason': sh['reason'], 'card': o['card'], 'spell': o['spell'],
                                  'buyable': o['buyable'], 'bought': bought[(o['spell'], o['index'])] > 0,
                                  'value': None if o['spell'] else next(vals), 'strategy': rep['strategy'],
                                  'tribe_now': tribe_at.get(k), 'main_tribe': main_of[k[:2]]})
        print('shops done', time.time() - t0, flush=True)
        with gzip.open(f'{S}/decisions.jsonl.gz', 'rt') as fh:
            for line in fh:
                if '"type":"sell"' not in line: continue
                d = json.loads(line); a = d['legal'][d['chosen']]
                if a['type'] != 'sell': continue
                k = (d['game'], d['seat'], d['round'])
                add('sell', {'game': k[0], 'seat': k[1], 'round': k[2], 'card': a['card'], 'tribe_now': tribe_at.get(k), 'main_tribe': main_of[k[:2]]})
        print('sells done', time.time() - t0, flush=True)
        for name in sorted(os.listdir(f'{S}/records')):
            gid = int(name[5:10])
            for line in open(f'{S}/records/{name}'):
                if SKIP_BOARDS or '"op":"fight_boards"' not in line: continue
                fb = json.loads(line)
                for p in fb['players']:
                    add('board', {'game': gid, 'round': fb['turn'], 'player': p['id'], 'place': None, 'state': p})
            for tbl in list(buf): flush(tbl)
        for tbl in list(buf): flush(tbl)
        print('boards done', time.time() - t0, flush=True)
    print(dict(counts)); print('load_s', round(time.time() - t0, 1))
main()
