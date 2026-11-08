extends GutTest
## v0.5 counts original fighters, rather than the bodies or tiers a combat effect produces.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/combat_kit.gd")


func _config() -> GameConfig:
	var config := GameConfig.defaults()
	config.set_value("damage_mode", "v05")
	config.set_value("base_damage_by_turn", [1, 3, 6])
	config.set_value("last_blow", true)
	return config


func _combat(boards: Array) -> Combat:
	var combat := Combat.create(KIT.library, _config(), RandomNumberGenerator.new())
	combat._setup(boards)
	return combat


func test_round_base_plus_starting_count_ignores_tiers_and_supplied_cap() -> void:
	for tier: int in [1, 6]:
		var combat := Combat.create(KIT.library, _config(), RandomNumberGenerator.new())
		combat.round_number = 2
		var result: Dictionary = combat.run(
			[KIT.board({0: KIT.plain(2, 2), 1: KIT.u("old_mother_mast")}), KIT.board({})],
			[tier, tier],
			[0, 1],
			1
		)
		assert_eq(result["damage_base"], 3)
		assert_eq(result["damage_performance"], 2)
		assert_eq(result["damage"], 5, "v0.5 has no cap, including a caller-supplied cap")
		assert_eq(KIT.last(result)["damage_performance"], 2)


func test_base_schedule_repeats_its_last_entry() -> void:
	var combat := Combat.create(KIT.library, _config(), RandomNumberGenerator.new())
	combat.round_number = 50
	var result: Dictionary = combat.run(
		[KIT.board({0: KIT.plain(2, 2)}), KIT.board({})], [1, 1], [0, 1], 0
	)
	assert_eq(result["damage_base"], 6)
	assert_eq(result["damage"], 7)


func test_golden_starting_unit_counts_once() -> void:
	var result: Dictionary = KIT.run(
		KIT.board({0: KIT.u("field_vole", 10, 10, true)}), KIT.board({}), 1, _config()
	)
	assert_eq(result["damage_performance"], 1)
	assert_eq(result["damage"], 2)


func test_start_of_combat_hero_summon_does_not_become_a_starting_unit() -> void:
	var combat := Combat.create(KIT.library, _config(), RandomNumberGenerator.new())
	combat.hero_effects = [
		[{"trigger": "start_of_combat", "do": {"effect": "summon", "unit": "field_vole"}}], []
	]
	var result: Dictionary = combat.run(
		[KIT.board({0: KIT.plain(2, 2)}), KIT.board({})], [1, 1], [0, 1], 0
	)
	assert_eq(combat.units_of(0).size(), 2, "the Start of Combat effect really summoned")
	assert_eq(result["damage_performance"], 1, "snapshot predates even hero effects")


func test_summoned_survivor_and_replacement_copy_do_not_count() -> void:
	var combat: Combat = _combat([KIT.board({0: KIT.plain(2, 2)}), KIT.board({})])
	var original: CombatUnit = combat.unit_at(0, 0)
	var summon: CombatUnit = combat.summon_into("field_vole", false, 0, 1, original)
	assert_not_null(summon)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 1)
	CombatMoves.become_copy(combat, original, summon, 0)
	assert_eq(combat.units_of(0).size(), 2)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 0, "new copies have new identities")


func test_stolen_enemy_and_own_unit_away_do_not_count_for_their_new_side() -> void:
	var combat: Combat = _combat(
		[KIT.board({0: KIT.plain(3, 3), 1: KIT.plain(2, 2)}), KIT.board({0: KIT.plain(4, 4)})]
	)
	CombatMoves.trade_sides(combat, combat.unit_at(0, 0), combat.unit_at(1, 0))
	assert_eq(CombatMoves.starting_survivors(combat, 0), 1, "only the untouched own unit counts")
	assert_eq(CombatMoves.starting_survivors(combat, 1), 0, "stolen starting unit is not ours")


