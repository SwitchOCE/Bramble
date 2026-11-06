class_name GameLog
extends RefCounted
## The review log: what each player's board was each round, and an end-of-game summary (boards by
## round, placements, gold spent, per-tribe stats) for the UI and for bots' evaluation.

## Player id -> the rounds recorded: {"round", "tier", "gold_spent", "health", "armor", "result",
## "board": [null or {"def_id", "name", "attack", "health", "golden", "tribes"}]}.
var _rounds: Dictionary = {}
## Player id -> tribe -> player-rounds with a unit of that tribe on board, counted per unit.
var _tribe_rounds: Dictionary = {}


## After a round's fights, before eliminations: every board that fought.
func record_round(round_number: int, players: Array[PlayerState]) -> void:
	for player: PlayerState in players:
		var rows: Array = _rounds.get(player.id, [])
		(
			rows
			. append(
				{
					"round": round_number,
					"tier": player.tier,
					"gold_spent": player.gold_spent_turn,
					"gold_at_start": player.gold_at_start,
					"gold_left": player.gold,
					"paid_refreshes": player.paid_refreshes,
					"items": _item_ids(player),
					"units_bought": player.units_bought,
					"health": player.health,
					"armor": player.armor,
					"result": player.last_result,
					"board": _board_row(player),
				}
			)
		)
		_rounds[player.id] = rows


static func _item_ids(player: PlayerState) -> Array:
	var out: Array = []
	for item: HandItem in player.items:
		out.append(item.def_id())
	return out


func _board_row(player: PlayerState) -> Array:
	var counts: Dictionary = _tribe_rounds.get(player.id, {})
	var board: Array = []
	for unit: RecruitUnit in player.board:
		if unit == null:
			board.append(null)
			continue
		(
			board
			. append(
				{
					"def_id": unit.def_id(),
					"name": str(unit.def["name"]),
					"attack": unit.attack,
					"health": unit.health,
					"golden": unit.golden,
					"tribes": unit.tribes().duplicate(),
				}
			)
		)
		for tribe: Variant in unit.tribes():
			counts[tribe] = CoreUtil.to_int(counts.get(tribe, 0)) + 1
	_tribe_rounds[player.id] = counts
	return board


## {"lobby_tribes", "rounds", "players": [...], "tribes": {tribe: {...}}}. A player's "main_tribe"
## is the tribe with the most unit-rounds on its board ("" for a neutral board).
func summary(players: Array[PlayerState], lobby_tribes: PackedStringArray) -> Dictionary:
	var rows: Array = []
	var tribes: Dictionary = {}
	var most_rounds: int = 0
	for player: PlayerState in players:
		var rounds: Array = _rounds.get(player.id, [])
		most_rounds = maxi(most_rounds, rounds.size())
		var main_tribe: String = _main_tribe(player.id)
		var unit_rounds: Dictionary = _tribe_rounds.get(player.id, {})
		(
			rows
			. append(
				{
					"player_id": player.id,
					"name": player.name,
					"personality": player.personality,
					"hero": str(player.hero.get("id", "")),
					"placement": CoreUtil.int_or_null(player.placement, 0),
					"health": player.health,
					"tier": player.tier,
					"gold_spent": player.gold_spent_game,
					"main_tribe": main_tribe,
					"bought_by_tribe": player.bought_by_tribe.duplicate(),
					"tribe_unit_rounds": unit_rounds.duplicate(),
					"rounds": rounds,
				}
			)
		)
		_add_tribe_stats(tribes, player, main_tribe)
	_finish_tribe_stats(tribes)
	return {
		"lobby_tribes": Array(lobby_tribes),
		"rounds": most_rounds,
		"players": rows,
		"tribes": tribes,
	}


func _main_tribe(player_id: int) -> String:
	var counts: Dictionary = _tribe_rounds.get(player_id, {})
	var best: String = ""
	var best_count: int = 0
	var names: Array = counts.keys()
	names.sort()
	for name: Variant in names:
		var count: int = CoreUtil.to_int(counts[name])
		if count > best_count:
			best = str(name)
			best_count = count
	return best


func _add_tribe_stats(tribes: Dictionary, player: PlayerState, main_tribe: String) -> void:
	for tribe: Variant in player.bought_by_tribe:
		var entry: Dictionary = _tribe_entry(tribes, str(tribe))
		entry["bought"] = (
			CoreUtil.to_int(entry["bought"]) + CoreUtil.to_int(player.bought_by_tribe[tribe])
		)
	var counts: Dictionary = _tribe_rounds.get(player.id, {})
	for tribe: Variant in counts:
		var entry: Dictionary = _tribe_entry(tribes, str(tribe))
		entry["unit_rounds"] = (
			CoreUtil.to_int(entry["unit_rounds"]) + CoreUtil.to_int(counts[tribe])
		)
	if main_tribe != "" and player.placement > 0:
		var entry: Dictionary = _tribe_entry(tribes, main_tribe)
		entry["main_players"] = CoreUtil.to_int(entry["main_players"]) + 1
		entry["placement_sum"] = CoreUtil.to_int(entry["placement_sum"]) + player.placement
		if player.placement == 1:
			entry["wins"] = CoreUtil.to_int(entry["wins"]) + 1


static func _tribe_entry(tribes: Dictionary, tribe: String) -> Dictionary:
	if not tribes.has(tribe):
		tribes[tribe] = {
			"bought": 0,
			"unit_rounds": 0,
			"main_players": 0,
			"placement_sum": 0,
			"wins": 0,
		}
	var entry: Dictionary = tribes[tribe]
	return entry


static func _finish_tribe_stats(tribes: Dictionary) -> void:
	for tribe: Variant in tribes:
		var entry: Dictionary = tribes[tribe]
		var players: int = entry["main_players"]
		var total: int = entry["placement_sum"]
		entry["avg_placement"] = float(total) / players if players > 0 else 0.0
