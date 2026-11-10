extends GutTest
## Prototype supply is an explicit test fixture; the live library keeps all prototypes retired.
## Recruit-phase triggers and the data effects on them (rulebook 3.2.1, 3.4.1, 4.2, 4.3.7, 4.4,
## 4.6, 7.2.3, 7.3, 8.3.3, 8.4; docs/ideation/engine.md). One test per trigger, one per effect.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
const GROW: Dictionary = {"effect": "buff", "attack": 1, "health": 1}

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(null, false, LegacyPrototypes.library())
	_player = _kit.player
	_rules = _kit.rules


func _card(id: String, mechanics: Array, tribes: Array = []) -> String:
	return _kit.card(id, mechanics, tribes)


func _put(id: String, slot: int = -1, golden: bool = false) -> RecruitUnit:
	return _kit.put(id, slot, golden)


## A board watcher that grows when `trigger` fires for anyone.
func _watcher(trigger: String, slot: int = 6) -> RecruitUnit:
	var id: String = "watch_%s" % trigger
	_card(id, [KIT.effect(trigger, GROW, {"subject": "any"})])
	return _put(id, slot)


func test_start_of_turn_trigger_3_2_1() -> void:
	var unit: RecruitUnit = _watcher("start_of_turn")
	_rules.start_phase(_player, 1)
	assert_eq(unit.attack, 2, "grew after the shop filled")


func test_start_of_turn_sees_the_new_shop_and_gold_3_2_1() -> void:
	_card("wealth", [KIT.effect("start_of_turn", {"effect": "buff", "attack": 1, "per": "gold"})])
	var unit: RecruitUnit = _put("wealth", 0)
	_rules.start_phase(_player, 1)
	assert_eq(unit.attack, 1 + 3, "+1 per gold, with the turn's 3 gold in")


func test_end_of_turn_trigger_3_4_1() -> void:
	var unit: RecruitUnit = _watcher("end_of_turn")
	_rules.start_phase(_player, 1)
	assert_eq(unit.attack, 1, "not yet")
	_rules.end_phase(_player)
	assert_eq(unit.attack, 2, "End of Turn")


func test_on_buy_trigger_4_2_1() -> void:
	var unit: RecruitUnit = _watcher("on_buy")
	_player.gold = 3
	var vole: RecruitUnit = _kit.shop("field_vole")
	assert_eq(_rules.buy(_player, 0), "", "buy")
	assert_eq(unit.attack, 2, "the board heard the buy")
	assert_true(_player.hand.has(vole), "bought into hand")


func test_on_buy_reaches_the_bought_unit_in_hand_4_2_1() -> void:
	_card("greeter", [KIT.effect("on_buy", GROW)])
	_kit.shop("greeter")
	_player.gold = 3
	_rules.buy(_player, 0)
	assert_eq(_player.hand[0].attack, 2, "its own buy trigger fired from the hand")


func test_on_play_battlecry_targets_position_7_2_3() -> void:
	var adjacent_buff: Dictionary = {
		"effect": "buff", "attack": 2, "target": {"select": "adjacent"}
	}
	_card("cry", [KIT.effect("on_play", adjacent_buff)])
	var left: RecruitUnit = _put("field_vole", 0)
	var far: RecruitUnit = _put("field_vole", 3)
	_put("cry")
	assert_eq(_rules.play(_player, 0, 1), "", "play to F2")
	assert_eq(left.attack, left.base_attack + 2, "F1 is adjacent")
	assert_eq(far.attack, far.base_attack, "F4 isn't")


func test_on_play_listens_to_itself_by_default_7_2_3() -> void:
	_card("selfish", [KIT.effect("on_play", GROW)])
	var unit: RecruitUnit = _put("selfish", 0)
	_put("field_vole")
	_rules.play(_player, 0, 1)
	assert_eq(unit.attack, 1, "another unit being played isn't its Battlecry")


func test_on_sell_fires_before_it_leaves_4_3_7() -> void:
	var around: Dictionary = {"effect": "buff", "attack": 3, "target": {"select": "adjacent"}}
	_card("parting", [KIT.effect("on_sell", around)])
	var neighbour: RecruitUnit = _put("field_vole", 1)
	_put("parting", 0)
	assert_eq(_rules.sell(_player, 0), "", "sell")
	assert_null(_player.board[0], "gone")
	assert_eq(neighbour.attack, neighbour.base_attack + 3, "it could still see its neighbour")


