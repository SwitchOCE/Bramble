-- Q6 against the whole-file archive layout (smallest): split every record into lines at query time
SELECT game, l->>'turn' AS round, p->>'id' AS player, p AS snapshot_json
FROM (SELECT game, unnest(from_json(l->'players', '["JSON"]')) AS p, l FROM
      (SELECT game, unnest(string_split(data, chr(10))) AS l FROM records) WHERE l LIKE '{"hash"%"op":"fight_boards"%"turn":8}')
ORDER BY hash(game * 8 + (p->>'id')::INT) LIMIT 50;
