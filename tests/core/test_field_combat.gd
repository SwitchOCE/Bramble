extends GutTest
@warning_ignore_start("unsafe_call_argument")


func _side(input: Dictionary, side: int) -> Dictionary:
	return {
		"round": input["round"],
		"layout": "blind",
		"config": input["config"],
		"board": input["boards"][side],
		"slots": input["slots"][side],
		"hero_effects": input["hero_effects"][side],
		"fight_rules": input["fight_rules"][side],
		"tier": input["tiers"][side],
	}


func test_pre_lever_captures_keep_capped_defaults() -> void:
	var source := UnitLibrary.load_dir()
	var values: Dictionary = GameConfig.full_game()._values.duplicate(true)
	for key: String in ["card_size_caps", "card_rate_limits", "scale_levers"]:
		values.erase(key)
	assert_eq(FightCapture.library_for(values, source), source)
	var config: GameConfig = FightCapture.config_for(values)
	assert_true(config.get_bool("card_size_caps"))
	assert_true(config.get_bool("card_rate_limits"))


func test_composed_real_capture_preserves_hidden_state_and_raw_outcome() -> void:
	var library := UnitLibrary.load_dir()
	var session := GameSession.create(71, library)
	var a: PlayerState = session._players[0]
	var b: PlayerState = session._players[1]
	a.board[0] = RecruitUnit.make(library.get_unit("elder_ooze"), 91)
	a.board[0].held.append(RecruitUnit.make(library.get_unit("wood_mouse_guard"), 92))
	a.slot_effects[0] = [{"name": "Ring", "attack": 3, "health": 2}]
	HeroRules.assign(a, library.get_hero("brother_bracken"))
	b.board[0] = RecruitUnit.make(library.get_unit("bridge_toad"), 93)
	var captured: Array[Dictionary] = []
	session.fight_capture_observer = func(
		raw_input: Dictionary, raw_result: Dictionary, _combat: Combat
	) -> void:
		captured.append({"input": raw_input.duplicate(true), "result": raw_result.duplicate(true)})
	session._fight(0, 1, 0)
	var input: Dictionary = captured[0]["input"]
	var expected: Dictionary = captured[0]["result"]
	var left: Dictionary = _side(input, 0)
	var right: Dictionary = _side(input, 1)
	var before: String = FightCapture.canonical([left, right])
	var result: Dictionary = FieldCombat.fight(
		left, right, str(input["rng_seed"]).to_int(), session._library
	)
	expected.erase("events")
	result.erase("events")
	assert_eq(FightCapture.canonical(result), FightCapture.canonical(expected))
	assert_eq(FightCapture.canonical([left, right]), before, "field inputs are never mutated")
	var swapped: Dictionary = FieldCombat.pair_input(right, left, 19)
	assert_eq(swapped["hero_effects"], [right["hero_effects"], left["hero_effects"]])
	assert_eq(swapped["fight_rules"], [right["fight_rules"], left["fight_rules"]])


func test_caps_off_session_library_survives_capture_field_and_exact_refight() -> void:
	var source := UnitLibrary.load_dir()
	var config := GameConfig.defaults()
	config.set_value("card_size_caps", false)
	config.set_value("scale_levers", ["scale_engine"])
	var session := GameSession.create(871, source, config)
	var library: UnitLibrary = session._library
	assert_ne(library, source)
	assert_false(library.get_unit("bridge_toad").has("permanent_buff_cap"))
	assert_false(library.get_unit("scale_engine").is_empty())
	var a: PlayerState = session._players[0]
	var b: PlayerState = session._players[1]
	a.board[0] = RecruitUnit.make(library.get_unit("bridge_toad"), 91)
	a.board[0].add_permanent(20, 20)
	b.board[0] = RecruitUnit.make(library.get_unit("wood_mouse_guard"), 92)
	var captured: Array[Dictionary] = []
	session.fight_capture_observer = func(
		raw_input: Dictionary, raw_result: Dictionary, combat: Combat
	) -> void:
		captured.append(FightCapture.record(raw_input, raw_result, library, combat))
	session._fight(0, 1, 0)
	var recorded: Dictionary = JSON.parse_string(JSON.stringify(captured[0]))
	var input: Dictionary = recorded["input"]
	assert_eq(CoreUtil.to_int(recorded["combat_start"][0]["units"][0]["attack"]), 21)
	var direct: Dictionary = FightCapture.replay(input, library)
	assert_true(FightCapture.matches(recorded, direct), "exact replay uses the session overlay")
	var restored: UnitLibrary = FightCapture.library_for(input["config"], source)
	assert_eq(
		FightCapture.library_for(input["config"], restored), restored, "one overlay per config"
	)
	assert_true(FightCapture.matches(recorded, FightCapture.replay(input, restored)))
	assert_true(FightCapture.matches(recorded, FightCapture.replay(input, source)))
	var result: Dictionary = FieldCombat.fight(
		_side(input, 0), _side(input, 1), str(input["rng_seed"]).to_int(), restored
	)
	direct.erase("events")
	result.erase("events")
	assert_eq(FightCapture.canonical(result), FightCapture.canonical(direct))
	var capped := CombatUnit.make(source.get_unit("bridge_toad"), input["boards"][0][0], 1, 0)
	assert_eq(
		capped.attack, 4, "negative control: base library silently caps the same 21 attack spec"
	)
	assert_eq(CoreUtil.to_int(source.get_unit("bridge_toad")["permanent_buff_cap"]), 3)
