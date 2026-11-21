-- @Q1 Per card from shops: offered, bought, buy rate, bot value; by round; by buyer's tribe; sold
LET $by_card = SELECT card, count() AS offered, count(bought) AS bought, math::mean(value) AS bot_value_mean FROM offer WHERE spell = false GROUP BY card;
LET $sold = SELECT card, count() AS sold FROM sell GROUP BY card;
SELECT card, offered, bought, <float> bought / offered AS buy_rate, bot_value_mean, ($sold[WHERE card = $parent.card][0].sold ?? 0) AS sold FROM $by_card ORDER BY offered DESC;
SELECT card, round, offered, bought, <float> bought / offered AS buy_rate FROM (SELECT card, round, count() AS offered, count(bought) AS bought FROM offer WHERE spell = false GROUP BY card, round) ORDER BY card, round;
SELECT card, tribe_now, offered, bought, <float> bought / offered AS buy_rate FROM (SELECT card, tribe_now, count() AS offered, count(bought) AS bought FROM offer WHERE spell = false GROUP BY card, tribe_now) ORDER BY card, tribe_now;
-- @Q2 Per card from final boards: share of boards, avg place with vs without, golden rate
LET $n = (SELECT count() AS c FROM seat GROUP ALL)[0].c;
LET $sp = (SELECT math::sum(place) AS s FROM seat GROUP ALL)[0].s;
LET $gold = SELECT card, count() AS units, count(golden) AS golden FROM final_unit GROUP BY card;
SELECT card, seats_with, <float> seats_with / $n AS share_of_boards, <float> sum_with / seats_with AS avg_place_with,
       <float> ($sp - sum_with) / ($n - seats_with) AS avg_place_without,
       <float> $gold[WHERE card = $parent.card][0].golden / $gold[WHERE card = $parent.card][0].units AS golden_rate
FROM (SELECT card, count() AS seats_with, math::sum(place) AS sum_with
      FROM (SELECT card, game, seat, place FROM final_unit GROUP BY card, game, seat, place) GROUP BY card)
ORDER BY seats_with DESC;
-- @Q3 Per tribe: avg place, share of final boards (by main tribe, and by unit tribe), place by round reached
LET $n = (SELECT count() AS c FROM seat GROUP ALL)[0].c;
LET $u = (SELECT count() AS c FROM final_unit GROUP ALL)[0].c;
SELECT main_tribe, seats, avg_place, <float> seats / $n AS share_of_final_boards FROM (SELECT main_tribe, count() AS seats, math::mean(place) AS avg_place FROM seat GROUP BY main_tribe) ORDER BY seats DESC;
SELECT tribe, units, <float> units / $u AS share_of_final_units FROM (SELECT tribe, count() AS units FROM (SELECT type::record('card', card).tribes[0] ?? 'Neutral' AS tribe FROM final_unit) GROUP BY tribe) ORDER BY units DESC;
SELECT main_tribe, rounds_reached, count() AS seats, math::mean(place) AS avg_place FROM seat GROUP BY main_tribe, rounds_reached ORDER BY main_tribe, rounds_reached;
-- @Q4 Per round: median and spread of board attack/health, and tribe counters/heaps
SELECT round, n, math::median(atk) AS atk_median, math::percentile(atk, 25) AS atk_p25, math::percentile(atk, 75) AS atk_p75, math::stddev(atk) AS atk_sd,
       math::median(hp) AS hp_median, math::percentile(hp, 25) AS hp_p25, math::percentile(hp, 75) AS hp_p75, math::stddev(hp) AS hp_sd
FROM (SELECT round, count() AS n, board_attack AS atk, board_health AS hp FROM seat_round GROUP BY round) ORDER BY round;
SELECT round, n, math::median(v) AS median, math::percentile(v, 25) AS p25, math::percentile(v, 75) AS p75, math::max(v) AS max FROM (SELECT round, count() AS n, counters.locust_tide AS v FROM seat_round WHERE counters.locust_tide != NONE GROUP BY round) ORDER BY round;
SELECT round, n, math::median(v) AS median, math::percentile(v, 25) AS p25, math::percentile(v, 75) AS p75, math::max(v) AS max FROM (SELECT round, count() AS n, counters.locust_hopper_bonus AS v FROM seat_round WHERE counters.locust_hopper_bonus != NONE GROUP BY round) ORDER BY round;
SELECT round, n, math::median(v) AS median, math::percentile(v, 25) AS p25, math::percentile(v, 75) AS p75, math::max(v) AS max FROM (SELECT round, count() AS n, heaps.thorn_compost AS v FROM seat_round WHERE heaps.thorn_compost != NONE GROUP BY round) ORDER BY round;
-- @Q5 Per fight, counts: deaths per fight, kills by source, mechanic uses
SELECT count() AS fights, math::mean(deaths) AS deaths_mean, math::median(deaths) AS deaths_median, math::max(deaths) AS deaths_max, math::sum(summons) AS summons, math::sum(renown) AS renown_events, math::sum(triggers) AS triggers, math::mean(triggers) AS triggers_mean, math::mean(attacks) AS attacks_mean, count(ghost) AS ghost_fights FROM fight GROUP ALL;
SELECT origin, card, source, math::sum(kills) AS kills, count() AS unit_fights FROM kill GROUP BY origin, card, source ORDER BY kills DESC;
SELECT source, card, math::sum(count) AS summoned FROM summon GROUP BY source, card ORDER BY summoned DESC;
-- @Q6 Boards to refight: 50 full board snapshots at round 8
SELECT game, player, round, state FROM board WHERE round = 8 ORDER BY game, player LIMIT 50;
