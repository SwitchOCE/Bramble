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
	var source: UnitLibrary = LegacyBog.library()
	var values: Dictionary = GameConfig.full_game()._values.duplicate(true)
	for key: String in ["card_size_caps", "card_rate_limits", "scale_levers"]:
		values.erase(key)
	var before: String = FightCapture.canonical(source.all_units())
	var configured: UnitLibrary = FightCapture.library_for(values, source)
	assert_ne(configured, source, "pass 3 owns a private configured library")
	assert_eq(FightCapture.library_for(values, configured), configured, "reuse matching overlay")
	var card: Dictionary = configured.get_unit("bridge_toad")
	assert_eq(CoreUtil.to_int(card["permanent_buff_cap"]), 3)
	MechanicRegistry.compiled(card)
	assert_true(card.has(MechanicRegistry.COMPILED_KEY), "configured cards own their cache")
	assert_false(source.get_unit("bridge_toad").has(MechanicRegistry.COMPILED_KEY))
	assert_eq(FightCapture.canonical(source.all_units()), before, "source stays unchanged")
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
	var source: UnitLibrary = LegacyBog.library()
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


func test_real_capture_freezes_rates_against_defaults_and_preset_drift() -> void:
	var defaults: Dictionary = Pass3Rates.defaults()
	var presets: Dictionary = Pass3Rates._presets.duplicate(true)
	var default_preset: String = Pass3Rates._default_preset
	var cases: Array[Dictionary] = []
	for preset: String in ["B", "C"]:
		for golden: bool in [false, true]:
			var source := UnitLibrary.load_dir()
			var config := GameConfig.full_game()
			config.set_value("pass3_preset", preset)
			config.set_value("fairies_ring_growth", 0.75)
			var session := GameSession.create(903, source, config)
			var library: UnitLibrary = session._library
			var a: PlayerState = session._players[0]
			var b: PlayerState = session._players[1]
			a.board[0] = RecruitUnit.make(library.get_unit("cradle_fetch"), 91, golden)
			a.board[4] = RecruitUnit.make(library.get_unit("hedge_witch"), 92)
			a.board[4].add_permanent(99, 117)
			b.board[0] = RecruitUnit.make(library.get_unit("wood_mouse_guard"), 93)
			var captured: Array[Dictionary] = []
			session.fight_capture_observer = func(
				raw_input: Dictionary, raw_result: Dictionary, combat: Combat
			) -> void:
				var events: Array = raw_result["events"]
				(
					captured
					. append(
						{
							"recorded": FightCapture.record(raw_input, raw_result, library, combat),
							"events": events.duplicate(true),
						}
					)
				)
			session._fight(0, 1, 0)
			var case: Dictionary = JSON.parse_string(JSON.stringify(captured[0]))
			var input: Dictionary = case["recorded"]["input"]
			var share: float = 1.0 if preset == "B" else 2.0
			assert_eq(input["config"]["fairies_fetch_share"], share)
			assert_eq(input["config"]["fairies_ring_growth"], 0.75, "explicit override wins")
			assert_eq(
				CoreUtil.to_int(input["config"]["scale_hero_spell_percent"]),
				10 if preset == "B" else 20
			)
			assert_eq(input["config"]["scale_hero_spell_stats"], true, "freeze nullable auto")
			assert_true(
				FightCapture.matches(
					case["recorded"], FightCapture.replay(input, UnitLibrary.load_dir())
				)
			)
			case["label"] = "%s golden=%s" % [preset, golden]
			cases.append(case)
	# Simulate future rates.json edits, including an edited existing preset and default choice.
	Pass3Rates._defaults["fairies_fetch_share"] = 0.25
	Pass3Rates._defaults["scale_hero_spell_percent"] = 70
	Pass3Rates._presets["C"]["fairies_fetch_share"] = 0.5
	Pass3Rates._presets["C"]["scale_hero_spell_percent"] = 80
	Pass3Rates._default_preset = "A"
	for case: Dictionary in cases:
		var recorded: Dictionary = case["recorded"]
		var input: Dictionary = recorded["input"]
		var label: String = case["label"]
		var fresh: UnitLibrary = UnitLibrary.load_dir()
		var replayed: Dictionary = FightCapture.replay(input, fresh)
		assert_true(FightCapture.matches(recorded, replayed), label + " exact events after drift")
		var expected_events: Array = case["events"]
		var replayed_events: Array = replayed["events"]
		for index: int in mini(expected_events.size(), replayed_events.size()):
			if (
				FightCapture.canonical(expected_events[index])
				!= FightCapture.canonical(replayed_events[index])
			):
				assert_eq(
					FightCapture.canonical(replayed_events[index]),
					FightCapture.canonical(expected_events[index]),
					label + " first divergent event %d" % index
				)
				break
		var restored: UnitLibrary = FightCapture.library_for(input["config"], fresh)
		var words: String = (
			"full stats" if input["config"]["pass3_preset"] == "B" else "double stats"
		)
		assert_string_contains(restored.get_unit("cradle_fetch")["text"], words)
		var percent: int = CoreUtil.to_int(input["config"]["scale_hero_spell_percent"])
		assert_string_contains(restored.get_card("harvest_supper")["details"], "%d%%" % percent)
		var unfrozen: Dictionary = input.duplicate(true)
		var unfrozen_values: Dictionary = unfrozen["config"]
		for key: String in defaults:
			unfrozen_values.erase(key)
		unfrozen_values["scale_hero_spell_stats"] = null
		assert_false(
			FightCapture.matches(recorded, FightCapture.replay(unfrozen, UnitLibrary.load_dir())),
			label + " negative control: a preset name alone drifts"
		)
	Pass3Rates._defaults = defaults
	Pass3Rates._presets = presets
	Pass3Rates._default_preset = default_preset
