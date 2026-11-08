extends RefCounted
## One unordered cross-tribe pair per round/roll. Every seed fights in both orientations.


static func schedule(boards: Array) -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	for a: int in boards.size():
		var left: Dictionary = boards[a]["source"]
		for b: int in range(a + 1, boards.size()):
			var right: Dictionary = boards[b]["source"]
			if (
				left["tribe"] != right["tribe"]
				and left["round"] == right["round"]
				and left["roll"] == right["roll"]
			):
				pairs.append({"a": a, "b": b, "round": left["round"], "roll": left["roll"]})
	return pairs


static func fight(
	library: UnitLibrary,
	config: GameConfig,
	left: Dictionary,
	right: Dictionary,
	fight_seed: int,
	log_events: bool = false
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(library, config, rng)
	combat.log_events = log_events
	combat.slot_effects = [left["slot_effects"], right["slot_effects"]]
	combat.side_rules = [left["rules"], right["rules"]]
	var tiers: Array[int] = [
		CoreUtil.to_int(left["source"]["tier"]), CoreUtil.to_int(right["source"]["tier"])
	]
	var ids: Array[int] = [0, 1]
	return combat.run([left["specs"], right["specs"]], tiers, ids, 0)


static func empty_record() -> Dictionary:
	return {"fights": 0, "wins": 0, "draws": 0, "losses": 0, "reasons": {}}


static func record_result(record: Dictionary, winner: int, side: int, reason: String) -> void:
	record["fights"] = CoreUtil.to_int(record["fights"]) + 1
	var key: String = "draws" if winner < 0 else ("wins" if winner == side else "losses")
	record[key] = CoreUtil.to_int(record[key]) + 1
	var reasons: Dictionary = record["reasons"]
	reasons[reason] = CoreUtil.to_int(reasons.get(reason, 0)) + 1


static func rates(record: Dictionary) -> Dictionary:
	var out: Dictionary = record.duplicate(true)
	var count: int = CoreUtil.to_int(record["fights"])
	var wins: float = CoreUtil.to_int(record["wins"])
	var draws: float = CoreUtil.to_int(record["draws"])
	var losses: float = CoreUtil.to_int(record["losses"])
	out["win_rate"] = wins / count if count > 0 else 0.0
	out["draw_rate"] = draws / count if count > 0 else 0.0
	out["loss_rate"] = losses / count if count > 0 else 0.0
	out["point_rate"] = ((wins + 0.5 * draws) / count if count > 0 else 0.0)
	return out


static func board_rows(boards: Array, records: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for index: int in boards.size():
		var board: Dictionary = boards[index]
		var source: Dictionary = board["source"]
		var limitations: Array = board["unrepresentable"]
		var record: Dictionary = records[index]
		var row: Dictionary = rates(record)
		row.merge(
			{
				"id": board["id"],
				"tribe": source["tribe"],
				"round": source["round"],
				"roll": source["roll"],
				"tier": source["tier"],
				"guessed_rank": source["rank"],
				"stat_total": source["stat_total"],
				"limitation_count": limitations.size()
			}
		)
		rows.append(row)
	for row: Dictionary in rows:
		var rank: int = 1
		var point_rate: float = row["point_rate"]
		for other: Dictionary in rows:
			var other_point_rate: float = other["point_rate"]
			if (
				row["round"] == other["round"]
				and row["roll"] == other["roll"]
				and other_point_rate > point_rate
			):
				rank += 1
		row["measured_rank"] = rank
		row["rank_change"] = CoreUtil.to_int(row["guessed_rank"]) - rank
	return rows


static func tribe_rows(boards: Array, records: Array) -> Array[Dictionary]:
	var groups: Dictionary = {}
	for index: int in boards.size():
		var tribe: String = str(boards[index]["source"]["tribe"])
		var combined: Dictionary = groups.get(tribe, empty_record())
		var record: Dictionary = records[index]
		for key: String in ["fights", "wins", "draws", "losses"]:
			combined[key] = CoreUtil.to_int(combined[key]) + CoreUtil.to_int(record[key])
		groups[tribe] = combined
	var rows: Array[Dictionary] = []
	for tribe: String in groups:
		var record: Dictionary = groups[tribe]
		var row: Dictionary = rates(record)
		row["tribe"] = tribe
		rows.append(row)
	return rows
