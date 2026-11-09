extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

var _library: UnitLibrary = UnitLibrary.load_dir()
var _records: Array[Dictionary] = []


func _capture(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	var recorded: Dictionary = FightCapture.record(input, result, _library, combat)
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(recorded))
	var replayed: Dictionary = FightCapture.replay(decoded["input"], _library)
	assert_true(FightCapture.matches(decoded, replayed), "all outcome fields and every event match")
	_records.append(decoded)


func _session(mode: String) -> GameSession:
	var config := GameConfig.full_game(mode)
	config.set_value("human_bot", "balanced")
	config.set_value("bots", ["balanced"])
	var session := GameSession.create(891, _library, config)
	session.fight_capture_observer = _capture
	session.combat_factory = CaptureCombat.instrument
	return session


func test_json_captures_reproduce_every_fight_in_a_real_lobby() -> void:
	_records.clear()
	var session := _session("v05")
	while not session.is_over():
		session.end_turn()
	assert_gt(_records.size(), 20, "real damage, heroes and eliminations")
	assert_true(
		_records.any(func(row: Dictionary) -> bool: return row["input"]["player_ids"].has(-1.0)),
		"includes ghosts through the same fight boundary"
	)


func test_slots_auras_eggs_bellies_away_birds_and_hero_effects_survive_capture() -> void:
	_records.clear()
	var session := _session("legacy")
	var a: PlayerState = session._players[0]
	var b: PlayerState = session._players[1]
	a.tier = 6
	b.tier = 5
	a.board[0] = RecruitUnit.make(_library.get_unit("redwing"), 101)
	a.board[2] = RecruitUnit.make(_library.get_unit("elder_ooze"), 102)
	var held := RecruitUnit.make(_library.get_unit("wood_mouse_guard"), 103)
	held.add_permanent(7, 9)
	a.board[2].held.append(held)
	var bird := RecruitUnit.make(_library.get_unit("mother_goose"), 104)
	a.away.append({"unit": bird, "nest": 1, "left": 1, "due": 20})
	a.slot_effects[1] = [{"name": "Ring", "attack": 9, "health": 7}]
	HeroRules.assign(a, _library.get_hero("brother_bracken"))
	b.board[0] = RecruitUnit.make(_library.get_unit("squire_lollop"), 201)
	b.board[1] = RecruitUnit.make(_library.get_unit("wood_mouse_guard"), 202)
	session._round = 8
	session._fight(0, 1, 7)
	assert_eq(_records.size(), 1)
	var before: Dictionary = _records[0]["combat_start"][1]["units"][0]
	var after: Dictionary = _records[0]["after_start_effects"][1]["units"][0]
	assert_eq(
		CoreUtil.to_int(after["attack"]),
		CoreUtil.to_int(before["attack"]) + 1,
		"Lollop start effect is captured"
	)
	var recorded: Dictionary = _records[0]
	var input: Dictionary = recorded["input"]
	assert_false(input["hero_effects"][0].is_empty())
	assert_eq(input["tiers"], [6.0, 5.0])
	assert_eq(CoreUtil.to_int(input["fight_rules"][0]["goose"]), HeldUnits.goose_strikes(a))
	var snapshot: Dictionary = recorded["combat_start"][0]
	var units: Array = snapshot["units"]
	var eggs: Array = units.filter(func(unit: Dictionary) -> bool: return unit["location"] == "egg")
	assert_eq(eggs.size(), 1)
	assert_gt(eggs[0]["attack"], input["boards"][0][1]["attack"], "Ring and Redwing after auras")
	assert_eq(units.filter(func(u: Dictionary) -> bool: return u["location"] == "belly").size(), 1)
	assert_eq(units.filter(func(u: Dictionary) -> bool: return u["location"] == "away").size(), 1)
	assert_between(float(snapshot["largest_share"]), 0.0, 1.0)
	assert_false(recorded["survivors"].is_empty(), "surviving fighters logged for damage replay")


