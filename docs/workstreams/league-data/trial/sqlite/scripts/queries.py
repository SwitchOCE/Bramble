"""The balance designer's six questions as SQLite queries. Portable SQL (runs on Python's SQLite 3.46, so no median()).
Times each query: median of 3 runs. Writes results to results/qN.tsv."""
import sqlite3, statistics, sys, time, os

DB = '/data/dbtest/sqlite/analysis.db'
OUT = '/data/dbtest/sqlite/results'
os.makedirs(OUT, exist_ok=True)

# percentile helper as a CTE pattern: rank rows within a group, pick by fraction
Q = {}

Q['q1a_buy_rate_by_card_round'] = '''
SELECT o.card, s.round, count(*) AS offered, sum(o.bought) AS bought,
       round(1.0*sum(o.bought)/count(*),4) AS buy_rate, round(avg(o.value),2) AS avg_bot_value
FROM shop_offers o JOIN shops s USING(shop_id)
GROUP BY o.card, s.round ORDER BY o.card, s.round'''

Q['q1b_buy_rate_by_card_tribe'] = '''
SELECT o.card, st.main_tribe AS buyer_tribe, count(*) AS offered, sum(o.bought) AS bought,
       round(1.0*sum(o.bought)/count(*),4) AS buy_rate
FROM shop_offers o JOIN shops s USING(shop_id) JOIN seats st ON st.game=s.game AND st.seat=s.seat
GROUP BY o.card, st.main_tribe ORDER BY o.card, buyer_tribe'''

Q['q1c_card_summary_sold_value'] = '''
WITH off AS (SELECT card, count(*) offered, sum(bought) bought, avg(value) v, avg(CASE WHEN bought=1 THEN value END) v_bought,
                    avg(CASE WHEN bought=0 THEN value END) v_passed FROM shop_offers GROUP BY card),
     sold AS (SELECT card, count(*) sold FROM actions WHERE type='sell' GROUP BY card)
SELECT off.card, offered, bought, round(1.0*bought/offered,4) buy_rate, coalesce(sold,0) sold,
       round(1.0*coalesce(sold,0)/nullif(bought,0),3) sold_per_buy, round(v,2) avg_value, round(v_bought,2) value_when_bought,
       round(v_passed,2) value_when_passed
FROM off LEFT JOIN sold USING(card) ORDER BY offered DESC'''

Q['q2_final_boards'] = '''
WITH fb AS (SELECT DISTINCT game, seat, card FROM board_units WHERE round=0),
     gold AS (SELECT card, count(*) units, sum(golden) golden FROM board_units WHERE round=0 GROUP BY card),
     n AS (SELECT count(*) seats, avg(place) avgp, sum(place) sump FROM seats)
SELECT fb.card, count(*) boards_with, round(1.0*count(*)/n.seats,4) share_of_boards,
       round(avg(s.place),3) place_with,
       round((n.sump - sum(s.place))*1.0/(n.seats - count(*)),3) place_without,
       gold.units, round(1.0*gold.golden/gold.units,3) golden_rate
FROM fb JOIN seats s USING(game,seat) JOIN gold USING(card), n
GROUP BY fb.card ORDER BY boards_with DESC'''

Q['q3a_tribe_place_share'] = '''
WITH t AS (SELECT main_tribe tribe, count(*) seats, round(avg(place),3) avg_place, sum(place=1) wins FROM seats GROUP BY 1),
     u AS (SELECT ct.tribe, count(*) units FROM board_units b JOIN card_tribes ct ON ct.card=b.card WHERE b.round=0 GROUP BY 1),
     tot AS (SELECT count(*) n FROM board_units WHERE round=0)
SELECT coalesce(t.tribe,u.tribe) tribe, t.seats, round(1.0*t.seats/1600,4) share_of_final_boards_by_main_tribe, t.avg_place, t.wins,
       u.units, round(1.0*u.units/tot.n,4) share_of_final_board_units
FROM u LEFT JOIN t ON t.tribe=u.tribe, tot
UNION ALL
SELECT t.tribe, t.seats, round(1.0*t.seats/1600,4), t.avg_place, t.wins, NULL, NULL FROM t WHERE t.tribe NOT IN (SELECT tribe FROM card_tribes)
ORDER BY 2 DESC'''

