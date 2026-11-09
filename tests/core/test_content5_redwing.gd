# gdlint:disable=max-public-methods
extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game(), true)
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)
	_player.gold = 20


func _fly(id: String, slot: int, attack: int = 7, health: int = 9) -> RecruitUnit:
	var bird: RecruitUnit = _kit.put(id, slot)
	bird.attack = attack
	bird.health = health
	bird.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(_rules.sell(_player, slot), "")
	return bird


func _combat(enemy: Dictionary = {}) -> Combat:
	var combat := Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())
	combat.side_rules = [_rules.fight_rules(_player), {}]
	combat._setup([_player.combat_board(), KIT._board(enemy)])
	combat._recalc_auras(false)
	return combat


func _stats(combat: Combat, slot: int) -> Vector2i:
	var unit: CombatUnit = combat.unit_at(0, slot)
	return Vector2i(unit.attack, unit.max_health)


func test_redwing_supports_only_eggs_beside_it_in_the_same_row() -> void:
	_fly("mrs_jay", 0)
	_fly("one_swallow", 2)
	_fly("chiffchaff", 4)
	_kit.put("redwing", 1)
	var combat: Combat = _combat()
	assert_eq(_stats(combat, 0), Vector2i(7, 9))
	assert_eq(_stats(combat, 2), Vector2i(7, 9))
	assert_eq(_stats(combat, 4), Vector2i(4, 5), "behind is not beside")
	assert_eq(combat.unit_at(0, 0).mechanic_ids, PackedStringArray(), "Egg gets no Bird text")


func test_golden_redwing_adds_two_and_copies_use_the_strongest_bonus_once() -> void:
	_fly("mrs_jay", 1)
	_kit.put("redwing", 0)
	_kit.put("redwing", 2, true)
	assert_eq(_stats(_combat(), 1), Vector2i(9, 11))
	_player.board[0] = null
	_kit.put("redwing", 0, true)
	assert_eq(_stats(_combat(), 1), Vector2i(9, 11), "golden copies do not stack")


func test_losing_redwing_in_combat_removes_only_its_aura_and_keeps_egg_buffs() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1)
	var combat: Combat = _combat()
	var egg: CombatUnit = combat.unit_at(0, 0)
	egg.add_combat(3, 4)
	combat.deal_effect_damage(null, combat.unit_at(0, 1), 99)
	combat._resolve_deaths(0)
	assert_eq(_stats(combat, 0), Vector2i(7, 9), "half 4/5 plus its own 3/4")
	assert_eq(egg.perm_attack, 4)


func test_real_nest_support_keeps_permanent_buffs_added_to_its_egg() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1)
	var combat: Combat = _combat()
	combat.unit_at(0, 0).add_permanent(3, 4)
	combat._recalc_auras(false)
	assert_eq(_stats(combat, 0), Vector2i(10, 13), "full Bird plus the Egg's permanent 3/4")
	combat.deal_effect_damage(null, combat.unit_at(0, 1), 99)
	combat._resolve_deaths(0)
	assert_eq(_stats(combat, 0), Vector2i(7, 9), "half Bird plus the same permanent 3/4")


func test_moving_redwing_changes_which_nest_it_supports() -> void:
	_fly("mrs_jay", 0)
	_fly("one_swallow", 4)
	_kit.put("redwing", 1)
	var combat: Combat = _combat()
	var source: CombatUnit = combat.unit_at(0, 1)
	combat.sides[0][1] = null
	combat.sides[0][5] = source
	source.slot = 5
	combat._recalc_auras(true)
	assert_eq(_stats(combat, 0), Vector2i(4, 5))
	assert_eq(_stats(combat, 4), Vector2i(7, 9))


func test_stealing_redwings_text_turns_its_egg_support_off() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	var combat: Combat = _combat({1: "mag_pye"})
	CombatHeld.steal_text(combat, combat.unit_at(1, 1), combat.unit_at(0, 1))
	assert_eq(_stats(combat, 0), Vector2i(4, 5))
	assert_eq(combat.unit_at(1, 1).params[-1]["factor"], 2, "golden text keeps its bonus")


func test_flying_redwing_stops_supporting_and_its_own_egg_has_no_aura() -> void:
	_fly("mrs_jay", 0)
	var redwing: RecruitUnit = _kit.put("redwing", 1)
	redwing.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_eq(_rules.sell(_player, 1), "")
	var combat: Combat = _combat()
	assert_eq(_stats(combat, 0), Vector2i(4, 5))
	assert_eq(_stats(combat, 1), Vector2i(1, 2))
	assert_eq(_player.nest_count(), 2)


func test_redwing_full_stats_replace_gooses_normal_half_egg() -> void:
	var goose: RecruitUnit = _fly("mother_goose", 0, 12, 15)
	_kit.put("redwing", 1)
	assert_eq(_stats(_combat(), 0), Vector2i(12, 15))
	assert_eq(HeldUnits.egg_forecast(_player, goose, 0)["attack"], 12)
	_player.board[1] = null
	assert_eq(_stats(_combat(), 0), Vector2i(6, 8), "Goose now follows the normal Egg rule")