func test_capture_is_detached_and_rng_state_is_lossless() -> void:
	_records.clear()
	var session := _session("v05")
	session.end_turn()
	var recorded: Dictionary = _records[0]
	assert_typeof(recorded["input"]["rng_state"], TYPE_STRING)
	assert_typeof(recorded["input"]["effect_rng_state"], TYPE_STRING)
	var original: String = FightCapture.canonical(recorded)
	session.end_turn()
	assert_eq(
		FightCapture.canonical(recorded), original, "subsequent recruit phases cannot mutate it"
	)
	var replayed: Dictionary = FightCapture.replay(recorded["input"], _library)
	assert_true(FightCapture.matches(recorded, replayed))
	recorded["events_sha256"] = "tampered"
	assert_false(FightCapture.matches(recorded, replayed), "event verification is enforced")


func test_default_json_roundtrip_preserves_thirds_and_explicit_rate_overrides() -> void:
	var config := GameConfig.full_game()
	var raw_values: Dictionary = JSON.parse_string(JSON.stringify(config.resolved_values()))
	var raw_restored: GameConfig = FightCapture.config_for(raw_values)
	for key: String in Pass3Rates.resolved(config):
		assert_eq(
			Pass3Rates.value(raw_restored, key),
			Pass3Rates.value(config, key),
			"raw observer: " + key
		)
	var session := GameSession.create(913, _library, config)
	var library: UnitLibrary = session._library
	var a: PlayerState = session._players[0]
	var b: PlayerState = session._players[1]
	a.board[0] = RecruitUnit.make(library.get_unit("field_vole"), 9101)
	a.board[0].add_permanent(99, 99)
	a.board[1] = RecruitUnit.make(library.get_unit("wick"), 9102)
	b.board[0] = RecruitUnit.make(library.get_unit("field_vole"), 9201)
	b.board[0].add_permanent(10, 9)
	var captures: Array[Dictionary] = []
	session.fight_capture_observer = func(
		capture_input: Dictionary, capture_result: Dictionary, capture_combat: Combat
	) -> void:
		captures.append(FightCapture.record(capture_input, capture_result, library, capture_combat))
	session._fight(0, 1, 0)
	var original: Dictionary = captures[0]
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(original))
	var input: Dictionary = decoded["input"]
	var values: Dictionary = input["config"]
	var restored: GameConfig = FightCapture.config_for(values)
	for key: String in Pass3Rates.resolved(config):
		assert_eq(Pass3Rates.value(restored, key), Pass3Rates.value(config, key), key)
	assert_eq(
		restored.get_value("pass3_text_defaults"), config.resolved_values()["pass3_text_defaults"]
	)
	assert_true(FightCapture.matches(decoded, FightCapture.replay(input, UnitLibrary.load_dir())))
	var combat := Combat.create(library, restored, RandomNumberGenerator.new())
	assert_eq(
		Pass3HunterCombat.shares(
			combat, {"attack": 12, "health": 12}, Pass3Rates.number(restored, "hunters_wick_share")
		),
		Vector2i(4, 4)
	)
	var unfrozen: Dictionary = input.duplicate(true)
	var unfrozen_values: Dictionary = unfrozen["config"]
	unfrozen_values.erase(Pass3Rates.EXACT_RATES)
	var rounded: GameConfig = FightCapture.config_for(unfrozen_values)
	combat.config = rounded
	assert_eq(
		Pass3HunterCombat.shares(
			combat, {"attack": 12, "health": 12}, Pass3Rates.number(rounded, "hunters_wick_share")
		),
		Vector2i(3, 3),
		"negative control exposes default JSON rounding"
	)
	assert_false(
		FightCapture.matches(decoded, FightCapture.replay(unfrozen, UnitLibrary.load_dir()))
	)
	values["hunters_wick_share"] = 0.25
	var overridden: GameConfig = FightCapture.config_for(values)
	assert_eq(
		Pass3Rates.number(overridden, "hunters_wick_share"), 0.25, "explicit harness override wins"
	)
	assert_eq(
		Pass3Rates.number(overridden, "hunters_grizel_share"),
		Pass3Rates.number(config, "hunters_grizel_share"),
		"unmodified rates retain captured precision"
	)

	var baseline: Dictionary = values["pass3_text_defaults"]
	baseline["hunters_wick_share"] = 0.25
	var baseline_override: Dictionary = FightCapture.config_for(values).get_value(
		"pass3_text_defaults"
	)
	assert_eq(
		baseline_override["hunters_wick_share"], 0.25, "explicit comparison baseline override wins"
	)