func test_borrowed_starting_unit_counts_again_after_returning_home() -> void:
	var combat: Combat = _combat([KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.plain(4, 4)})])
	var borrower: CombatUnit = combat.unit_at(0, 0)
	var enemy: CombatUnit = combat.unit_at(1, 0)
	CombatMoves.borrow_across(combat, borrower, enemy, 0)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 0)
	CombatMoves.send_home(combat, enemy)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 1)
	assert_eq(CombatMoves.starting_survivors(combat, 1), 1)


func test_swallowed_starting_unit_counts_after_actual_return_lifecycle() -> void:
	var combat: Combat = _combat(
		[KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.u("hasty_pudding")})]
	)
	var original: CombatUnit = combat.unit_at(0, 0)
	var holder: CombatUnit = combat.unit_at(1, 0)
	CombatHeld.swallow(combat, holder, original)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 0, "off the board cannot contribute")
	CombatHeld.return_inside(combat, holder)
	assert_same(combat.unit_at(0, 0), original)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 1)


func test_dead_starting_unit_only_counts_when_alive_and_returned() -> void:
	var combat: Combat = _combat([KIT.board({0: KIT.plain(2, 2)}), KIT.board({})])
	var original: CombatUnit = combat.unit_at(0, 0)
	original.damage_taken = 2
	assert_eq(CombatMoves.starting_survivors(combat, 0), 0, "even before death cleanup")
	combat._resolve_deaths(0)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 0)
	# There is no printed death-return effect yet. Its identity contract is the same fighter,
	# restored and re-entered; a summon of the same card above explicitly does not qualify.
	original.damage_taken = 0
	combat.enter_board(original, original)
	assert_eq(CombatMoves.starting_survivors(combat, 0), 1)


func test_last_blow_has_round_base_and_zero_performance() -> void:
	var result: Dictionary = KIT.run(
		KIT.board({0: KIT.plain(3, 3)}), KIT.board({0: KIT.plain(3, 3)}), 1, _config()
	)
	assert_true(result["last_blow"])
	assert_eq(result["damage_performance"], 0)
	assert_eq(result["damage"], 1, "Last Blow uses the round base without the legacy floor")


func test_tie_has_zero_base_and_zero_performance() -> void:
	var combat := Combat.create(KIT.library, _config(), RandomNumberGenerator.new())
	combat.round_number = 50
	var result: Dictionary = combat.run([KIT.board({}), KIT.board({})], [6, 6], [0, 1], 0)
	assert_eq(result["winner"], -1)
	assert_eq(result["damage_base"], 0)
	assert_eq(result["damage_performance"], 0)
	assert_eq(result["damage"], 0)


func test_session_suppresses_legacy_toll_and_caps_in_v05_mode() -> void:
	var config: GameConfig = _config()
	config.set_value("players", 2)
	config.set_value("hero_choice", false)
	config.set_value("human_bot", "naive")
	config.set_value("bots", ["naive"])
	config.set_value("round_toll", true)
	config.set_value("damage_cap_by_turn", [1])
	config.set_value("damage_cap_off_at_alive", 0)
	var session := GameSession.create(41, KIT.library, config)
	session._round = 14
	assert_eq(session._round_toll(), 0)
	assert_eq(session._damage_cap(), 0)
	session._fight(0, 1, 1)
	assert_eq(session.get_last_combat()["damage"], 0, "draw toll is suppressed")
	session._players[1].board[0] = RecruitUnit.make(KIT.library.get_unit("field_vole"), 900)
	session._fight(0, 1, 1)
	assert_eq(session.get_last_combat()["damage"], 7, "session supplies R14's repeating base")
	var end: Dictionary = KIT.last(session.get_last_combat())
	assert_eq(end["damage_base"], 6)
	assert_eq(end["damage_performance"], 1)


func test_bare_defaults_keep_legacy_damage_selectable() -> void:
	var config := GameConfig.defaults()
	assert_false(config.uses_v05_damage())
	var result: Dictionary = KIT.run(KIT.board({0: KIT.plain(2, 2)}), KIT.board({}), 1, config)
	assert_eq(result["damage"], 2, "tier 1 hero plus tier 1 survivor")