func test_on_summon_trigger_8_4() -> void:
	var watcher: RecruitUnit = _watcher("on_summon", 6)
	_rules.summon_units(_player, "hoglet", 2, false, 0)
	assert_eq(watcher.attack, 3, "two summons, heard one at a time")


func test_on_move_trigger_8_3_3() -> void:
	_card("restless", [KIT.effect("on_move", GROW)])
	var unit: RecruitUnit = _put("restless", 0)
	assert_eq(_rules.move(_player, 0, 5), "", "move")
	assert_eq(unit.attack, 2, "it moved")


func test_on_refresh_trigger_and_paid_flag_4_4() -> void:
	var paid_only: Dictionary = {"if": [{"kind": "paid"}], "subject": "any"}
	_card("thrifty", [KIT.effect("on_refresh", GROW, paid_only)])
	var unit: RecruitUnit = _put("thrifty", 0)
	_player.gold = 1
	_rules.refresh(_player)
	assert_eq(unit.attack, 2, "a paid refresh counts")
	_player.free_refreshes = 1
	_rules.refresh(_player)
	assert_eq(unit.attack, 2, "a free one doesn't")


func test_on_tier_up_trigger_4_6() -> void:
	var unit: RecruitUnit = _watcher("on_tier_up")
	_player.gold = 5
	_rules.tier_up(_player)
	assert_eq(unit.attack, 2, "tier went up")


func test_on_triple_trigger_7_3_1() -> void:
	var unit: RecruitUnit = _watcher("on_triple")
	_put("field_vole", 0)
	_put("field_vole", 1)
	_put("field_vole")
	_rules.check_triples(_player)
	assert_eq(unit.attack, 2, "a triple formed")


func test_on_gold_spent_counts_gold_with_every_4_1() -> void:
	var entry: Dictionary = KIT.effect(
		"on_gold_spent", GROW, {"every": 5, "count_amount": true, "counter": "spent"}
	)
	_card("miser", [entry])
	var unit: RecruitUnit = _put("miser", 0)
	_player.gold = 20
	_kit.shop("field_vole")
	_rules.buy(_player, 0)
	assert_eq([unit.attack, unit.counters["spent"]], [1, 3], "3 of 5 gold")
	_kit.shop("field_vole")
	_rules.buy(_player, 0)
	assert_eq([unit.attack, unit.counters["spent"]], [2, 1], "6 gold: fired once, 1 carried")


func test_every_threshold_stays_on_golden_7_3_5() -> void:
	_card("slow", [KIT.effect("end_of_turn", GROW, {"every": 2})])
	var golden: RecruitUnit = _put("slow", 0, true)
	_rules.end_phase(_player)
	assert_eq(golden.attack, 2, "golden base, the count is 1 of 2")
	_rules.end_phase(_player)
	assert_eq(golden.attack, 4, "+2: the number doubles, the threshold doesn't")


func test_limit_per_turn_resets_each_turn_g1() -> void:
	var entry: Dictionary = KIT.effect("on_buy", {"effect": "free_refresh"}, {"limit": 1})
	entry["subject"] = "any"
	_card("once", [entry])
	_put("once", 0)
	_player.gold = 30
	_kit.shop("field_vole")
	_kit.shop("field_vole")
	_rules.buy(_player, 0)
	_rules.buy(_player, 0)
	assert_eq(_player.free_refreshes, 1, "limit 1 this turn")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	var shop_size: int = _player.shop.size()
	assert_gt(shop_size, 0, "a new shop")
	_rules.buy(_player, 0)
	assert_eq(_player.free_refreshes, 2, "the limit starts over")


func test_after_combat_trigger_and_won_condition_3_5() -> void:
	_card("victor", [KIT.effect("after_combat", GROW, {"if": [{"kind": "won_last_combat"}]})])
	var unit: RecruitUnit = _put("victor", 0)
	_player.last_result = "loss"
	_rules.after_fights(_player)
	assert_eq(unit.attack, 1, "lost")
	_player.last_result = "win"
	_rules.after_fights(_player)
	assert_eq(unit.attack, 2, "won")


func test_events_queue_behind_each_other_architecture_3() -> void:
	# A play summons a token; the summon's trigger runs after the play's triggers finished.
	var summons: Dictionary = {"effect": "summon", "unit": "hoglet"}
	_card("caller", [KIT.effect("on_play", summons), KIT.effect("on_play", GROW)])
	_card("listener", [KIT.effect("on_summon", GROW)])
	var listener: RecruitUnit = _put("listener", 6)
	_put("caller")
	_rules.play(_player, 0, 0)
	assert_eq(_player.board[0].attack, 2, "both of the caller's on_play entries ran")
	assert_eq(listener.attack, 2, "and the summon was heard")


