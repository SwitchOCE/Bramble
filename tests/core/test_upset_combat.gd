extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const CombatKit = preload("res://tests/core/combat_kit.gd")


func _fight_input(a: Array, b: Array, seed_value: int = 1) -> Dictionary:
	var config := GameConfig.defaults()
	config.set_value("scale_levers", ["scale_answer", "scale_biggest_answer"])
	config.set_value("card_size_caps", false)
	var values: Dictionary = config._values.duplicate(true)
	var side: Dictionary = {
		"round": 10,
		"layout": "blind",
		"config": values,
		"board": a,
		"slots": [[], [], [], [], [], [], []],
		"hero_effects": [],
		"fight_rules": {},
		"tier": 3,
	}
	var other: Dictionary = side.duplicate(true)
	other["board"] = b
	return FieldCombat.pair_input(side, other, seed_value)


func _winner(run: Dictionary) -> int:
	var result: Dictionary = run["result"]
	return CoreUtil.to_int(result["winner"])


func _entry() -> Dictionary:
	return {
		"id": "effect",
		"trigger": "start_of_combat",
		"do":
		{
			"effect": "stat_fraction",
			"target": {"select": "enemies", "pick": "biggest"},
			"operation": "reduce",
			"numerator": 50,
			"denominator": 100
		},
	}


func test_direct_baseline_exactly_matches_capture_replay_and_does_not_mutate_fight_input() -> void:
	var input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.u("scale_answer", 4, 4)}),
		CombatKit.board({0: CombatKit.plain(6, 6)})
	)
	input["boards"][0][0]["held"] = [CombatKit.plain(1, 2)]
	input["slots"][0][0] = [{"name": "Ring", "attack": 1, "health": 2}]
	var source := UnitLibrary.load_dir()
	var prepared: Dictionary = UpsetCombat.prepare(input, source)
	var configured: UnitLibrary = prepared["intact_library"]
	var before: String = FightCapture.canonical(input)
	var expected: Dictionary = FightCapture.replay(input, source)
	var observed: Dictionary = UpsetCombat.run_input(input, configured, false, true)
	assert_eq(FightCapture.canonical(observed["result"]), FightCapture.canonical(expected))
	assert_eq(FightCapture.canonical(input), before)
	assert_true(prepared["supported"])
	var masked_library: UnitLibrary = prepared["library"]
	assert_eq(masked_library.get_unit("scale_answer")["mechanics"], [])
	assert_false(configured.get_unit("scale_answer")["mechanics"].is_empty())


func test_native_and_data_answer_positive_controls_and_oversized_negative_control() -> void:
	var source := UnitLibrary.load_dir()
	for id: String in ["scale_answer", "scale_biggest_answer"]:
		for seed_value: int in [1, 2, 19, 71]:
			var input: Dictionary = _fight_input(
				CombatKit.board({0: CombatKit.u(id, 4, 4)}),
				CombatKit.board({0: CombatKit.plain(6, 6)}),
				seed_value
			)
			var prepared: Dictionary = UpsetCombat.prepare(input, source)
			var intact: UnitLibrary = prepared["intact_library"]
			var masked: UnitLibrary = prepared["library"]
			var masked_input: Dictionary = prepared["input"]
			for flip: bool in [false, true]:
				assert_eq(_winner(UpsetCombat.run_input(input, intact, flip)), 0)
				assert_eq(_winner(UpsetCombat.run_input(masked_input, masked, flip)), 1)
	var big_input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.u("scale_answer", 20, 20)}),
		CombatKit.board({0: CombatKit.plain(6, 6)})
	)
	var big_prepared: Dictionary = UpsetCombat.prepare(big_input, source)
	var big_intact: UnitLibrary = big_prepared["intact_library"]
	var big_masked: UnitLibrary = big_prepared["library"]
	var big_masked_input: Dictionary = big_prepared["input"]
	assert_eq(_winner(UpsetCombat.run_input(big_input, big_intact)), 0)
	assert_eq(_winner(UpsetCombat.run_input(big_masked_input, big_masked)), 0)


