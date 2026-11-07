extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/combat_kit.gd")


func test_last_stand_saves_from_two_and_five_once_with_armor_first() -> void:
	for health: int in [2, 5, 40]:
		var player := PlayerState.new()
		player.health = health
		player.armor = 3
		assert_false(HeroRules.take_combat_loss(player, 3, true))
		assert_eq(player.health, health)
		assert_false(player.last_stand_used)
		assert_true(HeroRules.take_combat_loss(player, health, true))
		assert_eq(player.health, 1)
		assert_eq(player.armor, 0)
		player.health = 5
		assert_false(HeroRules.take_combat_loss(player, 99, true))
		assert_lt(player.health, 1)


func test_ghost_and_one_health_never_spend_the_save() -> void:
	var player := PlayerState.new()
	player.health = 5
	assert_false(HeroRules.take_combat_loss(player, 20, false))
	assert_lt(player.health, 1)
	assert_false(player.last_stand_used)
	player.health = 1
	assert_false(HeroRules.take_combat_loss(player, 1, true))
	assert_eq(player.health, 0)
	assert_false(player.last_stand_used)


func test_four_left_lifts_cap_and_session_records_last_stand() -> void:
	var config := GameConfig.full_game()
	config.set_value("hero_choice", false)
	var session := GameSession.create(41001, UnitLibrary.load_dir(), config)
	for player: PlayerState in session._players:
		player.board.fill(null)
		player.health = 5
	assert_eq(session._damage_cap(), 4)
	for index: int in range(4, 8):
		session._players[index].alive = false
	assert_eq(session._damage_cap(), 0)
	var rules: RecruitRules = session.get_rules()
	session._players[1].board[0] = RecruitUnit.make(rules.library.get_unit("field_vole"), 900)
	session._players[1].tier = 6
	session._fight(0, 1, session._damage_cap())
	assert_eq(session._players[0].health, 1)
	assert_true(session._players[0].last_stand_used)
	var end: Dictionary = KIT.last(session.get_last_combat())
	assert_eq(end["last_stand_sides"], [0])
	assert_eq(end["alive"], 4)
	assert_eq(end["damage_cap"], 0)
	assert_eq(end["damage"], end["damage_base"] + end["round_toll"])


func test_engine_coverage_reports_unfired_rules_then_records_actual_events() -> void:
	var coverage := SoakCoverage.new()
	assert_eq(
		coverage.engines_silent(), PackedStringArray(["harvest_supper", "last_four", "last_stand"])
	)
	coverage.note_recruit("", "cast", {"card": "harvest_supper"})
	coverage.note_fight(
		[{"type": "combat_end", "alive": 4, "damage_cap": 0, "last_stand_sides": [0]}], ["", ""]
	)
	assert_eq(coverage.engines_silent(), PackedStringArray())
	assert_eq(coverage.engine_counts()["last_stand"], 1)
