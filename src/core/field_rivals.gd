class_name FieldRivals
extends RefCounted
## Rival combat state stays at the capture boundary. RecruitUnits below are display/log copies.

var library: FieldLibrary
var seats: Dictionary = {}
var frames: Dictionary = {}
var previous_frames: Dictionary = {}
var source_rounds: Dictionary = {}
var switches: Array[Dictionary] = []
var history: Array[Dictionary] = []
var _reserved: Dictionary = {}
var _eligible: Array[Dictionary] = []
var _active_ids: Array[int] = []


static func create(
	config: GameConfig,
	units: UnitLibrary,
	lobby_tribes: PackedStringArray,
	prepared: FieldLibrary = null
) -> FieldRivals:
	var field := FieldRivals.new()
	field.library = (
		prepared
		if prepared != null
		else FieldLibrary.read(config.get_string("field_library"), units)
	)
	if field.library.error != "" or field.library.config_problem(config) != "":
		return null
	if field.library.can_deal(lobby_tribes, config.get_string("field_strength")) != "":
		return null
	return field


func setup(session: GameSession) -> void:
	var rng: RandomNumberGenerator = session._derive("field")
	_eligible = library.eligible(
		session._lobby_tribes, session._config.get_string("field_strength")
	)
	var available: Array[Dictionary] = _eligible.duplicate()
	var ids: Array[int] = []
	for player: PlayerState in session._players:
		if player.id != GameSession.HUMAN_ID:
			ids.append(player.id)
	ids.append(Matchmaking.GHOST)
	var deck: Array = []
	for id: int in ids:
		var groups: Dictionary = {}
		for choice: Dictionary in available:
			var line: Dictionary = library.data["lines"][choice["line"]]
			var tribe: String = line["tribe"]
			if not groups.has(tribe):
				groups[tribe] = []
			var tribe_choices: Array = groups[tribe]
			tribe_choices.append(choice)
		deck = deck.filter(func(tribe: String) -> bool: return groups.has(tribe))
		if deck.is_empty():
			deck = groups.keys()
			_shuffle(deck, rng)
		var group: Array = groups[str(deck.pop_back())]
		var policies: Dictionary = {}
		for choice: Dictionary in group:
			var candidate_line: String = choice["line"]
			if not policies.has(candidate_line):
				policies[candidate_line] = []
			var policy_choices: Array = policies[candidate_line]
			policy_choices.append(choice)
		var names: Array = policies.keys()
		var line_id: String = str(names[rng.randi_range(0, names.size() - 1)])
		var choices: Array = policies[line_id]
		var choice: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
		var trajectory: Dictionary = choice["trajectory"]
		seats[id] = {"line": line_id, "source_line": line_id, "trajectory": trajectory}
		available.erase(choice)
		if id == Matchmaking.GHOST:
			continue
		var player: PlayerState = session._players[id]
		HeroRules.assign(player, session._library.get_hero(str(trajectory["hero"])))
		player.personality = "field:%s" % line_id
		player.name = "Rival %d · %s" % [id, player.hero["name"]]
		session._bots.erase(id)


func prepare(session: GameSession) -> void:
	previous_frames = frames.duplicate(true)
	_active_ids.clear()
	for id: int in seats:
		if id == Matchmaking.GHOST or session._players[id].alive:
			_active_ids.append(id)
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
		player.name = "Rival %d · %s" % [id, player.hero["name"]]
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
		var eligible: Array = _choices(str(seat["line"]), round_number, id)
		var target: int = round_number
		if eligible.is_empty():
			# Beyond the entire source horizon there is no round-matched field to borrow.
			target = _last_round(id)
			eligible = _choices(str(seat["line"]), target, id)
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
func _choices(preferred: String, round_number: int, seat_id: int) -> Array:
	var lines: Dictionary = library.data["lines"]
	var preferred_line: Dictionary = lines[preferred]
	var same: Array = []
	var tribe: Array = []
	var any_line: Array = []
	for choice: Dictionary in _eligible:
		var trajectory: Dictionary = choice["trajectory"]
		var rounds: Dictionary = trajectory["rounds"]
		if not rounds.has(str(round_number)) or _occupied(str(trajectory["id"]), seat_id):
			continue
		var line_id: String = choice["line"]
		var line: Dictionary = lines[line_id]
		any_line.append(choice)
		if line_id == preferred:
			same.append(choice)
		if line["tribe"] == preferred_line["tribe"]:
			tribe.append(choice)
	return same if not same.is_empty() else (tribe if not tribe.is_empty() else any_line)


func _occupied(trajectory_id: String, except_id: int) -> bool:
	for id: int in _active_ids:
		if id != except_id and seats[id]["trajectory"]["id"] == trajectory_id:
			return true
	return false


func _last_round(seat_id: int) -> int:
	var latest: int = 1
	for choice: Dictionary in _eligible:
		var trajectory: Dictionary = choice["trajectory"]
		if not _occupied(str(trajectory["id"]), seat_id):
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


func ghost_hero(unit_library: UnitLibrary) -> Dictionary:
	var seat: Dictionary = seats[Matchmaking.GHOST]
	var trajectory: Dictionary = seat["trajectory"]
	return GameSession._hero_card(unit_library.get_hero(str(trajectory["hero"])))


func scout(id: int, unit_library: UnitLibrary) -> Dictionary:
	if not previous_frames.has(id):
		return {}
	var frame: Dictionary = previous_frames[id]
	var nests: Array = []
	var rules: Dictionary = frame["fight_rules"]
	for nest: Dictionary in rules.get("nests", []):
		nests.append(nest["slot"])
	var board: Array = frame["board"]
	var slots: Array = frame["slots"]
	var public_frame: Dictionary = frames.get(id, frame)
	var effects: Array = public_frame["hero_effects"]
	return {
		"views": _public_board(_views(frame, unit_library)),
		"specs": _public_board(board),
		"slots": slots.duplicate(true),
		"hero_effects": effects.duplicate(true),
		"rules": {"back_row_first": rules.get("back_row_first", false)},
		"tier": public_frame["tier"],
		"nests": nests
	}


static func _public_board(entries: Array) -> Array:
	var out: Array = entries.duplicate(true)
	for value: Variant in out:
		if value == null:
			continue
		var entry: Dictionary = value
		if str(entry.get("def_id", "")) == HeldUnits.EGG:
			for key: String in ["bird_attack", "bird_health", "turns_left"]:
				entry.erase(key)
	return out


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