func test_partial_effect_mask_preserves_other_buff_grants_held_and_slot_state() -> void:
	var answer: Dictionary = _entry()
	var buff: Dictionary = {
		"effect": "buff", "target": {"select": "self"}, "attack": 2, "health": 3
	}
	answer["do"] = [answer["do"], buff]
	var granted: Dictionary = {"entry": answer, "golden": false}
	var safe: Dictionary = {"entry": {"id": "bristle", "damage": 1}, "golden": false}
	var body: Dictionary = CombatKit.plain(4, 4)
	body["grants"] = [granted, safe]
	body["held"] = [CombatKit.plain(3, 5)]
	var input: Dictionary = _fight_input(
		CombatKit.board({0: body}), CombatKit.board({0: CombatKit.plain(6, 6)})
	)
	input["slots"][0][0] = [
		{"name": "Ring", "attack": 3, "health": 2}, {"entry": _entry(), "golden": false}
	]
	input["hero_effects"][1] = [_entry()]
	input["fight_rules"][0]["nests"] = [
		{
			"slot": 2,
			"spec": {"def_id": "field_vole", "grants": [{"entry": _entry(), "golden": false}]}
		}
	]
	var before: String = FightCapture.canonical(input)
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	var masked: Dictionary = prepared["input"]
	assert_true(prepared["supported"])
	assert_eq(masked["boards"][0][0]["grants"][0]["entry"]["do"], [buff])
	assert_eq(masked["boards"][0][0]["grants"][1], safe)
	assert_eq(masked["boards"][0][0]["held"], body["held"])
	assert_eq(masked["slots"][0][0], [{"name": "Ring", "attack": 3, "health": 2}])
	assert_eq(masked["hero_effects"][1], [])
	assert_eq(masked["fight_rules"][0]["nests"][0]["spec"]["grants"], [])
	assert_eq(FightCapture.canonical(input), before)


func test_stateful_bundled_and_unknown_native_masks_are_unsupported() -> void:
	var answer: Dictionary = _entry()
	answer["limit"] = 1
	answer["do"] = [answer["do"], {"effect": "buff", "attack": 1, "health": 1}]
	var input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.plain(4, 4)}), CombatKit.board({0: CombatKit.plain(6, 6)})
	)
	input["boards"][0][0]["grants"] = [
		{"entry": answer, "golden": false},
		{"entry": {"id": "unknown_future_native"}, "golden": false}
	]
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	assert_false(prepared["supported"])
	assert_eq(prepared["unsupported"].size(), 2)


func test_layout_is_board_local_moves_complete_specs_and_pins_eggs_and_nests() -> void:
	var egg: Dictionary = {"def_id": HeldUnits.EGG, "attack": 1, "health": 3}
	var body: Dictionary = CombatKit.plain(8, 4)
	body["held"] = [CombatKit.plain(7, 9)]
	body["grants"] = [{"entry": _entry(), "golden": false}]
	var board: Array = CombatKit.board({0: body, 1: egg, 4: CombatKit.plain(2, 9)})
	var rules: Dictionary = {"nests": [{"slot": 2, "spec": CombatKit.plain(3, 4)}]}
	var before: String = FightCapture.canonical([board, rules])
	var first: Dictionary = UpsetCombat.alternate_layout("frozen-board-7", board, rules)
	var second: Dictionary = UpsetCombat.alternate_layout("frozen-board-7", board, rules)
	assert_eq(first, second)
	assert_eq(first["pinned_slots"], [1, 2])
	assert_eq(first["old_to_new"][1], 1)
	assert_eq(first["old_to_new"][2], 2)
	assert_eq(first["board"][first["old_to_new"][0]], body)
	assert_eq(FightCapture.canonical([board, rules]), before)


func test_unequal_unit_counts_do_not_override_first_attack() -> void:
	var input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.plain(8, 8), 1: CombatKit.plain(1, 1)}),
		CombatKit.board({0: CombatKit.plain(2, 3)})
	)
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	var intact: UnitLibrary = prepared["intact_library"]
	var normal: Dictionary = UpsetCombat.run_input(input, intact, false, true)
	var flipped: Dictionary = UpsetCombat.run_input(input, intact, true, true)
	assert_false(flipped["first_coin_eligible"])
	assert_eq(normal, flipped)


func test_coin_override_preserves_start_of_combat_and_later_rng_when_no_attacks() -> void:
	var input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.plain(0, 5)}), CombatKit.board({0: CombatKit.plain(0, 5)})
	)
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	var intact: UnitLibrary = prepared["intact_library"]
	var normal: Dictionary = UpsetCombat.run_input(input, intact, false, true)
	var flipped: Dictionary = UpsetCombat.run_input(input, intact, true, true)
	assert_true(flipped["first_coin_eligible"])
	assert_eq(flipped["first_side_original"], normal["first_side_original"])
	assert_eq(flipped["first_side_used"], 1 - normal["first_side_used"])
	var a: Dictionary = normal["result"]
	var b: Dictionary = flipped["result"]
	var a_events: Array = a["events"]
	var b_events: Array = b["events"]
	a_events[0].erase("first_side")
	b_events[0].erase("first_side")
	assert_eq(FightCapture.canonical(a), FightCapture.canonical(b))


