"""Build the analysis layer: analysis.duckdb, from the sample's JSON-lines files. 2 threads."""
import duckdb, os, sys, time
S = '/data/dbtest/sample'
DB = sys.argv[1] if len(sys.argv) > 1 else '/data/dbtest/duckdb/analysis.duckdb'
if os.path.exists(DB): os.remove(DB)
STORAGE = sys.argv[2] if len(sys.argv) > 2 else None
c = duckdb.connect(config={'threads': 2, 'preserve_insertion_order': False})
c.execute(f"ATTACH '{DB}' AS a" + (f" (STORAGE_VERSION '{STORAGE}')" if STORAGE else '')); c.execute('USE a')
t0 = time.time()
def run(name, sql):
    t = time.time(); c.execute(sql); print(f'{name}: {time.time()-t:.2f}s', flush=True)

run('raw_games', f"""CREATE TEMP TABLE raw_games AS SELECT * FROM read_json('{S}/games.jsonl', maximum_object_size=200000000)""")
run('games', """CREATE TABLE games AS SELECT game::INT game, seed, swapped, rounds::INT rounds, round_limit_hit, red_seats::INT[] red_seats FROM raw_games""")
run('raw_seats', """CREATE TEMP TABLE raw_seats AS SELECT game, unnest(seats) s FROM raw_games""")
run('seats', """CREATE TABLE seats AS SELECT game::INT game, s.seat::INT seat, s.colour, s.bot, s.place::INT place,
      s.main_tribe, s.commit_round::INT commit_round, s.died_round::INT died_round, s.refused::INT refused,
      to_json(s.pivots) pivots, (s.clock_out IS NOT NULL AND s.clock_out::VARCHAR<>'null') clock_out
    FROM raw_seats""")
run('final_board', """CREATE TABLE final_board AS SELECT game::INT game, s.seat::INT seat, b.slot::INT slot, b.card, b.golden, b.attack::INT attack, b.health::INT health
    FROM (SELECT game, s, unnest(s.final_board) b FROM raw_seats)""")
run('raw_rounds', """CREATE TEMP TABLE raw_rounds AS SELECT game, s.seat seat, unnest(s.rounds) r FROM raw_seats""")
# tribes / heaps / counters are objects with open-ended keys; keep them as JSON so a new tribe does not change the schema
run('seat_rounds', """CREATE TABLE seat_rounds AS SELECT game::INT game, seat::INT seat, r.round::INT round, r.tier::INT tier,
      r.board_attack::INT board_attack, r.board_health::INT board_health, r.gold_start::INT gold_start, r.gold_left::INT gold_left,
      r.gold_from_cards::INT gold_from_cards, r.triple, r.golden_gained, r.slot_buff, len(r.board)::INT board_n, len(r.hand)::INT hand_n,
      to_json(r.tribes) tribes, to_json(r.heaps) heaps, to_json(r.counters) counters
    FROM raw_rounds""")
run('round_board', """CREATE TABLE round_board AS SELECT game::INT game, seat::INT seat, r.round::INT round, b.slot::INT slot, b.card, b.golden, b.attack::INT attack, b.health::INT health
    FROM (SELECT game, seat, r, unnest(r.board) b FROM raw_rounds)""")
# long form of the counters: one row per (seat, round, kind, name)
run('round_counters', """CREATE TABLE round_counters AS SELECT * FROM (
    SELECT game, seat, round, 'tribe' AS kind, k AS name, (tribes->>k)::INT AS value FROM (SELECT *, unnest(json_keys(tribes)) k FROM seat_rounds)
    UNION ALL SELECT game, seat, round, 'heap', k, (heaps->>k)::INT FROM (SELECT *, unnest(json_keys(heaps)) k FROM seat_rounds)
    UNION ALL SELECT game, seat, round, 'counter', k, (counters->>k)::INT FROM (SELECT *, unnest(json_keys(counters)) k FROM seat_rounds)) WHERE value IS NOT NULL""")
