# gdlint:disable=max-public-methods
extends GutTest
## The slice's spells and heroes (docs/ideation/content/SLICE.md, neutrals-spells-heroes.md).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
const F1: int = 0
const F2: int = 1
const F3: int = 2
const B1: int = 4
const B2: int = 5

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_rules.start_phase(_player, 1)


func _hero(id: String) -> void:
	HeroRules.assign(_player, _kit.library.get_hero(id))


func test_elderflower_cordial_front_row_plus_1_2() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", F1)
	assert_eq(_kit.cast("elderflower_cordial", F1), "")
	assert_eq(unit.attack, 2)
	assert_eq(unit.health, 6)


func test_elderflower_cordial_back_row_plus_2_1() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", B1)
	_kit.cast("elderflower_cordial", B1)
	assert_eq(unit.attack, 3)
	assert_eq(unit.health, 5)


func test_pinch_of_dust_gives_plus_1_1() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.cast("pinch_of_dust", F1)
	assert_eq(unit.attack, 2)
	assert_eq(unit.health, 5)


func test_hungry_gap_gains_2_and_next_turn_only_shop_is_one_smaller() -> void:
	var size_now: int = _player.shop.size()
	_player.gold = 0
	_kit.cast("hungry_gap")
	assert_eq(_player.gold, 2, "its cost was paid at the shop")
	assert_eq(_rules.ask("shop_size", _player, 3), 3, "not this turn")
	_rules.end_phase(_player)
	_rules.after_fights(_player)
	assert_eq(_rules.ask("shop_size", _player, 3), 2, "next turn")
	_rules.start_phase(_player, 2)
	assert_eq(_rules.ask("shop_size", _player, 3), 2)
	_rules.end_phase(_player)
	assert_eq(_rules.ask("shop_size", _player, 3), 3, "gone after it")
	assert_gt(size_now, 0)


func test_shake_the_tree_refreshes_but_keeps_the_chosen_card() -> void:
	var kept: RecruitUnit = _player.shop[1]
	var others: Array = [_player.shop[0], _player.shop[2], _player.shop[3]]
	assert_eq(_kit.cast("shake_the_tree", 1), "")
	assert_has(_player.shop, kept)
	for gone: RecruitUnit in others:
		assert_does_not_have(_player.shop, gone)
	assert_eq(_player.shop.size(), 4)


func test_shake_the_tree_refuses_a_shop_index_that_isnt_there() -> void:
	assert_ne(_kit.cast("shake_the_tree", 9), "")
	assert_eq(_player.items.size(), 1, "still held")


func test_cold_frame_pays_after_2_turns_in_its_slot() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.cast("cold_frame", F1)
	_kit.pass_turn()
	assert_eq(unit.attack, 1, "the cast turn is one")
	_kit.pass_turn()
	assert_eq(unit.attack, 4)
	assert_eq(unit.health, 7)
	_kit.pass_turn()
	assert_eq(unit.attack, 4, "once")


func test_cold_frame_a_move_restarts_the_count() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.cast("cold_frame", F1)
	_kit.pass_turn()
	_rules.move_on_board(_player, F1, F2)
	_kit.pass_turn()
	assert_eq(unit.attack, 1, "one turn in the new slot")
	_kit.pass_turn()
	assert_eq(unit.attack, 4, "the second")


func test_cold_frame_wait_carried_through_a_triple_restarts_when_the_golden_lands() -> void:
	var first: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.put("pill_bug", F2)
	_kit.cast("cold_frame", F1)
	_kit.pass_turn()
	assert_eq(first.timers.size(), 1, "one turn in, still waiting")
	_kit.put("pill_bug")
	_rules.check_triples(_player)
	assert_eq(_player.hand.size(), 1, "the golden goes to hand")
	var golden: RecruitUnit = _player.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.timers.size(), 1, "the wait came along")
	var attack: int = golden.attack
	assert_eq(_rules.play(_player, 0, F3), "")
	_kit.pass_turn()
	assert_eq(golden.attack, attack, "the wait restarted: one turn in the new slot")
	_kit.pass_turn()
	assert_eq(golden.attack, attack + 3, "the second")