Q['q3b_tribe_place_by_round_reached'] = '''
SELECT main_tribe tribe, coalesce(died_round, 'won') round_reached, count(*) seats, round(avg(place),3) avg_place
FROM seats GROUP BY 1, 2 ORDER BY 1, coalesce(died_round, 99)'''

Q['q4a_round_board_stats'] = '''
WITH r AS (SELECT round, board_attack a, board_health h,
             cume_dist() OVER (PARTITION BY round ORDER BY board_attack) pa,
             cume_dist() OVER (PARTITION BY round ORDER BY board_health) ph FROM seat_rounds)
SELECT round, count(*) n,
  min(CASE WHEN pa>=0.5 THEN a END) attack_median, min(CASE WHEN pa>=0.25 THEN a END) attack_p25, min(CASE WHEN pa>=0.75 THEN a END) attack_p75,
  round(sqrt(avg(a*a)-avg(a)*avg(a)),1) attack_sd,
  min(CASE WHEN ph>=0.5 THEN h END) health_median, min(CASE WHEN ph>=0.25 THEN h END) health_p25, min(CASE WHEN ph>=0.75 THEN h END) health_p75,
  round(sqrt(avg(h*h)-avg(h)*avg(h)),1) health_sd
FROM r GROUP BY round ORDER BY round'''

Q['q4b_round_tribe_counters'] = '''
WITH r AS (SELECT c.round, st.main_tribe, c.kind, c.name, c.value,
             cume_dist() OVER (PARTITION BY c.round, st.main_tribe, c.kind, c.name ORDER BY c.value) p
           FROM seat_round_counters c JOIN seats st USING(game,seat))
SELECT main_tribe, kind, name, round, count(*) n, min(CASE WHEN p>=0.5 THEN value END) median,
       min(CASE WHEN p>=0.25 THEN value END) p25, min(CASE WHEN p>=0.75 THEN value END) p75, max(value) max
FROM r GROUP BY 1,2,3,4 ORDER BY 1,2,3,4'''

Q['q5a_fight_counts'] = '''
SELECT round, count(*) fights, round(avg(deaths_a+deaths_b),2) deaths_per_fight, round(avg(killed_a+killed_b),2) kills_per_fight,
       round(avg(attacks),2) attacks_per_fight, round(avg(triggers),2) triggers_per_fight, sum(winner IS NULL) draws,
       sum(ghost_of IS NOT NULL) vs_ghost
FROM fights GROUP BY round ORDER BY round'''

Q['q5b_kills_by_source'] = '''
SELECT card, origin, coalesce(source,'') source, count(*) appearances, sum(kills) kills, round(avg(kills),3) kills_per_appearance
FROM fight_kills GROUP BY 1,2,3 ORDER BY kills DESC'''

Q['q5c_mechanic_uses'] = '''
SELECT 'summon' mechanic, source AS by_card, card AS makes, sum(count) uses FROM fight_summons GROUP BY 2,3
UNION ALL
SELECT 'action:'||type, coalesce(card,''), '', count(*) FROM actions WHERE type NOT IN ('buy','refresh','end_turn') GROUP BY 1,2
ORDER BY uses DESC'''

Q['q6_boards_round8'] = '''
SELECT game, round, player, snapshot FROM fight_snapshots WHERE round=8 AND player>=0
ORDER BY (game*7919 + player*104729) % 1009 LIMIT 50'''


def run(db, sql):
    t = time.perf_counter(); rows = db.execute(sql).fetchall(); return time.perf_counter() - t, rows


if __name__ == '__main__':
    db = sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
    for name, sql in Q.items():
        times = []
        for _ in range(3):
            dt, rows = run(db, sql); times.append(dt)
        cols = [d[0] for d in db.execute(sql).description]
        with open(f'{OUT}/{name}.tsv', 'w') as f:
            f.write('\t'.join(cols) + '\n')
            for r in rows:
                f.write('\t'.join('' if v is None else str(v) for v in r) + '\n')
        print(f'{name}\trows={len(rows)}\tmedian_ms={statistics.median(times)*1000:.1f}\truns_ms={[round(x*1000,1) for x in times]}')