func test_trigger_limit_stops_a_loop_9_10_2() -> void:
	_kit.config.set_value("trigger_limit_action", 50)
	var loop_entry: Dictionary = KIT.effect("on_refresh", {"effect": "refresh_shop"})
	_card("looper", [loop_entry])
	_put("looper", 0)
	_player.free_refreshes = 1
	_rules.refresh(_player)
	var logged: Array = []
	for entry: Dictionary in _player.recruit_log:
		logged.append(entry["type"])
	assert_true(logged.has("trigger_limit"), "the loop stopped and said so")


# --- Effects ------------------------------------------------------------------------------------


func test_effect_buff_permanent_and_next_combat_12_1_1() -> void:
	var next_fight: Dictionary = {"effect": "buff", "attack": 2, "duration": "combat"}
	_card("priming", [KIT.effect("end_of_turn", next_fight)])
	var unit: RecruitUnit = _put("priming", 0)
	_rules.end_phase(_player)
	assert_eq(unit.attack, 3, "shown on the card for the fight ahead")
	assert_eq(unit.perm_attack, 0, "not permanent")
	_rules.after_fights(_player)
	assert_eq(unit.attack, 1, "over after the fight")


func _buff_with(select: String, slot: int, extra: Dictionary = {}) -> void:
	var target: Dictionary = {"select": select}
	target.merge(extra)
	var id: String = "%s_%d_%s" % [select, slot, extra.size()]
	var step: Dictionary = {"effect": "buff", "attack": 1, "target": target}
	_card(id, [KIT.effect("end_of_turn", step)])
	_put(id, slot)
	_rules.end_phase(_player)


func _grown_slots() -> Array:
	var out: Array = []
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _player.board[slot]
		if unit != null and unit.perm_attack > 0:
			out.append(slot)
	return out


func _fill_board(except: int) -> void:
	for slot: int in BoardGeometry.SLOTS:
		if slot != except:
			_put("field_vole", slot, true)


func test_selector_in_front_8_2_1() -> void:
	_fill_board(5)
	_buff_with("in_front", 5)
	assert_eq(_grown_slots(), [1, 2], "B2 has F2 and F3 in front")


func test_selector_behind_8_2_1() -> void:
	_fill_board(1)
	_buff_with("behind", 1)
	assert_eq(_grown_slots(), [4, 5], "F2 has B1 and B2 behind")


func test_selector_adjacent_8_2_2() -> void:
	_fill_board(1)
	_buff_with("adjacent", 1)
	assert_eq(_grown_slots(), [0, 2], "F1 and F3")


func test_selector_neighbours_8_2_3() -> void:
	_fill_board(5)
	_buff_with("neighbours", 5)
	assert_eq(_grown_slots(), [1, 2, 4, 6], "in front and adjacent")


func test_selector_row_and_ends_8_2_5() -> void:
	_fill_board(1)
	_buff_with("row_ends", 1)
	assert_eq(_grown_slots(), [0, 3], "the ends of the front row")


func test_selector_tribe_and_other_5_2_3() -> void:
	var fairy: RecruitUnit = _put("hedge_sprite", 0)
	var vole: RecruitUnit = _put("field_vole", 1)
	_buff_with("friendly", 2, {"tribe": "Fairies", "other": true})
	assert_eq(fairy.perm_attack, 1, "the Fairy")
	assert_eq(vole.perm_attack, 0, "not the Hedgerow Vole")
	assert_eq(_grown_slots(), [0], "and not itself")


func test_selector_random_count_is_seeded_1_2_2() -> void:
	_fill_board(0)
	_buff_with("others", 0, {"pick": "random", "count": 2})
	assert_eq(_grown_slots().size(), 2, "two of the six")


func test_selector_highest_attack_1_2_2() -> void:
	var strong: RecruitUnit = _put("field_vole", 0)
	strong.add_permanent(10, 0)
	_put("field_vole", 1)
	_buff_with("friendly", 2, {"pick": "highest_attack"})
	assert_eq(strong.perm_attack, 11, "the strongest")