func test_lower_stat_win_without_declared_cause_is_not_answer_evidence() -> void:
	var input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.plain(1, 1)}), CombatKit.board({0: CombatKit.plain(0, 5)})
	)
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	var intact: UnitLibrary = prepared["intact_library"]
	var masked: UnitLibrary = prepared["library"]
	var masked_input: Dictionary = prepared["input"]
	assert_eq(_winner(UpsetCombat.run_input(input, intact)), 0)
	assert_eq(_winner(UpsetCombat.run_input(masked_input, masked)), 0)
	assert_eq(_winner(UpsetCombat.run_input(input, intact, true)), 0)


func test_pre_overlay_capture_defaults_replay_exactly() -> void:
	var input: Dictionary = _fight_input(
		CombatKit.board({0: CombatKit.plain(4, 4)}), CombatKit.board({0: CombatKit.plain(6, 6)})
	)
	for key: String in ["card_size_caps", "card_rate_limits", "scale_levers"]:
		input["config"].erase(key)
	var source := UnitLibrary.load_dir()
	var prepared: Dictionary = UpsetCombat.prepare(input, source)
	var configured: UnitLibrary = prepared["intact_library"]
	assert_eq(configured, source, "missing overlay keys keep inert defaults")
	var expected: Dictionary = FightCapture.replay(input, source)
	var observed: Dictionary = UpsetCombat.run_input(input, configured, false, true)
	assert_eq(FightCapture.canonical(observed["result"]), FightCapture.canonical(expected))


func test_held_and_borrowed_answer_grants_mask_identically() -> void:
	var source := UnitLibrary.load_dir()
	var config := GameConfig.defaults()
	config.set_value("scale_levers", ["scale_answer"])
	var configured: UnitLibrary = ScaleOverlay.library_for(source, config)
	var borrower := RecruitUnit.make(configured.get_unit("frumenty"), 51)
	borrower.held.append(RecruitUnit.make(configured.get_unit("scale_answer"), 52))
	var input: Dictionary = _fight_input(
		CombatKit.board({0: borrower.combat_spec()}), CombatKit.board({0: CombatKit.plain(6, 6)})
	)
	var prepared: Dictionary = UpsetCombat.prepare(input, source)
	var masked_input: Dictionary = prepared["input"]
	assert_false(input["boards"][0][0]["grants"].is_empty())
	assert_eq(masked_input["boards"][0][0]["grants"], [])
	assert_eq(masked_input["boards"][0][0]["held"], input["boards"][0][0]["held"])
	var private: UnitLibrary = prepared["library"]
	assert_eq(private.get_unit("scale_answer")["mechanics"], [])


func test_known_layout_intervention_reverses_winner_independent_of_first_coin() -> void:
	var a: Array = CombatKit.board({0: CombatKit.plain(8, 4), 4: CombatKit.plain(2, 9)})
	var b: Array = CombatKit.board({0: CombatKit.plain(4, 8), 4: CombatKit.plain(4, 3)})
	var alternative: Dictionary = UpsetCombat.alternate_layout("placement-fixture-7", a, {})
	assert_eq(alternative["old_to_new"][0], 4)
	assert_eq(alternative["old_to_new"][4], 0)
	var input: Dictionary = _fight_input(a, b, 1)
	var changed: Dictionary = input.duplicate(true)
	changed["boards"][0] = alternative["board"]
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	var intact: UnitLibrary = prepared["intact_library"]
	for flip: bool in [false, true]:
		var original: Dictionary = UpsetCombat.run_input(input, intact, flip)
		var moved: Dictionary = UpsetCombat.run_input(changed, intact, flip)
		assert_eq(_winner(original), 0)
		assert_eq(_winner(moved), 1)
		assert_eq(original["first_side_original"], moved["first_side_original"])
		assert_eq(original["first_side_used"], moved["first_side_used"])


func test_known_first_attack_coin_intervention_reverses_winner() -> void:
	var body: Array = CombatKit.board({0: CombatKit.plain(7, 7), 1: CombatKit.plain(1, 1)})
	var input: Dictionary = _fight_input(body, body.duplicate(true), 1)
	input["config"]["last_blow"] = false
	assert_eq(input["rng_state"], "-1966449618399012673")
	var prepared: Dictionary = UpsetCombat.prepare(input, UnitLibrary.load_dir())
	var intact: UnitLibrary = prepared["intact_library"]
	var normal: Dictionary = UpsetCombat.run_input(input, intact)
	var flipped: Dictionary = UpsetCombat.run_input(input, intact, true)
	assert_eq(_winner(normal), 1)
	assert_eq(_winner(flipped), 0)
	assert_true(normal["first_coin_eligible"])
	assert_eq(normal["first_side_original"], flipped["first_side_original"])
	assert_eq(normal["first_side_used"], 1 - flipped["first_side_used"])
