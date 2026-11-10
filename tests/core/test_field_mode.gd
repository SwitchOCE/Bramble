extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")

const FieldTestData := preload("res://tests/core/field_test_data.gd")
const FrozenContent := preload("res://tests/core/field_frozen_content.gd")
const REPLAY: String = "res://tests/fixtures/field/replay.json"

var _library: UnitLibrary = TestLibraries.current()
var _observed: Array = []
var _frozen: FrozenContent


func after_each() -> void:
	if _frozen != null:
		_frozen.restore()
		_frozen = null


func _session(seed_value: int = 71) -> GameSession:
	var config := GameConfig.full_game()
	var field := FieldLibrary.prepare(config, _library, FieldTestData.path())
	assert_eq(field.error, "")
	config.set_value("human_bot", "hard")
	return GameSession.create(seed_value, _library, config, Bot.create, field)


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
	for standing: Dictionary in first.get_standings():
		assert_false(standing.has("field_line"))
		assert_false(standing.has("field_source_line"))
		assert_false(standing.has("field_source_round"))
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
	_frozen = FrozenContent.new()
	_frozen.setup()
	session._library = _frozen.library
	session._config = FightCapture.config_for(input["config"])
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
	field._eligible = field.library.eligible(session._lobby_tribes, "top4")
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


func test_ghost_fights_current_field_but_scouts_previous_round_with_no_opening_reveal() -> void:
	var session := _session()
	assert_eq(session._scout_of(-1), {})
	assert_eq(session.get_state()["next_opponent_last_board"], [])
	var round_one: Dictionary = session._field.frames[-1].duplicate(true)
	session._round = 2
	session._field.prepare(session)
	var first_scout: Dictionary = session._field.scout(-1, session._library)
	assert_eq(first_scout["specs"], FieldRivals._public_board(round_one["board"]))
	session._round = 3
	var round_two: Dictionary = session._field.frames[-1].duplicate(true)
	session._field.prepare(session)
	session._ghost_board = [null, null, null, null, null, null, null]
	var ghost: Dictionary = FieldRivals.side(session, Matchmaking.GHOST)
	assert_eq(FightCapture.canonical(ghost), FightCapture.canonical(session._field.frames[-1]))
	assert_eq(session._field.source_rounds[-1], 3)
	assert_ne(FightCapture.canonical(ghost["board"]), FightCapture.canonical(session._ghost_board))
	var scout: Dictionary = session._scout_of(-1)
	assert_eq(scout["specs"], FieldRivals._public_board(round_two["board"]))
	assert_eq(scout["slots"], round_two["slots"])
	assert_eq(scout["hero_effects"], ghost["hero_effects"], "hero identity remains public")
	assert_eq(scout["rules"].keys(), ["back_row_first"], "no hidden Larder or ammo disclosure")
	_observed.clear()
	session.fight_capture_observer = _remember
	session._fight(0, -1, 0)
	assert_eq(_observed[0]["input"]["boards"][1], ghost["board"])


func test_loader_rejects_versions_content_config_and_malformed_rounds() -> void:
	var field := FieldLibrary.read(FieldTestData.path(), _library)
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
	assert_eq(FieldLibrary.configure(config, _library, FieldTestData.path()), "")
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
	field._eligible = field.library.eligible(session._lobby_tribes, "top4")
	field._advance(1, 2)
	assert_eq(field.seats[1]["source_line"], "successor")
	assert_eq(field.source_rounds[1], 2)
	field._advance(1, 3)
	assert_eq(field.source_rounds[1], 2, "terminal field is labelled with its actual source round")
	assert_eq(field.seats[1]["trajectory"]["id"], "same-tribe")


