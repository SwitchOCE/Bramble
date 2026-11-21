-- Q6: 50 full board snapshots at round 8, from the archive's fight_boards lines (one row per player board)
SELECT game, turn AS round, p.id::INT AS player, p.tier::INT AS tier, p.board AS board_json, p AS snapshot_json
FROM (SELECT game, turn, unnest(from_json(line->'players', '["JSON"]')) AS p FROM record_lines WHERE op = 'fight_boards' AND turn = 8)
ORDER BY hash(game * 8 + p.id::INT) LIMIT 50;
