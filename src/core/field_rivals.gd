class_name FieldRivals
extends RefCounted
## Rival combat state stays at the capture boundary. RecruitUnits below are display/log copies.

var library: FieldLibrary
var seats: Dictionary = {}
var frames: Dictionary = {}
var source_rounds: Dictionary = {}
var switches: Array[Dictionary] = []
var history: Array[Dictionary] = []
var _reserved: Dictionary = {}


func setup(session: GameSession) -> void:
	var rng: RandomNumberGenerator = session._derive("field")
	var lines: Dictionary = library.data["lines"]
	var groups: Dictionary = {}
	for id: String in lines:
		var line_data: Dictionary = lines[id]
		var tribe: String = line_data["tribe"]
		if (
			tribe != ""
			and not session._lobby_tribes.is_empty()
			and not session._lobby_tribes.has(tribe)
		):
			continue
		if not groups.has(tribe):
			groups[tribe] = []
		var group: Array = groups[tribe]
		group.append(id)
	var deck: Array = []
	for player: PlayerState in session._players:
		if player.id == GameSession.HUMAN_ID:
			continue
		if deck.is_empty():
			deck = groups.keys()
			_shuffle(deck, rng)
		var tribe: String = str(deck.pop_back())
		var policies: Array = groups[tribe]
		var line: String = policies[rng.randi_range(0, policies.size() - 1)]
		var line_data: Dictionary = lines[line]
		var trajectories: Array = line_data["trajectories"]
		var trajectory: Dictionary = trajectories[rng.randi_range(0, trajectories.size() - 1)]
		seats[player.id] = {"line": line, "source_line": line, "trajectory": trajectory}
		HeroRules.assign(player, session._library.get_hero(str(trajectory["hero"])))
		player.personality = "field:%s" % line
		player.name = "Rival %d · %s" % [player.id, trajectory["name"]]
		session._bots.erase(player.id)
	# A separate persistent trajectory supplies ghosts, advancing even before the first death.
	var first_seat: Dictionary = seats[1]
	seats[Matchmaking.GHOST] = first_seat.duplicate(true)


func prepare(session: GameSession) -> void:
	for id: String in _reserved:
		session._pool.give_back(id, CoreUtil.to_int(_reserved[id]))
	_reserved.clear()
	for id: int in seats:
		if id >= 0 and not session._players[id].alive:
			continue
		_advance(id, session._round)
		history.append(
			{
				"seat": id,
				"round": session._round,
				"line": seats[id]["line"],
				"source_line": seats[id]["source_line"],
				"trajectory": seats[id]["trajectory"]["id"],
				"source_round": source_rounds[id]
			}
		)
		if id < 0:
			continue
		var player: PlayerState = session._players[id]
		var frame: Dictionary = frames[id]
		var trajectory: Dictionary = seats[id]["trajectory"]
		# Switching never restores Health, Armor or Last Stand.
		player.hero = session._library.get_hero(str(trajectory["hero"]))
		player.name = "Rival %d · %s" % [id, trajectory["name"]]
		player.tier = CoreUtil.to_int(frame["tier"])
		player.round_number = session._round
		var specs: Array = frame["board"]
		player.fought_specs = specs.duplicate(true)
		var slots: Array = frame["slots"]
		player.fought_slots = slots.duplicate(true)
		var rules: Dictionary = frame["fight_rules"]
		player.fought_rules = rules.duplicate(true)
		player.fought_view = _views(frame, session._library)
		for slot: int in BoardGeometry.SLOTS:
			var board: Array = frame["board"]
			var value: Variant = board[slot]
			player.board[slot] = null
			if value != null:
				var spec: Dictionary = value
				var view: Dictionary = player.fought_view[slot]
				var unit := RecruitUnit.make(
					session._library.get_unit(str(spec["def_id"])),
					0,
					CoreUtil.to_bool(spec.get("golden", false))
				)
				unit.perm_attack = CoreUtil.to_int(view["attack"]) - unit.base_attack_now()
				unit.perm_health = CoreUtil.to_int(view["health"]) - unit.base_health_now()
				player.board[slot] = unit
				_reserve(spec, session._pool)
		for nest: Dictionary in rules.get("nests", []):
			var bird: Dictionary = nest["spec"]
			_reserve(bird, session._pool)


func _advance(id: int, round_number: int) -> void:
	var seat: Dictionary = seats[id]
	var trajectory: Dictionary = seat["trajectory"]
	var rounds: Dictionary = trajectory["rounds"]
	if not rounds.has(str(round_number)):
		var eligible: Array = _choices(str(seat["line"]), round_number)
		var target: int = round_number
		if eligible.is_empty():
			# Beyond the entire source horizon there is no round-matched field to borrow.
			target = _last_round()
			eligible = _choices(str(seat["line"]), target)
		var previous: Dictionary = frames.get(id, rounds["1"])
		var size: int = board_size(previous)
		eligible.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool:
				var a_trajectory: Dictionary = a["trajectory"]
				var a_rounds: Dictionary = a_trajectory["rounds"]
				var a_frame: Dictionary = a_rounds[str(target)]
				var da: int = absi(board_size(a_frame) - size)
				var b_trajectory: Dictionary = b["trajectory"]
				var b_rounds: Dictionary = b_trajectory["rounds"]
				var b_frame: Dictionary = b_rounds[str(target)]
				var db: int = absi(board_size(b_frame) - size)
				return da < db if da != db else str(a_trajectory["id"]) < str(b_trajectory["id"])
		)
		var choice: Dictionary = eligible[0]
		var next: Dictionary = choice["trajectory"]
		if next["id"] != trajectory["id"]:
			switches.append(
				{
					"seat": id,
					"round": round_number,
					"from": trajectory["id"],
					"to": next["id"],
					"from_line": seat["source_line"],
					"to_line": choice["line"],
					"source_round": target
				}
			)
		seat["trajectory"] = next
		seat["source_line"] = choice["line"]
		trajectory = next
		rounds = trajectory["rounds"]
		source_rounds[id] = target
	else:
		source_rounds[id] = round_number
	var selected_frame: Dictionary = rounds[str(source_rounds[id])]
	frames[id] = selected_frame.duplicate(true)


