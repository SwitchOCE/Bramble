-- Q3a: per main tribe: seats, avg place, share of seats, share of final-board units belonging to the tribe
WITH units AS (SELECT t.tribe, count(*) AS n FROM final_board f JOIN (SELECT id, unnest(tribes) AS tribe FROM cards) t ON t.id = f.card GROUP BY tribe),
     allu AS (SELECT count(*) AS n FROM final_board)
SELECT s.main_tribe, count(*) AS seats, round(avg(place), 3) AS avg_place, round(count(*) / 1600.0, 3) AS seat_share,
       round(any_value(u.n) / any_value(allu.n), 3) AS final_unit_share
FROM seats s LEFT JOIN units u ON u.tribe = s.main_tribe CROSS JOIN allu
GROUP BY s.main_tribe ORDER BY avg_place;
-- Q3b: place by round reached (last round played) per main tribe
SELECT s.main_tribe, coalesce(s.died_round, g.rounds) AS round_reached, count(*) AS seats, round(avg(place), 2) AS avg_place
FROM seats s JOIN games g USING (game) GROUP BY ALL ORDER BY main_tribe, round_reached;
