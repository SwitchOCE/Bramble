-- Q2: per card on final boards: boards with it, share of final boards, avg place with vs without, golden share of copies
WITH per_board AS (SELECT game, seat, card, count(*) AS copies, sum(golden::INT) AS golden FROM final_board GROUP BY ALL),
     tot AS (SELECT count(*) AS n, sum(place) AS sp FROM seats)
SELECT card, count(*) AS boards, round(count(*) / any_value(tot.n), 4) AS share_of_boards,
       round(avg(s.place), 3) AS place_with,
       round((any_value(tot.sp) - sum(s.place)) / (any_value(tot.n) - count(*)), 3) AS place_without,
       sum(copies) AS copies, round(sum(golden) / sum(copies), 3) AS golden_share
FROM per_board JOIN seats s USING (game, seat) CROSS JOIN tot
GROUP BY card ORDER BY boards DESC;