func test_selector_hand_and_shop_12_2_2() -> void:
	var held: RecruitUnit = _put("field_vole")
	_buff_with("hand", 0)
	assert_eq(held.perm_attack, 1, "the hand")
	var shown: RecruitUnit = _kit.shop("field_vole")
	_buff_with("shop", 1)
	assert_eq(shown.perm_attack, 1, "the shop, before it goes back at the end of the turn")


func test_effect_summon_uses_8_4_and_is_created_4_3_1() -> void:
	_card("caller", [KIT.effect("end_of_turn", {"effect": "summon", "unit": "hoglet", "count": 2})])
	_put("caller", 1)
	_rules.end_phase(_player)
	assert_eq(_player.board[2].def_id(), "hoglet", "first choice from F2 is F3 (8.4.2)")
	assert_eq(_player.board[0].def_id(), "hoglet", "then F1")
	assert_eq(_player.board[0].origin, RecruitUnit.ORIGIN_CREATED, "Created")


func test_effect_summon_on_a_full_board_is_lost_8_4_5() -> void:
	_fill_board(0)
	_card("caller2", [KIT.effect("end_of_turn", {"effect": "summon", "unit": "hoglet"})])
	_put("caller2", 0)
	_rules.end_phase(_player)
	assert_eq(_player.board_count(), 7, "nothing new")


func test_golden_summons_a_golden_token_7_3_5() -> void:
	_card("caller3", [KIT.effect("end_of_turn", {"effect": "summon", "unit": "hoglet"})])
	_put("caller3", 0, true)
	_rules.end_phase(_player)
	assert_true(_player.board[1].golden, "golden token, count kept")


func test_effect_gold_now_and_next_turn_4_1_6() -> void:
	_card("purse", [KIT.effect("end_of_turn", {"effect": "gold", "amount": 2})])
	_card("bank", [KIT.effect("end_of_turn", {"effect": "gold", "amount": 3, "when": "next_turn"})])
	_put("purse", 0)
	_put("bank", 1)
	_rules.end_phase(_player)
	assert_eq([_player.gold, _player.gold_next_turn], [2, 3], "now and later")
	_rules.start_phase(_player, 1)
	assert_eq(_player.gold, 2 + 3 + 3, "carried, next-turn gold, income")
	assert_eq(_player.gold_next_turn, 0, "paid out")


func test_golden_doubles_gold_7_3_5() -> void:
	_card("purse2", [KIT.effect("end_of_turn", {"effect": "gold", "amount": 2})])
	_put("purse2", 0, true)
	_rules.end_phase(_player)
	assert_eq(_player.gold, 4, "doubled")


func test_effect_add_card_is_created_and_can_triple_7_3_3() -> void:
	_put("field_vole", 1)
	_put("field_vole", 2)
	_card("gift", [KIT.effect("end_of_turn", {"effect": "add_card", "card": "field_vole"})])
	_put("gift", 0)
	_rules.end_phase(_player)
	assert_true(_player.hand[0].golden, "the third copy made a golden")


func test_effect_add_card_from_pool_takes_a_real_copy_4_3_2() -> void:
	var pool: UnitPool = _kit.pool
	var before: int = pool.copies_left("field_vole")
	var step: Dictionary = {"effect": "add_card", "card": "field_vole", "from_pool": true}
	_card("gift2", [KIT.effect("end_of_turn", step)])
	_put("gift2", 0)
	_rules.end_phase(_player)
	assert_eq(pool.copies_left("field_vole"), before - 1, "left the pool")
	assert_eq(_player.hand[0].pool_copies, 1, "holds it")
	assert_eq(_player.hand[0].origin, RecruitUnit.ORIGIN_CREATED, "still sells for 0")


func test_effect_add_card_on_a_full_hand_is_lost_7_1_2() -> void:
	var step: Dictionary = {"effect": "add_card", "card": "hoglet"}
	_card("gift3", [KIT.effect("end_of_turn", step)])
	_put("gift3", 0)
	for _index: int in 10:
		_put("field_vole", -1, true)
	_rules.end_phase(_player)
	assert_eq(_player.hand.size(), 10, "lost")


func test_effect_free_refresh_costs_nothing_and_doesnt_count_4_4_5() -> void:
	_card("rerolls", [KIT.effect("start_of_turn", {"effect": "free_refresh", "count": 2})])
	_put("rerolls", 0)
	_rules.start_phase(_player, 1)
	assert_eq(_player.free_refreshes, 2, "two waiting")
	var gold: int = _player.gold
	assert_eq(_rules.refresh(_player), "", "refresh")
	assert_eq([_player.gold, _player.paid_refreshes, _player.free_refreshes], [gold, 0, 1], "free")


