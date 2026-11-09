extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")

const BASELINE: String = "res://tests/fixtures/field/baseline.json"
const REPLAY: String = "res://tests/fixtures/field/replay.json"

var _library: UnitLibrary = UnitLibrary.load_dir()
var _observed: Array = []


func _session(seed_value: int = 71) -> GameSession:
	var config := GameConfig.full_game()
	assert_eq(FieldLibrary.configure(config, _library, BASELINE), "")
	config.set_value("human_bot", "hard")
	return GameSession.create(seed_value, _library, config)


func _remember(input: Dictionary, result: Dictionary, _combat: Combat) -> void:
	_observed.append({"input": input.duplicate(true), "result": result.duplicate(true)})


func test_field_game_reaches_a_winner_with_real_eliminations_and_repeats_exactly() -> void:
	_observed.clear()
	var first := _session()
	assert_not_null(first)
	if first == null:
		return
	first.fight_capture_observer = _remember
	while not first.is_over():
		assert_eq(first.end_turn(), "")
	var first_fights: Array = _observed.duplicate(true)
	assert_eq(first._living().size(), 1)
	var places: Array = first.get_standings().map(
		func(row: Dictionary) -> int: return CoreUtil.to_int(row["placement"])
	)
	places.sort()
	assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8])
	assert_true(
		first_fights.any(func(row: Dictionary) -> bool: return row["input"]["player_ids"].has(-1)),
		"normal matchmaking includes field ghosts"
	)
	_observed.clear()
	var second := _session()
	second.fight_capture_observer = _remember
	while not second.is_over():
		second.end_turn()
	assert_eq(FightCapture.canonical(_observed), FightCapture.canonical(first_fights))
	assert_eq(first.get_standings(), second.get_standings())
	assert_eq(first._field.switches, second._field.switches)


func test_captured_fight_matches_the_harness_at_the_field_game_boundary() -> void:
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REPLAY))
	var input: Dictionary = record["input"]
	var session := _session(CoreUtil.to_int(record["seed"]))
	session._round = CoreUtil.to_int(input["round"])
	var ids: Array = input["player_ids"]
	for side: int in 2:
		session._field.frames[CoreUtil.to_int(ids[side])] = {
			"board": input["boards"][side],
			"slots": input["slots"][side],
			"hero_effects": input["hero_effects"][side],
			"fight_rules": input["fight_rules"][side],
			"tier": input["tiers"][side]
		}
	_observed.clear()
	session.fight_capture_observer = _remember
	session._fight(
		CoreUtil.to_int(ids[0]), CoreUtil.to_int(ids[1]), CoreUtil.to_int(input["damage_cap"])
	)
	assert_eq(_observed.size(), 1)
	assert_true(
		FightCapture.matches(record, _observed[0]["result"]), "every result and event matches"
	)
	for key: String in [
		"boards",
		"slots",
		"hero_effects",
		"fight_rules",
		"tiers",
		"rng_seed",
		"rng_state",
		"effect_rng_seed",
		"effect_rng_state"
	]:
		assert_eq(
			FightCapture.canonical(_observed[0]["input"][key]),
			FightCapture.canonical(input[key]),
			key
		)


func test_switch_uses_same_line_closest_size_without_restoring_health() -> void:
	var session := _session()
	var field: FieldRivals = session._field
	var seat: Dictionary = field.seats[1]
	var initial: Dictionary = seat["trajectory"].duplicate(true)
	var frame: Dictionary = {}
	for candidate: Dictionary in initial["rounds"].values():
		if FieldRivals.board_size(candidate) > 0:
			frame = candidate.duplicate(true)
			break
	frame.erase("views")
	# Three candidates have equal occupied slots but very different total stats.
	var spec: Dictionary = (
		frame["board"].filter(func(value: Variant) -> bool: return value != null)[0].duplicate(true)
	)
	frame["board"] = [spec, null, null, null, null, null, null]
	spec["attack"] = 10
	spec["health"] = 10
	initial["id"] = "ended"
	initial["rounds"] = {"1": frame}
	seat["trajectory"] = initial
	field.frames[1] = frame
	var candidates: Array = [initial]
	for amount: int in [12, 100]:
		var next: Dictionary = initial.duplicate(true)
		next["id"] = str(amount)
		var next_frame: Dictionary = frame.duplicate(true)
		next_frame["board"][0]["attack"] = amount
		next["rounds"]["2"] = next_frame
		candidates.append(next)
	field.library.data["lines"][seat["line"]]["trajectories"] = candidates
	session._players[1].health = 7
	session._players[1].armor = 1
	session._players[1].last_stand_used = true
	session._round = 2
	field.prepare(session)
	assert_eq(seat["trajectory"]["id"], "12")
	assert_eq(field.source_rounds[1], 2)
	assert_eq(session._players[1].health, 7)
	assert_eq(session._players[1].armor, 1)
	assert_true(session._players[1].last_stand_used)
	assert_eq(field.switches[0]["to"], "12")


