-- Q1a: per card, how often bought when offered, by round and by the buyer's main tribe (units only)
SELECT o.card, o.round, s.main_tribe, count(*) AS offered, sum(o.bought::INT) AS bought,
       round(avg(o.bought::INT), 4) AS buy_rate
FROM shop_offers o JOIN seats s USING (game, seat)
WHERE NOT o.spell
GROUP BY ALL ORDER BY card, round, main_tribe;
