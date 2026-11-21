-- Q1b: per card overall: offered, bought, buy rate, times sold, mean bot value (shop reports)
WITH off AS (SELECT card, count(*) AS offered, sum(bought::INT) AS bought FROM shop_offers WHERE NOT spell GROUP BY card),
     sold AS (SELECT card, count(*) AS sold FROM actions WHERE action = 'sell' GROUP BY card),
     val AS (SELECT card, avg(value) AS bot_value, median(value) AS bot_value_median, count(*) AS valued FROM bot_values WHERE kind = 'shop' GROUP BY card)
SELECT off.card, offered, bought, round(bought / offered, 4) AS buy_rate, coalesce(sold, 0) AS sold,
       round(coalesce(sold, 0) / nullif(bought, 0), 3) AS sold_per_buy, round(bot_value, 2) AS bot_value, round(bot_value_median, 2) AS bot_value_median
FROM off LEFT JOIN sold USING (card) LEFT JOIN val USING (card) ORDER BY buy_rate DESC;