func test_ghost_and_scout_use_current_field_inputs_instead_of_dead_board() -> void:
	var session := _session()
	session._round = 3
	session._field.prepare(session)
	session._ghost_board = [null, null, null, null, null, null, null]
	var ghost: Dictionary = FieldRivals.side(session, Matchmaking.GHOST)
	assert_eq(FightCapture.canonical(ghost), FightCapture.canonical(session._field.frames[-1]))
	assert_eq(session._field.source_rounds[-1], 3)
	assert_ne(FightCapture.canonical(ghost["board"]), FightCapture.canonical(session._ghost_board))
	var scout: Dictionary = session._scout_of(-1)
	assert_eq(scout["specs"], ghost["board"])
	assert_eq(scout["slots"], ghost["slots"])
	assert_eq(scout["hero_effects"], ghost["hero_effects"])
	_observed.clear()
	session.fight_capture_observer = _remember
	session._fight(0, -1, 0)
	assert_eq(_observed[0]["input"]["boards"][1], ghost["board"])


func test_loader_rejects_versions_content_config_and_malformed_rounds() -> void:
	var field := FieldLibrary.read(BASELINE, _library)
	assert_eq(field.error, "")
	var original: Dictionary = field.data.duplicate(true)
	field.data["config_version"] = 999
	assert_string_contains(field._validate(_library), "version mismatch")
	field.data = original.duplicate(true)
	var hashes: Dictionary = field.data["content_hashes"]
	hashes[hashes.keys()[0]] = "changed"
	assert_string_contains(field._validate(_library), "content version mismatch")
	field.data = original.duplicate(true)
	var config := GameConfig.full_game()
	assert_eq(FieldLibrary.configure(config, _library, BASELINE), "")
	config.set_value("starting_health", 100)
	assert_string_contains(field.config_problem(config), "starting_health")
	config.set_value("opponents", "field")
	assert_null(
		GameSession.create(71, _library, config), "direct callers cannot silently mix configs"
	)
	var lines: Dictionary = field.data["lines"]
	var first: Dictionary = lines[lines.keys()[0]]["trajectories"][0]
	first["rounds"].erase("1")
	assert_string_contains(field._validate(_library), "noncontiguous")


func test_pool_reserves_visible_units_and_returns_them_between_rounds() -> void:
	var session := _session()
	assert_gt(session._field._reserved.size(), 0)
	var reserved: Dictionary = session._field._reserved.duplicate()
	var counts: Dictionary = {}
	for id: String in reserved:
		counts[id] = session._pool.copies_left(id)
	for player: PlayerState in session._players:
		if player.id > 0:
			player.alive = false
	session._field.prepare(session)
	assert_true(session._field._reserved.is_empty())
	for id: String in reserved:
		assert_eq(
			session._pool.copies_left(id),
			CoreUtil.to_int(counts[id]) + CoreUtil.to_int(reserved[id])
		)


func test_extinct_line_borrows_same_tribe_before_wider_field_and_labels_terminal_tail() -> void:
	var session := _session()
	var field: FieldRivals = session._field
	var initial: Dictionary = field.seats[1]["trajectory"].duplicate(true)
	var frame: Dictionary = initial["rounds"]["1"]
	initial["id"] = "ended"
	initial["rounds"] = {"1": frame}
	var successor: Dictionary = initial.duplicate(true)
	successor["id"] = "same-tribe"
	successor["rounds"]["2"] = frame.duplicate(true)
	var other: Dictionary = successor.duplicate(true)
	other["id"] = "other-tribe"
	field.library.data["lines"] = {
		"original": {"tribe": "Birds", "trajectories": [initial]},
		"successor": {"tribe": "Birds", "trajectories": [successor]},
		"other": {"tribe": "Oozes", "trajectories": [other]}
	}
	field.seats[1] = {"line": "original", "source_line": "original", "trajectory": initial}
	field._advance(1, 2)
	assert_eq(field.seats[1]["source_line"], "successor")
	assert_eq(field.source_rounds[1], 2)
	field._advance(1, 3)
	assert_eq(field.source_rounds[1], 2, "terminal field is labelled with its actual source round")
	assert_eq(field.seats[1]["trajectory"]["id"], "same-tribe")