func test_effect_refresh_shop_replaces_a_frozen_shop_4_4_6() -> void:
	_card("rush", [KIT.effect("on_sell", {"effect": "refresh_shop"})])
	_put("rush", 0)
	_rules.start_phase(_player, 1)
	_player.frozen = true
	var old: Array = _player.shop.duplicate()
	_rules.sell(_player, 0)
	assert_false(_player.frozen, "unfrozen")
	assert_ne(old[0], _player.shop[0], "new cards")


func test_effect_grant_keyword_reaches_combat_11_1_1() -> void:
	var step: Dictionary = {
		"effect": "grant",
		"keyword": "Bristle",
		"mechanic": {"id": "bristle", "n": 3},
		"target": {"select": "adjacent"},
	}
	_card("teacher", [KIT.effect("end_of_turn", step)])
	var pupil: RecruitUnit = _put("field_vole", 1)
	_put("teacher", 0)
	_rules.end_phase(_player)
	var keywords: Array = pupil.view()["keywords"]
	assert_true(keywords.has("Bristle"), "shown on the card")
	var fighter := CombatUnit.make(pupil.def, pupil.combat_spec(), 1, 0)
	assert_true(fighter.has_mechanic("bristle"), "plays in combat")


func test_effect_grant_for_one_combat_ends_12_1_2() -> void:
	var step: Dictionary = {
		"effect": "grant",
		"keyword": "Hunker",
		"mechanic": {"id": "hunker"},
		"duration": "combat",
	}
	_card("brace", [KIT.effect("end_of_turn", step)])
	var unit: RecruitUnit = _put("brace", 0)
	_rules.end_phase(_player)
	assert_eq(unit.grants.size(), 1, "has it for the fight")
	_rules.after_fights(_player)
	assert_eq(unit.grants.size(), 0, "gone after")


func test_effect_damage_in_recruit_is_permanent_and_destroys_5_3_7() -> void:
	var step: Dictionary = {"effect": "damage", "amount": 2, "target": {"select": "adjacent"}}
	_card("spiky", [KIT.effect("end_of_turn", step)])
	_kit.card("frail", [], [], 1, 2)
	var tough: RecruitUnit = _put("hoglet_mother", 1)
	_put("frail", 3)
	_put("spiky", 2)
	_rules.end_phase(_player)
	assert_eq(tough.health, 1, "3 Health less 2, kept")
	assert_null(_player.board[3], "the 2-Health unit is destroyed")


func test_effect_swap_and_move_8_3_3() -> void:
	var swap: Dictionary = {"effect": "swap", "target": {"select": "in_front", "pick": "first"}}
	_card("climber", [KIT.effect("end_of_turn", swap)])
	var unit: RecruitUnit = _put("climber", 4)
	var front: RecruitUnit = _put("field_vole", 0)
	_rules.end_phase(_player)
	assert_eq(_player.board[0], unit, "moved up")
	assert_eq(_player.board[4], front, "and swapped")


func test_effect_move_to_a_row_8_3_3() -> void:
	var move: Dictionary = {"effect": "move", "to": "back"}
	_card("shy", [KIT.effect("on_play", move)])
	_put("shy")
	_rules.play(_player, 0, 0)
	assert_null(_player.board[0], "left the front")
	assert_eq(_player.board[4].def_id(), "shy", "first empty back slot")


func test_script_mechanic_reads_and_changes_position() -> void:
	# Scripts and data share RecruitContext.move_unit.
	var ctx: RecruitContext = RecruitContext.make(_rules, _player, "on_play", {})
	_put("field_vole", 2)
	ctx.source_slot = 2
	ctx.move_unit(2, 6)
	assert_null(_player.board[2], "moved")
	assert_eq(ctx.source_slot, 6, "the context follows its unit")


# --- Conditions ---------------------------------------------------------------------------------


func _fires_with(condition: Dictionary) -> bool:
	var id: String = "cond_%d" % _rules.new_iid()
	_card(id, [KIT.effect("end_of_turn", GROW, {"if": [condition]})])
	var unit: RecruitUnit = _put(id, _player.first_empty_slot())
	_rules.end_phase(_player)
	return unit.perm_attack > 0