## A whole extinct source line cannot supply this round. Prefer its tribe, then this round's
## wider field; only use a terminal-round field when no source trajectory reaches the round.
func _choices(preferred: String, round_number: int) -> Array:
	var lines: Dictionary = library.data["lines"]
	var preferred_line: Dictionary = lines[preferred]
	var same: Array = []
	var tribe: Array = []
	var any_line: Array = []
	for line_id: String in lines:
		var line: Dictionary = lines[line_id]
		for trajectory: Dictionary in line["trajectories"]:
			var rounds: Dictionary = trajectory["rounds"]
			if not rounds.has(str(round_number)):
				continue
			var choice: Dictionary = {"line": line_id, "trajectory": trajectory}
			any_line.append(choice)
			if line_id == preferred:
				same.append(choice)
			if line["tribe"] == preferred_line["tribe"]:
				tribe.append(choice)
	return same if not same.is_empty() else (tribe if not tribe.is_empty() else any_line)


func _last_round() -> int:
	var latest: int = 1
	var lines: Dictionary = library.data["lines"]
	for line: Dictionary in lines.values():
		for trajectory: Dictionary in line["trajectories"]:
			var rounds: Dictionary = trajectory["rounds"]
			latest = maxi(latest, rounds.size())
	return latest


## Size means total captured Attack + Health, including next-combat buffs and held bodies.
static func board_size(frame: Dictionary) -> int:
	var total: int = 0
	for value: Variant in frame["board"]:
		if value != null:
			var spec: Dictionary = value
			total += _spec_size(spec)
	return total


static func _spec_size(spec: Dictionary) -> int:
	var size: int = 0
	for key: String in ["attack", "health", "combat_attack", "combat_health"]:
		size += CoreUtil.to_int(spec.get(key, 0))
	for held: Dictionary in spec.get("held", []):
		size += _spec_size(held)
	return size


func _reserve(spec: Dictionary, pool: UnitPool) -> void:
	var def_id: String = str(spec["def_id"])
	var copies: int = 3 if CoreUtil.to_bool(spec.get("golden", false)) else 1
	for _copy: int in copies:
		if pool.take(def_id):
			_reserved[def_id] = CoreUtil.to_int(_reserved.get(def_id, 0)) + 1
	for held: Dictionary in spec.get("held", []):
		_reserve(held, pool)


func scout(id: int, unit_library: UnitLibrary) -> Dictionary:
	var frame: Dictionary = frames[id]
	var nests: Array = []
	var rules: Dictionary = frame["fight_rules"]
	for nest: Dictionary in rules.get("nests", []):
		nests.append(nest["slot"])
	var board: Array = frame["board"]
	var slots: Array = frame["slots"]
	var effects: Array = frame["hero_effects"]
	return {
		"views": _views(frame, unit_library),
		"specs": board.duplicate(true),
		"slots": slots.duplicate(true),
		"hero_effects": effects.duplicate(true),
		"rules": rules.duplicate(true),
		"tier": frame["tier"],
		"nests": nests
	}


static func _views(frame: Dictionary, unit_library: UnitLibrary) -> Array:
	if frame.has("views"):
		var captured_views: Array = frame["views"]
		return captured_views.duplicate(true)
	var views: Array = []
	for value: Variant in frame["board"]:
		if value == null:
			views.append(null)
		else:
			var spec: Dictionary = value
			views.append(
				CombatUnit.make(unit_library.get_unit(str(spec["def_id"])), spec, 0, 0).view()
			)
	return views


## Both ordinary and field games use this same fight assembly; field inputs bypass recruit.
static func side(session: GameSession, id: int) -> Dictionary:
	if session._field != null and session._field.frames.has(id):
		var frame: Dictionary = session._field.frames[id]
		return frame.duplicate(true)
	if id == Matchmaking.GHOST:
		return {
			"board": session._ghost_board,
			"slots": session._ghost_slots,
			"hero_effects": [],
			"fight_rules": session._ghost_rules,
			"tier": session._ghost_tier
		}
	var player: PlayerState = session._players[id]
	return {
		"board": player.combat_board(),
		"slots": player.combat_slots(),
		"hero_effects": HeroRules.effects_of(player.hero),
		"fight_rules": session._rules.fight_rules(player),
		"tier": player.tier
	}


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for index: int in range(items.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var swap: Variant = items[index]
		items[index] = items[other]
		items[other] = swap