func test_full_current_bird_includes_harvest_supper_once_and_ring_is_added_after() -> void:
	var bird: RecruitUnit = _fly("mrs_jay", 0)
	_kit.put("redwing", 1)
	assert_eq(_kit.cast("harvest_supper", 1), "")
	_player.slot_effects[0] = [{"name": "Ring", "attack": 3, "health": 5}]
	var fight: Dictionary = _kit.fight_board({0: {"def_id": "pill_bug", "attack": 0, "health": 99}})
	var egg: Dictionary = KIT.of_type(fight, "combat_start")[0]["boards"][0][0]
	assert_eq(Vector2i(egg["attack"], egg["health"]), Vector2i(11, 15))
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(8, 10), "no permanent Egg growth")


func test_a_recruit_covering_the_nest_does_not_get_redwings_stats() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1)
	var unit: RecruitUnit = _kit.put("pill_bug", 0)
	assert_eq(_stats(_combat(), 0), Vector2i(unit.attack, unit.health))


func test_returning_birds_remove_the_egg_without_gaining_stats() -> void:
	var bird: RecruitUnit = _fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	_kit.pass_turn()
	assert_eq(_stats(_combat(), 0), Vector2i(9, 11))
	_kit.pass_turn()
	assert_true(_player.hand.has(bird))
	assert_null(_player.combat_board()[0])
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(7, 9))


func test_dunnock_shortens_the_supported_tern_trip_and_brings_home_the_flock() -> void:
	var bird: RecruitUnit = _fly("old_tern", 1)
	var other: RecruitUnit = _fly("mrs_jay", 3)
	_kit.put("mrs_dunnock", 0)
	_kit.put("redwing", 2)
	assert_eq(_stats(_combat(), 1), Vector2i(7, 9), "Dunnock leaves the supported Egg free")
	assert_eq(_player.nest_at(3)["due"], 3)
	_kit.pass_turn()
	assert_true(_player.hand.has(bird))
	assert_true(_player.hand.has(other), "Tern brings back the Bird whose trip was not shortened")
	assert_true(_player.pending.is_empty())
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(7, 9))
	assert_eq(Vector2i(other.attack, other.health), Vector2i(7, 9))


func test_stork_returns_supported_bird_without_copying_egg_stats() -> void:
	var bird: RecruitUnit = _fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	_kit.put("mrs_stork", 2)
	_kit.pass_turn()
	_player.gold = 20
	_rules.spend(_player, 6)
	assert_true(_player.hand.has(bird))
	assert_null(_player.combat_board()[0])
	assert_eq(Vector2i(bird.attack, bird.health), Vector2i(7, 9))


func test_played_bird_text_still_repeats_when_it_returns_from_a_supported_nest() -> void:
	var bird: RecruitUnit = _fly("chiffchaff", 4)
	var front: RecruitUnit = _kit.put("pill_bug", 0)
	_kit.put("redwing", 5)
	_kit.pass_turn()
	_kit.pass_turn()
	var before: int = bird.attack
	assert_eq(_rules.play(_player, _player.hand.find(bird), 4), "")
	assert_eq(bird.attack, before + 1)
	assert_eq(front.attack, 1)


func test_whistlers_does_not_count_a_full_size_egg_as_a_bird() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	_kit.put("seven_whistlers", 6)
	var fight: Dictionary = _kit.fight_board(
		{0: {"def_id": "pill_bug", "attack": 20, "health": 40}}
	)
	var changes: Array[Dictionary] = KIT.of_type(fight, "stats")
	assert_true(changes.is_empty(), "no Bird came home this turn")
	var egg: Dictionary = KIT.of_type(fight, "combat_start")[0]["boards"][0][0]
	assert_eq(egg["tribes"], [])


func test_ratchet_lands_the_real_bird_without_copying_gold_redwings_egg_bonus() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	_kit.put("gabble_ratchet", 6)
	var combat: Combat = _combat()
	combat.deal_effect_damage(null, combat.unit_at(0, 0), 99)
	combat._resolve_deaths(0)
	assert_eq(combat.unit_at(0, 0).def_id(), "mrs_jay")
	assert_eq(_stats(combat, 0), Vector2i(7, 9))


func test_ghost_snapshot_keeps_supported_eggs_without_reading_the_live_player() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	var board: Array = _player.combat_board()
	var sky: Dictionary = HeldUnits.sky_rules(_player)
	_player.away.clear()
	_player.board[1] = null
	var combat := Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())
	combat.side_rules = [sky, {}]
	combat._setup([board, KIT._board({})])
	combat._recalc_auras(false)
	assert_eq(_stats(combat, 0), Vector2i(9, 11))


