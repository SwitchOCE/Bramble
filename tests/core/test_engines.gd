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
		coverage.engines_silent(),
		PackedStringArray(["harvest_supper", "last_four", "last_stand", "last_blow"])
	)
	coverage.note_recruit("", "cast", {"card": "harvest_supper"})
	coverage.note_fight(
		[
			{
				"type": "combat_end",
				"alive": 4,
				"damage_cap": 0,
				"last_stand_sides": [0],
				"last_blow": true
			}
		],
		["", ""]
	)
	assert_eq(coverage.engines_silent(), PackedStringArray())
	assert_eq(coverage.engine_counts()["last_stand"], 1)


func test_last_blow_credits_exchange_attacker_and_has_a_four_damage_floor() -> void:
	for seed_now: int in range(1, 9):
		var result: Dictionary = KIT.run(
			KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.plain(3, 3)}), seed_now
		)
		var start: Dictionary = KIT.events(result)[0]
		assert_eq(result["winner"], start["first_side"])
		assert_true(result["last_blow"])
		assert_eq(result["damage"], 4)


func test_last_blow_credits_possets_death_effect_instead_of_declared_attacker() -> void:
	var combat := Combat.create(KIT.library, GameConfig.full_game(), RandomNumberGenerator.new())
	combat._setup([KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.u("mrs_posset", 0, 1)})])
	combat._attacks_started = true
	combat._perform_attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	var result: Dictionary = combat._finish(Combat.REASON_BOARD_EMPTY, [6, 5], 0)
	assert_eq(result["winner"], 1)
	assert_eq(result["damage"], 5)
	assert_eq(KIT.last(result)["last_blow_kind"], Hit.EFFECT)
	assert_eq(KIT.last(result)["last_blow_source"], 2)


func test_bitter_is_attack_loss_and_cannot_steal_last_blow() -> void:
	var result: Dictionary = KIT.run(
		KIT.board({0: KIT.plain(1, 1)}), KIT.board({0: KIT.u("peatling", 1, 1)})
	)
	assert_true(result["last_blow"])
	assert_eq(result["winner"], KIT.events(result)[0]["first_side"])
	assert_eq(KIT.last(result)["last_blow_kind"], Hit.ATTACK)


func test_start_of_combat_wipe_stays_a_tie_even_after_lethal_effect_damage() -> void:
	var combat := Combat.create(KIT.library, GameConfig.full_game(), RandomNumberGenerator.new())
	combat._setup([KIT.board({0: KIT.plain(1, 1)}), KIT.board({0: KIT.plain(1, 1)})])
	var left: CombatUnit = combat.unit_at(0, 0)
	var right: CombatUnit = combat.unit_at(1, 0)
	combat.deal_effect_damage(left, right, 1)
	combat.deal_effect_damage(right, left, 1)
	combat._resolve_deaths(0)
	var result: Dictionary = combat._finish(Combat.REASON_BOARD_EMPTY, [6, 6], 0)
	assert_eq(result["winner"], -1)
	assert_false(result["last_blow"])


func test_nonlethal_effect_does_not_steal_last_blow_or_safety_limit_win() -> void:
	var combat := Combat.create(KIT.library, GameConfig.full_game(), RandomNumberGenerator.new())
	combat._setup([KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.plain(3, 3)})])
	combat._attacks_started = true
	combat._perform_attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	var result: Dictionary = combat._finish(Combat.REASON_TRIGGER_LIMIT, [6, 6], 0)
	assert_eq(result["winner"], -1)
	assert_false(result["last_blow"])


func test_last_blow_uses_a_swapped_effect_owners_fighting_side() -> void:
	var combat := Combat.create(KIT.library, GameConfig.full_game(), RandomNumberGenerator.new())
	combat._setup([KIT.board({0: KIT.u("mrs_posset", 0, 1)}), KIT.board({0: KIT.plain(3, 3)})])
	CombatMoves.trade_sides(combat, combat.unit_at(0, 0), combat.unit_at(1, 0))
	combat._attacks_started = true
	combat._perform_attack(combat.unit_at(0, 0), combat.unit_at(1, 0))
	var result: Dictionary = combat._finish(Combat.REASON_BOARD_EMPTY, [6, 5], 0)
	assert_eq(result["winner"], 1)
	assert_eq(KIT.last(result)["last_blow_source"], 1)