func test_condition_count_tribe_12_2_2() -> void:
	var needs_two: Dictionary = {
		"kind": "count", "target": {"select": "friendly", "tribe": "Fairies"}, "at_least": 2
	}
	assert_false(_fires_with(needs_two), "no Fairies")
	_put("hedge_sprite", 5)
	_put("hedge_sprite", 6, true)
	assert_true(_fires_with(needs_two), "two Fairies")


func test_condition_position_reads_the_slot_8_2() -> void:
	_card("front_only", [KIT.effect("end_of_turn", GROW, {"if": [{"kind": "in_row"}]})])
	var front: RecruitUnit = _put("front_only", 2)
	var back: RecruitUnit = _put("front_only", 5)
	_rules.end_phase(_player)
	assert_eq([front.perm_attack, back.perm_attack], [1, 0], "front row only")


func test_condition_at_row_end_and_not_8_2_5() -> void:
	var clause: Dictionary = {"if": [{"kind": "at_row_end", "not": true}]}
	_card("middle", [KIT.effect("end_of_turn", GROW, clause)])
	var end: RecruitUnit = _put("middle", 0)
	var middle: RecruitUnit = _put("middle", 1)
	_rules.end_phase(_player)
	assert_eq([end.perm_attack, middle.perm_attack], [0, 1], "not at the end")


func test_condition_numbers_gold_tier_hand_round() -> void:
	_player.gold = 5
	_player.tier = 3
	_player.round_number = 7
	assert_true(_fires_with({"kind": "gold", "at_least": 5}), "gold")
	assert_false(_fires_with({"kind": "gold", "at_most": 4}), "gold at most")
	assert_true(_fires_with({"kind": "tier", "at_least": 3}), "tier")
	assert_true(_fires_with({"kind": "round", "at_least": 7}), "round")
	assert_true(_fires_with({"kind": "hand", "at_most": 0}), "hand")


func test_condition_chance_is_on_the_effect_stream_1_2_2() -> void:
	assert_true(_fires_with({"kind": "chance", "percent": 100}), "always")
	assert_false(_fires_with({"kind": "chance", "percent": 0}), "never")


func test_subject_tribe_filter_5_2_3() -> void:
	var filter: Dictionary = {"subject": "other", "subject_tribe": "Fairies"}
	_card("fan", [KIT.effect("on_play", GROW, filter)])
	var fan: RecruitUnit = _put("fan", 0)
	_put("field_vole")
	_rules.play(_player, 0, 1)
	assert_eq(fan.attack, 1, "a Vole played")
	_put("hedge_sprite")
	_rules.play(_player, 0, 2)
	assert_eq(fan.attack, 2, "a Fairy played")


func test_per_scales_the_numbers() -> void:
	var step: Dictionary = {
		"effect": "buff", "attack": 2, "per": {"select": "friendly", "tribe": "Fairies"}
	}
	_card("scaler", [KIT.effect("end_of_turn", step)])
	var unit: RecruitUnit = _put("scaler", 0)
	_put("hedge_sprite", 1)
	_put("hedge_sprite", 2, true)
	_rules.end_phase(_player)
	assert_eq(unit.perm_attack, 4, "+2 for each of two Fairies")


func test_golden_doubling_reaches_every_number_in_a_data_effect_7_3_5() -> void:
	var entry: Dictionary = {
		"id": "effect",
		"trigger": "on_play",
		"every": 3,
		"do":
		[
			{"effect": "buff", "attack": 1, "health": 2},
			{"effect": "gold", "amount": 3},
			{"effect": "free_refresh", "count": 1},
			{"effect": "damage", "amount": 4},
			{"effect": "add_card", "card": "hoglet", "count": 1},
			{"effect": "summon", "unit": "hoglet", "count": 1},
		],
	}
	var golden: Dictionary = MechanicRegistry.params_for(entry, true)
	var steps: Array = golden["do"]
	assert_eq([steps[0]["attack"], steps[0]["health"]], [2, 4], "buff")
	assert_eq(steps[1]["amount"], 6, "gold")
	assert_eq(steps[2]["count"], 2, "free refresh")
	assert_eq(steps[3]["amount"], 8, "damage")
	assert_eq(steps[4]["count"], 2, "add card")
	assert_eq(steps[5]["count"], 1, "summon count is a threshold (golden token instead)")
	assert_eq(golden["every"], 3, "thresholds keep their value")
	var normal: Dictionary = MechanicRegistry.params_for(entry, false)
	var normal_steps: Array = normal["do"]
	assert_eq(normal_steps[0]["attack"], 1, "the normal card is untouched")
