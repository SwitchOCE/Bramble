-- Q4a: per round, board attack and health: median, quartiles, stddev
SELECT round, count(*) AS boards,
       median(board_attack) AS atk_median, quantile_cont(board_attack, 0.25) AS atk_p25, quantile_cont(board_attack, 0.75) AS atk_p75, round(stddev(board_attack), 1) AS atk_sd,
       median(board_health) AS hp_median, quantile_cont(board_health, 0.25) AS hp_p25, quantile_cont(board_health, 0.75) AS hp_p75, round(stddev(board_health), 1) AS hp_sd
FROM seat_rounds GROUP BY round ORDER BY round;
-- Q4b: per round, each tribe resource counter (counters and heaps): median and quartiles
SELECT round, kind, name, count(*) AS seats, median(value) AS med, quantile_cont(value, 0.25) AS p25, quantile_cont(value, 0.75) AS p75, max(value) AS max
FROM round_counters WHERE kind <> 'tribe' GROUP BY ALL ORDER BY name, round;