func test_bread_from_the_back_aims_the_back_row_and_feeds_the_units_in_front() -> void:
	_kit.put("pill_bug", B2)
	var left: RecruitUnit = _kit.put("pill_bug", F2)
	var right: RecruitUnit = _kit.put("pill_bug", F3)
	assert_ne(_kit.cast("bread_from_the_back", F2), "", "a front unit is no target")
	_player.items.clear()
	assert_eq(_kit.cast("bread_from_the_back", B2), "")
	assert_eq(left.attack, 2)
	assert_eq(right.health, 5)


func test_spore_cloud_rings_any_slot_plus_2_2() -> void:
	assert_eq(_kit.cast("spore_cloud", F1), "", "an empty slot will do")
	var unit: RecruitUnit = _kit.play("pill_bug", F1)
	assert_eq(unit.attack, 3)
	assert_eq(unit.health, 6)


func test_stand_behind_me_aims_the_front_row_and_feeds_the_units_behind() -> void:
	_kit.put("pill_bug", F2)
	var left: RecruitUnit = _kit.put("pill_bug", B1)
	assert_ne(_kit.cast("stand_behind_me", B1), "", "a back unit is no target")
	_player.items.clear()
	assert_eq(_kit.cast("stand_behind_me", F2), "")
	assert_eq(left.attack, 2)
	assert_eq(left.health, 5)


func test_boundary_stone_rings_a_slot_plus_3_3() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", F1)
	_kit.cast("boundary_stone", F1)
	assert_eq(unit.attack, 4)
	assert_eq(unit.health, 7)


func test_last_orders_spends_everything_for_1_1_per_2_spent() -> void:
	var unit: RecruitUnit = _kit.put("pill_bug", F1)
	_player.gold = 6
	_kit.cast("last_orders", F1)
	assert_eq(_player.gold, 0)
	assert_eq(unit.attack, 1 + 3, "6 spent is three lots of 2")
	assert_eq(unit.health, 4 + 3)


func test_dame_hoolet_back_row_attacks_before_front_row() -> void:
	_hero("dame_hoolet")
	_kit.put("pill_bug", F1)
	_kit.put("field_vole", B1)
	_kit.put("field_vole", B2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 99}}
	)
	var boards: Array = result["events"][0]["boards"]
	var back: Array = [boards[0][B1]["uid"], boards[0][B2]["uid"]]
	var mine: Array = []
	for event: Dictionary in result["events"]:
		if (
			event["type"] == "attack"
			and (event["attacker"] in back or event["attacker"] == boards[0][F1]["uid"])
		):
			mine.append(event["attacker"])
	assert_eq(mine.slice(0, 2), back, "B1, B2, then F1")
	assert_eq(mine[2], boards[0][F1]["uid"])


func test_brother_bracken_gives_small_board_one_stat_per_tier() -> void:
	_hero("brother_bracken")
	_kit.put("pill_bug", F2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 0, "health": 99}}
	)
	var raised: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "stats":
			raised.append(event["attack"])
	assert_has(raised, 2, "tier 1 gives +1/+1")


func test_pipkin_shop_is_2_bigger_and_only_2_buys() -> void:
	_hero("pipkin")
	_rules.replace_shop(_player)
	assert_eq(_player.shop.size(), 6, "4 + 2 on tier 1")
	_player.gold = 20
	assert_eq(_rules.buys_left(_player), 2)
	assert_eq(_rules.buy(_player, 0), "")
	assert_eq(_rules.buy(_player, 0), "")
	assert_ne(_rules.buy(_player, 0), "", "the third is refused")
	_kit.pass_turn()
	assert_eq(_rules.buys_left(_player), 2, "a new turn")


