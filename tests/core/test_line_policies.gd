extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")


func test_every_tribe_has_two_registered_profiles_and_every_priority_is_a_real_card() -> void:
	var library := TestLibraries.current()
	var counts: Dictionary = {}
	for id: String in LinePolicies.profiles():
		var entry: Dictionary = LinePolicies.profiles()[id]
		assert_true(BenchSuites.REGISTRY.has(id))
		var tribe: String = str(entry["tribe"])
		counts[tribe] = CoreUtil.to_int(counts.get(tribe, 0)) + 1
		for card: String in entry["priority"]:
			assert_false(library.get_unit(card).is_empty(), card)
		var brain: Bot = BenchSuites.create_bot(id)
		assert_true(brain is LineBrain)
		assert_eq(brain.build_name(), id)
	for tribe: String in ["Birds", "Bog folk", "Fairies", "Hedgerow folk", "Hunters", "Oozes"]:
		assert_eq(counts[tribe], 2, tribe)
	assert_eq(counts[""], 1, "shared fast-tier economy line")


func test_profile_changes_do_not_mutate_hard_knowledge() -> void:
	var known: Dictionary = BotKnowledge.shared().strategy("hedgerow_treasury")
	var before: String = JSON.stringify(known)
	var brain: LineBrain = BenchSuites.create_bot("line_hedgerow_engine")
	brain.value.strategy["units"]["squire_lollop"] = 999
	brain.profile["save_threshold"] = 999
	assert_eq(JSON.stringify(known), before)
	assert_eq(LinePolicies.profiles()["line_hedgerow_engine"]["save_threshold"], 2.0)
	assert_eq(brain._target_round(4), 10, "fixed declared climb schedule")


func test_lobby_deal_resolves_lines_to_available_tribes() -> void:
	var tribes: PackedStringArray = ["Birds", "Fairies", "Hunters", "Bog folk", "Oozes"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 81
	var names: PackedStringArray = BotLobby.resolve(BenchSuites.seats("lines", 9), tribes, rng)
	assert_eq(names.size(), 8)
	for bot_name: String in names:
		var brain: BotBrain = BenchSuites.create_bot(bot_name)
		if not brain is LineBrain:
			assert_eq(brain.get_script(), preload("res://tools/sim/field_hard.gd"))
			continue
		var line_brain: LineBrain = brain
		var tribe: String = str(line_brain.profile["tribe"])
		assert_true(tribe == "" or tribes.has(tribe))
		assert_eq(brain.level.place, BotLevel.PLACE_RULE, "blind placer layout")
		assert_false(brain.level.scouts, "does not adapt to a field opponent")


func test_line_lobby_has_real_heroes_pool_damage_and_eliminations() -> void:
	var names: PackedStringArray = BenchSuites.seats("lines", 81)
	var config := GameConfig.full_game()
	config.set_value("human_bot", names[0])
	config.set_value("bots", Array(names.slice(1)))
	var session := GameSession.create(81, TestLibraries.current(), config, BenchSuites.create_bot)
	while not session.is_over():
		session.end_turn()
	var rows: Array = session.get_game_log()["players"]
	var placements: Array = []
	for row: Dictionary in rows:
		assert_false(str(row["hero"]).is_empty())
		var seat: int = CoreUtil.to_int(row["player_id"])
		assert_true(
			session.build_of(seat).begins_with("line_") or names[seat].begins_with("hard_field")
		)
		placements.append(row["placement"])
	placements.sort()
	assert_eq(placements, [1, 2, 3, 4, 5, 6, 7, 8])


func test_short_all_line_lobby_with_both_caps_disabled() -> void:
	var names: PackedStringArray = BenchSuites.seats("lines", 140001)
	var config := GameConfig.full_game()
	config.set_value("human_bot", names[0])
	config.set_value("bots", Array(names.slice(1)))
	config.set_value("card_size_caps", false)
	config.set_value("card_rate_limits", false)
	config.set_value("max_rounds", 8)
	var session := GameSession.create(
		140001, TestLibraries.current(), config, BenchSuites.create_bot
	)
	for player: PlayerState in session._players:
		for entry: Array in [[1, "charcoal_burner"], [4, "field_vole"], [5, "field_vole"]]:
			player.board[entry[0]] = RecruitUnit.make(
				session._library.get_unit(entry[1]), session._rules.new_iid()
			)
		assert_gt(BotBurner.forecast(player, 101), 24.0)
	while not session.is_over():
		session.end_turn()
	var rows: Array = session.get_game_log()["players"]
	assert_eq(rows.size(), 8, "all line seats complete real capped-length play")
	for row: Dictionary in rows:
		assert_between(CoreUtil.to_int(row["placement"]), 1, 8)