run('raw_fights', """CREATE TEMP TABLE raw_fights AS SELECT game, fr.round round, unnest(fr.fights) f, generate_subscripts(fr.fights,1) fight_no
    FROM (SELECT game, unnest(fights) fr FROM raw_games)""")
run('fights', """CREATE TABLE fights AS SELECT game::INT game, round::INT round, fight_no::INT fight_no, f.a::INT a, f.b::INT b,
      f.winner::INT winner, f.loser::INT loser, f.damage::INT damage, f.result.attacks::INT attacks,
      f.result.deaths[1]::INT deaths_a, f.result.deaths[2]::INT deaths_b, f.result.killed[1]::INT killed_a, f.result.killed[2]::INT killed_b,
      f.result.starting[1]::INT starting_a, f.result.starting[2]::INT starting_b, f.result.triggers::INT triggers, f.result.reason reason,
      f.ghost_of::INT ghost_of, to_json(f.renown) renown
    FROM raw_fights""")
run('fight_kills', """CREATE TABLE fight_kills AS SELECT game::INT game, round::INT round, fight_no::INT fight_no, side::INT side,
      k.card, k.golden, k.origin, k.source, k.kills::INT kills
    FROM (SELECT game, round, fight_no, side, unnest(lst) k FROM
          (SELECT game, round, fight_no, unnest(f.kills) lst, generate_subscripts(f.kills,1)-1 side FROM raw_fights))""")
run('fight_summons', """CREATE TABLE fight_summons AS SELECT game::INT game, round::INT round, fight_no::INT fight_no, side::INT side,
      k.source, k.card, k.count::INT n
    FROM (SELECT game, round, fight_no, side, unnest(lst) k FROM
          (SELECT game, round, fight_no, unnest(f.summons) lst, generate_subscripts(f.summons,1)-1 side FROM raw_fights))""")
run('raw_shops', f"""CREATE TEMP TABLE raw_shops AS SELECT row_number() OVER () view_id, * FROM read_json('{S}/shops.jsonl.gz')""")
run('shop_offers', """CREATE TABLE shop_offers AS
    SELECT view_id::INT view_id, game::INT game, seat::INT seat, round::INT round, reason, gold::INT gold, tier::INT tier,
      o.card, o.spell, o."index"::INT idx, o.buyable,
      list_contains(list_transform(list_filter(bought, x -> x.spell = o.spell), x -> x."index"), o."index") bought
    FROM (SELECT *, unnest(offers) o FROM raw_shops)""")
run('raw_reports', f"""CREATE TEMP TABLE raw_reports AS SELECT * FROM read_json('{S}/reports.jsonl')""")
run('bot_values', """CREATE TABLE bot_values AS SELECT game::INT game, seat::INT seat, round::INT round, kind, strategy,
      json_extract_string(v[1], '$') AS card, (v[2]::VARCHAR)::DOUBLE AS value FROM (SELECT *, unnest("values") v FROM raw_reports)""")
run('actions', f"""CREATE TABLE actions AS SELECT game::INT game, seat::INT seat, round::INT round, step::INT step, "by",
      a."type" AS action, a.card, a.mechanic, a.spell, result
    FROM (SELECT *, legal[chosen+1] a FROM read_json('{S}/decisions.jsonl.gz') WHERE chosen IS NOT NULL AND chosen >= 0)""")
run('discovers', f"""CREATE TABLE discovers AS SELECT game::INT game, seat::INT seat, round::INT round, options, pick::INT pick, card FROM read_json('{S}/discovers.jsonl')""")
run('cards', f"""CREATE TABLE cards AS SELECT * FROM read_json('{S}/library.json')""")
# refight snapshots are not copied here: they are the fight_boards lines of the archive (see load_archive.py)
c.execute('CHECKPOINT')
for (t,) in c.sql("SELECT table_name FROM duckdb_tables() WHERE NOT temporary ORDER BY 1").fetchall():
    print(t, c.sql(f'SELECT count(*) FROM {t}').fetchone()[0])
c.close()
print(f'total {time.time()-t0:.1f}s, file {os.path.getsize(DB)/1e6:.2f} MB')