func test_dame_farthing_interest_on_carried_gold_up_to_5() -> void:
	_hero("dame_farthing")
	_player.gold = 11
	_rules.end_phase(_player)
	_rules.after_fights(_player)
	_rules.start_phase(_player, 2)
	assert_eq(_player.gold, 11 + _kit.config.get_int_at("income_by_turn", 1) + 2, "11 pays 2")
	_player.gold = 99
	_rules.end_phase(_player)
	_rules.after_fights(_player)
	_rules.start_phase(_player, 3)
	assert_eq(_player.gold, 99 + _kit.config.get_int_at("income_by_turn", 2) + 5, "up to 5")


func test_hob_mumblecrust_cannot_borrow_on_turn_one() -> void:
	_hero("hob_mumblecrust")
	var gold: int = _player.gold
	assert_false(_rules.power_usable(_player))
	assert_ne(_rules.use_power(_player), "")
	assert_eq(_player.gold, gold)
	assert_eq(_player.debt, 0)


func test_hob_mumblecrust_borrows_three_without_health_cost() -> void:
	_hero("hob_mumblecrust")
	_kit.pass_turn()
	_player.gold = 0
	var health: int = _player.health
	assert_eq(_rules.use_power(_player), "")
	assert_eq(_player.gold, 3)
	assert_ne(_rules.use_power(_player), "", "once a turn")
	_player.gold = 0
	_kit.pass_turn()
	assert_eq(_player.gold, _kit.config.get_int_at("income_by_turn", 2) - 1)
	assert_eq(_player.health, health)


func test_little_king_wren_lowest_attack_uses_the_highest_enemy_attack_first() -> void:
	_hero("little_king_wren")
	_kit.put("pill_bug", F1)
	_kit.put("ballooning_spider", F2)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 7, "health": 99}}
	)
	var pill: int = result["events"][0]["boards"][0][F1]["uid"]
	var damages: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "attack" and event["attacker"] == pill:
			damages.append(event)
	assert_gt(damages.size(), 0, "it attacked")
	var hit: int = 0
	for event: Dictionary in result["events"]:
		if event["type"] == "damage" and event["source"] == pill:
			hit = event["amount"]
			break
	assert_eq(hit, 7, "the enemy's 7, for the first attack")


func test_jill_down_the_tree_drops_a_tier_and_gains_2() -> void:
	_hero("jill_down_the_tree")
	assert_ne(_rules.use_power(_player), "", "tier 1 can't drop")
	_player.tier = 3
	_player.gold = 0
	assert_eq(_rules.use_power(_player), "")
	assert_eq(_player.tier, 2)
	assert_eq(_player.gold, 2)
	assert_eq(_player.upgrade_cost, 2, "going back up the tree is cheap, once")


func test_old_mother_mousewife_replaces_a_front_unit_at_your_tier() -> void:
	_hero("old_mother_mousewife")
	_player.tier = 3
	_kit.put("field_vole", F1)
	var result: Dictionary = _kit.fight_board(
		{F1: {"def_id": "pill_bug", "attack": 99, "health": 99}}
	)
	var mice: Array = []
	for event: Dictionary in result["events"]:
		if event["type"] == "summon":
			mice.append(event)
	assert_eq(mice.size(), 1, "a Mouse death cannot make another Mouse")
	assert_eq(mice[0]["slot"], F1)
	assert_eq(mice[0]["unit"]["attack"], 3)
	assert_eq(mice[0]["unit"]["health"], 3)


func test_march_hare_upgrades_cost_4_more_and_climb_two_tiers() -> void:
	_hero("march_hare")
	var cost: int = _rules.tier_up_cost(_player)
	assert_eq(cost, _player.upgrade_cost + 4)
	_player.gold = cost
	assert_eq(_rules.tier_up(_player), "")
	assert_eq(_player.tier, 3)
	_player.tier = 5
	_player.gold = 99
	assert_eq(_rules.tier_up(_player), "")
	assert_eq(_player.tier, 6, "the top is the top")
