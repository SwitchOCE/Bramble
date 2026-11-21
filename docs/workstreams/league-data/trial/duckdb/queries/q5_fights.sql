-- Q5a: kills by source card (units present at start vs summoned, with summoner)
SELECT card, origin, source, sum(kills) AS kills, count(*) AS appearances FROM fight_kills GROUP BY ALL ORDER BY kills DESC;
-- Q5b: deaths per fight: distribution
SELECT count(*) AS fights, round(avg(deaths_a + deaths_b), 2) AS deaths_mean, median(deaths_a + deaths_b) AS deaths_median,
       quantile_cont(deaths_a + deaths_b, 0.9) AS deaths_p90, round(avg(triggers), 2) AS triggers_mean, round(avg(attacks), 2) AS attacks_mean,
       sum((ghost_of IS NOT NULL)::INT) AS ghost_fights
FROM fights;
-- Q5c: mechanic uses: summons by source in fights, and shop-phase abilities by mechanic
SELECT 'fight summon' AS what, source AS name, sum(n) AS uses FROM fight_summons GROUP BY ALL
UNION ALL SELECT 'shop ability', coalesce(mechanic, card), count(*) FROM actions WHERE action = 'ability' GROUP BY ALL
ORDER BY what, uses DESC;
