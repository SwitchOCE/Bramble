extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var kit: KIT


func before_each() -> void:
	kit = KIT.new()
	kit.setup(GameConfig.full_game())


func test_nan_levels_smallest_bog_and_tiddy_splits_evenly_including_other_tribes() -> void:
	var nan: RecruitUnit = kit.put("warty_nan", 0)
	nan.add_permanent(10, 10)
	var small: RecruitUnit = kit.put("bridge_toad", 2)
	var carry: RecruitUnit = kit.put("gideon", 4)
	kit.put("tiddy_mun", 5)
	var outsider: RecruitUnit = kit.put("field_vole", 6)
	kit.player.bog_toll = 21
	kit.rules.events.fire(kit.player, "start_of_turn")
	assert_eq(small.perm_attack, 10, "Nan floors half of the Toll")
	assert_eq(
		[carry.perm_attack, outsider.perm_attack],
		[5, 5],
		"Tiddy's half is split among both neighbours"
	)
	assert_eq([carry.perm_health, outsider.perm_health], [5, 5])


func test_golden_nan_tiddy_and_resolved_dials_are_not_scaled_by_soak_keep() -> void:
	kit.config.set_value("bog_soak_keep", 99)
	kit.put("warty_nan", 0, true)
	var small: RecruitUnit = kit.put("bridge_toad", 2)
	var carry: RecruitUnit = kit.put("gideon", 4)
	kit.put("tiddy_mun", 5, true)
	kit.player.bog_toll = 20
	kit.rules.events.fire(kit.player, "start_of_turn")
	assert_eq(small.perm_attack, 20)
	assert_eq(
		carry.perm_attack, 20, "an end-position funnel gives its whole share to one neighbour"
	)


func test_printed_and_borrowed_growing_ability_only_fires_once_with_guard_counterexample() -> void:
	var nan: RecruitUnit = kit.put("warty_nan", 0)
	nan.add_permanent(100, 100)
	var target: RecruitUnit = kit.put("bridge_toad", 2)
	nan.grants.append(
		{"entry": {"id": "pass3_bog", "ability": "nan", "factor": 1}, "golden": false}
	)
	kit.player.bog_toll = 20
	kit.rules.events.fire(kit.player, "start_of_turn")
	assert_eq(target.perm_attack, 10)
	target.perm_attack = 0
	target.perm_health = 0
	kit.player.pass3_loop_guards = false
	kit.config.set_value("pass3_loop_guards", false)
	kit.rules.events.fire(kit.player, "start_of_turn")
	assert_eq(
		target.perm_attack, 20, "without deduplication, printed plus borrowed doubles the reward"
	)


func test_shared_kisses_survive_holding_and_new_frogs_and_toll_resets_to_zero() -> void:
	var frog: RecruitUnit = kit.put("his_highness")
	RecruitCarry.apply(kit.rules, kit.player, {"op": "bog_state", "toll": 19, "kisses": 2})
	assert_eq(frog.counters.get("kisses"), 2)
	kit.player.board[0] = frog
	kit.player.hand.erase(frog)
	kit.rules.board_changed(kit.player)
	var prince: RecruitUnit = kit.put("prince_restored", 3)
	kit.rules.board_changed(kit.player)
	assert_eq(prince.counters.get("kisses"), 2)
	RecruitCarry.apply(kit.rules, kit.player, {"op": "bog_state", "toll": 0, "kisses": 2})
	assert_eq(kit.player.bog_toll, 0)
	assert_eq(kit.rules.fight_rules(kit.player).get("bog_kisses"), 2)


func test_soak_preview_uses_scout_attack_rounded_up_and_never_own_stats() -> void:
	var toad: RecruitUnit = kit.put("bridge_toad", 0)
	toad.add_permanent(99999, 99999)
	kit.player.scout = {
		"views": [{"name": "Scout", "attack": 5, "health": 30}, null, null, null, null, null, null]
	}
	var board: Array = [toad.view(), null, null, null, null, null, null]
	Pass3Bog.views(kit.player, board, kit.config)
	assert_eq(board[0]["soak_preview"][0]["drink"], 4)
	kit.player.scout["views"][0]["attack"] = 1
	Pass3Bog.views(kit.player, board, kit.config)
	assert_eq(board[0]["soak_preview"][0]["drink"], 0, "Bitter leaves at least 1 Attack")


func test_golden_chorus_loan_uses_strongest_soak_and_lend_count_dial() -> void:
	kit.put("bridge_toad", 0)
	kit.put("natterjack_chorus", 1, true)
	kit.put("warty_nan", 2)
	assert_eq(Pass3Bog.soak_keep(kit.player, 0, kit.config), 4.0)
	assert_eq(Pass3Bog.soak_keep(kit.player, 2, kit.config), 4.0)
	var board: Array = [
		kit.player.board[0].view(),
		kit.player.board[1].view(),
		kit.player.board[2].view(),
		null,
		null,
		null,
		null
	]
	Pass3Bog.views(kit.player, board, kit.config)
	assert_string_contains(board[2]["borrowed_rules"][0]["text"], "next Start of Turn")
	assert_string_contains(board[2]["borrowed_rules"][0]["text"], "+4/+4")
	kit.config.set_value("bog_chorus_lends", 1)
	assert_eq(Pass3Bog.soak_keep(kit.player, 2, kit.config), 0.0)


func test_optional_capstone_toll_lever_only_pays_when_enabled() -> void:
	var diva: RecruitUnit = kit.put("prima_donna", 0)
	kit.player.bog_toll = 23
	kit.rules.events.fire(kit.player, "on_play", {"subject": diva})
	assert_eq(diva.perm_attack, 0)
	kit.config.set_value("bog_capstone_gain_toll", true)
	kit.rules.events.fire(kit.player, "on_play", {"subject": diva})
	assert_eq([diva.perm_attack, diva.perm_health], [23, 23])


func test_native_bog_has_no_size_caps_and_keeps_named_guards_with_overlays_off() -> void:
	kit.config.set_value("card_size_caps", false)
	kit.config.set_value("card_rate_limits", false)
	var library: UnitLibrary = ScaleOverlay.library_for(kit.library, kit.config)
	var toad: RecruitUnit = RecruitUnit.make(library.get_unit("bridge_toad"), 100)
	toad.add_permanent(10000, 10000)
	assert_eq(toad.perm_attack, 10000)
	assert_string_contains(library.get_unit("peat_cutter")["text"], "Once a fight")
	assert_string_contains(library.get_unit("peat_king")["text"], "Twice a fight")
	assert_true(Pass3Rates.enabled(kit.config, "pass3_loop_guards"))
