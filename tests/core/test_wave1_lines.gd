extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const Kit := preload("res://tests/core/recruit_kit.gd")
const NAMES: Array[String] = ["birds_homecoming", "birds_tempo", "fairies_ring", "fairies_court"]


func before_each() -> void:
	BenchSuites.reload_lines(LinePolicies.DEFAULT_PATH)


func after_each() -> void:
	BenchSuites.reload_lines(LinePolicies.DEFAULT_PATH)


func test_wave1_files_validate_and_normalize_every_operational_field() -> void:
	for file: String in ["birds", "fairies"]:
		var table: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://tools/sim/lines/%s.json" % file)
		)
		assert_eq(LinePolicies.validate_wave1(table).size(), 0, file)
		for line_name: String in table:
			var source: Dictionary = table[line_name]
			var profile: Dictionary = LinePolicies.profiles()["line_" + line_name]
			assert_eq(profile["source_policy"], source, "retain advisory prose verbatim")
			assert_eq(profile["priority"], source.get("buy_priority", source.get("priority")))
			assert_eq(profile["engine"], source["engine_flag"])
			for tier: int in range(2, 7):
				assert_eq(profile["climb_schedule"][tier - 2], source["climb"]["T%d" % tier])
			var brain: LineBrain = BenchSuites.create_bot(line_name)
			assert_true(brain is CommittedLineBrain)
			assert_eq(brain.build_name(), "line_" + line_name)
			assert_false(brain.level.scouts)
			assert_eq(brain.level.place, BotLevel.PLACE_RULE)


func test_schema_rejects_bad_cards_rounds_types_and_switch_targets() -> void:
	var table: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tools/sim/lines/birds.json")
	)
	var source: Dictionary = table["birds_tempo"]
	source["buy_priority"] = ["not_a_card"]
	source["engine_flag"] = "false"
	source["climb"]["T3"] = 1
	source["switch_to"]["line"] = "missing"
	var errors: PackedStringArray = LinePolicies.validate_wave1(table)
	assert_eq(errors.size(), 4)
	assert_false(LinePolicies.validate_wave1([]).is_empty())


func test_each_wave1_line_plays_a_short_real_lobby_without_falling_back() -> void:
	for index: int in NAMES.size():
		var line_name: String = NAMES[index]
		var config := GameConfig.full_game()
		config.set_value("tribes_per_lobby", 0)
		config.set_value("human_bot", line_name)
		config.set_value(
			"bots", [line_name, line_name, line_name, line_name, line_name, line_name, line_name]
		)
		config.set_value("max_rounds", 3)
		var session := GameSession.create(
			180001 + index, UnitLibrary.load_dir(), config, BenchSuites.create_bot
		)
		assert_true(session._config.get_bool("pass3_content"))
		while not session.is_over():
			session.end_turn()
		for player: PlayerState in session._players:
			assert_eq(session.build_of(player.id), "line_" + line_name)
			assert_true(player.pass3_content)
			assert_gt(player.board_count() + player.away.size(), 0)
		assert_eq(session.get_game_log()["players"].size(), 8)


func test_tempo_switch_uses_homecoming_profile_at_declared_round() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var brain: LineBrain = BenchSuites.create_bot("birds_tempo")
	brain.play_turn(kit.player, kit.rules, 7)
	assert_eq(brain.build_name(), "line_birds_homecoming")
	assert_true(brain.profile["engine"])
	assert_eq(brain.profile["fly_policy"]["keep_home_min"], 3.0)


func test_written_flight_limits_apply_and_do_not_change_ordinary_hard() -> void:
	var kit := Kit.new()
	kit.setup(GameConfig.full_game())
	var brain: LineBrain = BenchSuites.create_bot("birds_tempo")
	kit.player.pass3_content = true
	for id: String in ["one_swallow", "chiffchaff", "mrs_jay", "mr_redbreast", "cuckoo"]:
		var bird: RecruitUnit = kit.put(id, kit.player.board_count())
		bird.played_round = 1
	kit.player.round_number = 4
	brain.value.library = kit.library
	brain.value.recruit_rules = kit.rules
	assert_eq(BotPass3.best_flight(kit.player, brain.value, 3), -1, "starts at round four")
	kit.player.board[4] = null
	assert_eq(BotPass3.best_flight(kit.player, brain.value, 4), -1, "keeps four home")
	assert_eq(brain.value.strategy["line_fly_policy"]["allowed"], ["chiffchaff", "one_swallow"])
	assert_false(BotKnowledge.shared().strategy("birds_highway").has("line_fly_policy"))


func test_historical_table_opt_out_still_uses_frozen_profile_data() -> void:
	BenchSuites.reload_lines(LinePolicies.HISTORICAL_PATH)
	assert_true(LinePolicies.profiles().has("line_birds_engine"))
	assert_false(LinePolicies.profiles().has("line_birds_homecoming"))
	var brain: LineBrain = BenchSuites.create_bot("line_birds_engine")
	assert_eq(brain.build_name(), "line_birds_engine")
	assert_eq(brain.profile["climb_schedule"], [4.0, 6.0, 8.0, 10.0, 12.0])


func test_accounting_roster_keeps_all_four_written_lines_and_four_blind_hard_seats() -> void:
	var names: PackedStringArray = BenchSuites.seats("wave1_accounting", 1900001)
	assert_eq(names, BenchSuites.seats("wave1_accounting", 1900001))
	assert_true(BenchSuites.is_known("wave1_accounting"))
	assert_eq(names.size(), 8)
	for line_name: String in NAMES:
		assert_eq(names.count("line_" + line_name), 1)
	assert_eq(names.count("hard_field:varied"), 4)