func test_launcher_adopts_lever_config_and_loader_accepts_its_overlay_cards() -> void:
	var field := FieldLibrary.read(FieldTestData.path(), _library)
	field.data["config"]["scale_levers"] = ["scale_engine"]
	field.data["config"]["card_size_caps"] = false
	var lever_library := UnitLibrary.load_dir("res://content/levers")
	var spec: Dictionary = (
		RecruitUnit.make(lever_library.get_unit("scale_engine"), 2001).combat_spec()
	)
	var lines: Dictionary = field.data["lines"]
	for line: Dictionary in lines.values():
		for trajectory: Dictionary in line["trajectories"]:
			var frame: Dictionary = trajectory["rounds"]["1"]
			frame["board"][0] = spec.duplicate(true)
			frame.erase("views")
	var path: String = "res://build/strong-field-lever-test.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(field.data))
	file.close()
	var config := GameConfig.full_game()
	assert_eq(FieldLibrary.configure(config, _library, path), "")
	assert_false(config.get_bool("card_size_caps"))
	assert_eq(config.get_strings("scale_levers"), PackedStringArray(["scale_engine"]))
	config.set_value("human_bot", "hard")
	var session := GameSession.create(71, _library, config)
	assert_not_null(session)
	if session != null:
		assert_false(session._library.get_unit("scale_engine").is_empty())
		assert_eq(session._field.frames[1]["board"][0]["def_id"], "scale_engine")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_field_ghost_identity_and_hero_are_shown_without_naming_an_eliminated_seat() -> void:
	var session := _session()
	session._pairings = [[0, -1], [1, 2], [3, 4], [5, 6]]
	var state: Dictionary = session.get_state()
	var View := preload("res://src/ui/screens/recruit_view.gd")
	assert_eq(state["opponents"], "field")
	var UiTheme := preload("res://src/ui/ui_theme.gd")
	var standing: Dictionary = state["standings"][1]
	assert_string_contains(UiTheme.player_name(standing), "Rival 1")
	assert_string_contains(UiTheme.player_name(standing), str(standing["hero"]))
	assert_true(View.is_ghost_next(state))
	assert_eq(View.next_name(state), "Field ghost")
	assert_true(View.ghost_owner(state).is_empty())
	assert_not_null(state["next_opponent_hero"])
	var card: Dictionary = View.ghost_card(state)
	assert_eq(
		str(card["text"]),
		str(state["next_opponent_hero"]["text"]),
		"only the actual power text, without a generic ghost explanation"
	)
	assert_string_contains(str(card["text"]), str(state["next_opponent_hero"]["text"]))
	var lines: PackedStringArray = []
	session._round = 2
	session._field.prepare(session)
	session._players[0].scout = session._scout_of(-1)
	state = session.get_state()
	PlayView._scouted(state, lines)
	assert_string_contains("\n".join(lines), "Field ghost")
	assert_string_contains("\n".join(lines), "last board")
	assert_false("\n".join(lines).contains("last player out"))


func test_two_hundred_deals_use_eight_distinct_top_four_trajectories_in_lobby() -> void:
	var library := FieldLibrary.read(FieldTestData.path(), _library)
	assert_eq(library.error, "")
	for seed_value: int in range(1, 201):
		var session := GameSession.new()
		session._seed = seed_value
		session._config = GameConfig.full_game()
		session._library = _library
		session._lobby_tribes = session._draw_lobby_tribes()
		for id: int in 8:
			var player := PlayerState.new()
			player.id = id
			session._players.append(player)
		session._field = FieldRivals.new()
		session._field.library = library
		session._field.setup(session)
		var seen: Dictionary = {}
		for seat: Dictionary in session._field.seats.values():
			var trajectory: Dictionary = seat["trajectory"]
			assert_false(seen.has(trajectory["id"]), "independent ghost and unique rivals")
			seen[trajectory["id"]] = true
			assert_lte(CoreUtil.to_int(trajectory["finish_place"]), 4)
			for tribe: String in trajectory["lobby_tribes"]:
				assert_true(session._lobby_tribes.has(tribe))
		assert_eq(seen.size(), 8)


func test_switch_does_not_take_a_living_rival_or_ghost_trajectory() -> void:
	var session := _session()
	var field: FieldRivals = session._field
	var seat: Dictionary = field.seats[1]
	var initial: Dictionary = seat["trajectory"].duplicate(true)
	var frame: Dictionary = initial["rounds"]["1"]
	initial["id"] = "ended"
	initial["rounds"] = {"1": frame}
	seat["trajectory"] = initial
	var shared: Dictionary = initial.duplicate(true)
	shared["id"] = "a-owned-by-rival"
	shared["rounds"]["2"] = frame
	var available: Dictionary = shared.duplicate(true)
	available["id"] = "z-available"
	field.seats[2]["trajectory"] = shared
	field._eligible = [
		{"line": seat["line"], "trajectory": shared},
		{"line": seat["line"], "trajectory": available}
	]
	field._advance(1, 2)
	assert_eq(seat["trajectory"]["id"], "z-available")
	var ended_ghost: Dictionary = initial.duplicate(true)
	ended_ghost["id"] = "ghost-ended"
	field.seats[-1] = {"line": seat["line"], "source_line": seat["line"], "trajectory": ended_ghost}
	var ghost_only: Dictionary = shared.duplicate(true)
	ghost_only["id"] = "zz-ghost-only"
	field._eligible.append({"line": seat["line"], "trajectory": ghost_only})
	field._advance(-1, 2)
	assert_eq(field.seats[-1]["trajectory"]["id"], "zz-ghost-only")


func test_scout_strips_private_egg_fields_without_changing_fight_specs() -> void:
	var private_board: Array = [
		{
			"def_id": HeldUnits.EGG,
			"attack": 1,
			"health": 2,
			"bird_attack": 100,
			"bird_health": 200,
			"turns_left": 9
		}
	]
	var visible: Array = FieldRivals._public_board(private_board)
	assert_eq(visible[0], {"def_id": HeldUnits.EGG, "attack": 1, "health": 2})
	assert_eq(private_board[0]["bird_attack"], 100)