func test_frumenty_and_grants_forecast_the_same_full_eggs_as_combat() -> void:
	var bird: RecruitUnit = _fly("mrs_jay", 0)
	var borrower: RecruitUnit = _kit.put("frumenty", 1)
	borrower.held.append(RecruitUnit.make(_kit.library.get_unit("redwing"), 900, true))
	assert_eq(HeldUnits.egg_forecast(_player, bird, 0)["attack"], 9)
	assert_eq(_stats(_combat(), 0), Vector2i(9, 11))
	borrower.held.clear()
	borrower.grants.append({"entry": {"id": "redwing", "factor": 1}, "golden": true})
	assert_eq(HeldUnits.egg_forecast(_player, bird, 0)["health"], 11)
	assert_eq(_stats(_combat(), 0), Vector2i(9, 11))


func test_scout_records_supported_egg_without_exposing_the_away_bird() -> void:
	_fly("mrs_jay", 0)
	_kit.put("redwing", 1, true)
	_player.slot_effects[0] = [{"name": "Ring", "attack": 3, "health": 5}]
	_player.remember_fought_board()
	assert_eq(_player.fought_specs[0]["egg_full_attack"], 7)
	assert_eq(_player.fought_specs[0]["egg_full_health"], 9)
	assert_eq(_player.fought_view[0]["attack"], 12)
	assert_eq(_player.fought_view[0]["health"], 16)
	assert_false(str(_player.fought_specs).contains("mrs_jay"))
	var combat := Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())
	combat._setup([_player.fought_specs, KIT._board({})])
	combat._recalc_auras(false)
	assert_eq(_stats(combat, 0), Vector2i(9, 11), "public scout body supports the simulated aura")
	combat.deal_effect_damage(null, combat.unit_at(0, 1), 99)
	combat._resolve_deaths(0)
	assert_eq(_stats(combat, 0), Vector2i(4, 5), "the simulated aura still disappears")


func test_live_and_ghost_scouts_keep_only_supported_eggs_visible_stats() -> void:
	_fly("mrs_jay", 0)
	_fly("old_tern", 3)
	_kit.put("redwing", 1)
	_player.remember_fought_board()
	_player.fought_rules = _rules.fight_rules(_player)
	var config: GameConfig = GameConfig.full_game()
	config.set_value("pass3_content", false)
	config.set_value("bots", BotLobby.seats(BotLevel.HARD))
	var session: GameSession = GameSession.create(3, _kit.library, config)
	session._players[2] = _player
	var scout: Dictionary = session._scout_of(2)
	assert_eq(scout["specs"][0]["egg_full_attack"], 7)
	assert_eq(scout["specs"][0]["egg_full_health"], 9)
	assert_eq(scout["rules"], {"back_row_first": false}, "no separate Egg metadata")
	assert_false(str(scout).contains("old_tern"), "unsupported away Birds stay private")
	assert_false(str(scout).contains("mrs_jay"), "supported Eggs expose stats, not Bird identity")
	_player.health = 0
	session._eliminate()
	var ghost: Dictionary = session._scout_of(Matchmaking.GHOST)
	assert_eq(ghost["rules"], {}, "ghost scout needs only its plain Egg specs")
	var combat := Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())
	combat.side_rules = [session._ghost_rules, {}]
	combat._setup([session._ghost_board, KIT._board({})])
	combat._recalc_auras(false)
	assert_eq(_stats(combat, 0), Vector2i(7, 9))
	assert_false(str(ghost).contains("old_tern"))
	assert_false(str(ghost).contains("mrs_jay"))
	combat = Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())
	combat._setup([ghost["specs"], KIT._board({})])
	combat._recalc_auras(false)
	assert_eq(_stats(combat, 0), Vector2i(7, 9), "ghost scout uses its plain Egg spec")
	combat.deal_effect_damage(null, combat.unit_at(0, 1), 99)
	combat._resolve_deaths(0)
	assert_eq(_stats(combat, 0), Vector2i(4, 5), "ghost scout loses support dynamically too")


func test_plain_goose_egg_scout_keeps_half_current_stats_and_golden_support() -> void:
	_fly("mother_goose", 0, 12, 15)
	_kit.put("redwing", 1, true)
	_player.remember_fought_board()
	var egg: Dictionary = _player.fought_specs[0]
	assert_eq([egg["attack"], egg["health"]], [6, 8])
	assert_eq([egg["egg_full_attack"], egg["egg_full_health"]], [12, 15])
	assert_false(str(_player.fought_specs).contains("mother_goose"))
	var combat := Combat.create(_kit.library, _kit.config, RandomNumberGenerator.new())
	combat._setup([_player.fought_specs, KIT._board({})])
	combat._recalc_auras(false)
	assert_eq(_stats(combat, 0), Vector2i(14, 17))
	combat.deal_effect_damage(null, combat.unit_at(0, 1), 99)
	combat._resolve_deaths(0)
	assert_eq(_stats(combat, 0), Vector2i(6, 8))
