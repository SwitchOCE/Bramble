# gdlint:disable=max-public-methods
extends GutTest
## Known meal/shop answers, plus diagnostic guard-off counterexamples. No lobbies.
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
## Mechanics here are checked at the pre-A3.5 Ooze dials; test_pass3_path covers the path values.
const LEGACY_DIALS: Dictionary = {
	"oozes_soup_share": 0.125,
	"oozes_elder_share": 0.5,
	"oozes_aspic_bonus": 0.5,
	"oozes_golden_aspic_multiplier": 2.0,
	"oozes_hasty_share": 0.2,
	"oozes_eat_printed_multiplier": 1,
}
var kit: KIT


static func _legacy_config() -> GameConfig:
	var config := GameConfig.full_game()
	for key: String in LEGACY_DIALS:
		config.set_value(key, LEGACY_DIALS[key])
	return config


func before_each() -> void:
	kit = KIT.new()
	kit.setup(_legacy_config())
	kit.player.round_number = 5
	kit.player.gold = 100


func _meal(attack: int = 8, health: int = 10, id: String = "field_vole") -> RecruitUnit:
	var meal: RecruitUnit = kit.put(id)
	meal.add_permanent(attack - meal.base_attack_now(), health - meal.base_health_now())
	kit.player.hand.erase(meal)
	return meal


func _start() -> void:
	kit.rules.board_changed(kit.player)
	Pass3Oozes.start_turn(kit.rules, kit.player, false)


func _body(unit: RecruitUnit) -> Vector2i:
	return Pass3Oozes.own_stats(unit)


func test_digest_keeps_only_own_stats_returns_real_copies_and_never_pays_sale_gold() -> void:
	var dollop: RecruitUnit = kit.put("little_dollop", 0)
	var meal: RecruitUnit = _meal(8, 10, "little_nip")
	meal.tribe_attack = 30
	meal.tribe_health = 40
	meal.set_aura(50, 60)
	meal.add_combat(70, 80)
	meal.pool_copies = 1
	assert_true(kit.pool.take(meal.def_id()))
	var copies: int = kit.pool.copies_left(meal.def_id())
	dollop.held.append(meal)
	_start()
	assert_eq(_body(dollop), Vector2i(9, 12))
	assert_eq(kit.player.gold, 100)
	assert_eq(kit.pool.copies_left(meal.def_id()), copies + 1)
	assert_true(dollop.held.is_empty())


func test_golden_digest_eats_both_meals_and_discount_is_two() -> void:
	var dollop: RecruitUnit = kit.put("little_dollop", 0, true)
	dollop.held.append(_meal())
	dollop.held.append(_meal(4, 6))
	_start()
	assert_eq(_body(dollop), Vector2i(14, 20))
	assert_eq(HeldUnits.swallow_cost(kit.rules, kit.player, dollop), 1)


func test_soup_live_layer_tracks_carry_and_is_retained_once_on_purchase() -> void:
	var carry: RecruitUnit = kit.put("little_dollop", 0)
	carry.add_permanent(79, 94)
	kit.put("stone_soup", 4)
	var offer: RecruitUnit = kit.shop("field_vole")
	var base: Vector2i = _body(offer)
	kit.rules.board_changed(kit.player)
	assert_eq(Vector2i(offer.attack, offer.health), base + Vector2i(10, 12))
	assert_eq(offer.perm_attack, 0)
	carry.add_permanent(80, 80)
	kit.rules.board_changed(kit.player)
	assert_eq(Vector2i(offer.attack, offer.health), base + Vector2i(20, 22))
	assert_eq(kit.rules.buy(kit.player, 0), "")
	assert_eq(_body(offer), base + Vector2i(20, 22))
	kit.player.board[4] = null
	kit.rules.board_changed(kit.player)
	assert_eq(_body(offer), base + Vector2i(20, 22))


func test_soup_never_buffs_or_commits_stats_to_shy_shop_offers() -> void:
	for golden: bool in [false, true]:
		before_each()
		var carry: RecruitUnit = kit.put("little_dollop", 0)
		carry.add_permanent(79, 94)
		kit.put("stone_soup", 4, golden)
		var offer: RecruitUnit = kit.shop("silky")
		var base: Vector2i = _body(offer)
		kit.rules.board_changed(kit.player)
		assert_eq(Vector2i(offer.attack, offer.health), base)
		assert_eq(offer.get_meta("ooze_soup_bonus"), Vector2i.ZERO)
		assert_eq(kit.rules.buy(kit.player, 0), "")
		assert_eq(_body(offer), base)
		assert_eq(Vector2i(offer.perm_attack, offer.perm_health), Vector2i.ZERO)


func test_golden_soup_reads_two_biggest_once_and_normal_soup_does_not_stack() -> void:
	var carry: RecruitUnit = kit.put("little_dollop", 0)
	carry.add_permanent(79, 94)
	var second: RecruitUnit = kit.put("bubble_and_squeak", 1)
	second.add_permanent(37, 44)
	kit.put("stone_soup", 4, true)
	kit.put("stone_soup", 5)
	kit.rules.board_changed(kit.player)
	assert_eq(Pass3Oozes.soup_bonus(kit.player), Vector2i(15, 18))
	kit.player.pass3_loop_guards = false
	assert_eq(Pass3Oozes.soup_bonus(kit.player), Vector2i(25, 30), "without best-Soup guard")


func test_soup_bonus_disappears_when_last_soup_leaves() -> void:
	kit.put("stone_soup", 4)
	var offer: RecruitUnit = kit.shop("field_vole")
	kit.rules.board_changed(kit.player)
	kit.player.board[4] = null
	kit.rules.board_changed(kit.player)
	assert_eq(Vector2i(offer.attack, offer.health), _body(offer))


func test_aspic_uses_only_strongest_in_front_and_elder_shares_original_meal() -> void:
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
	carry.add_permanent(30, 30)
	kit.put("aunt_aspic", 4)
	kit.put("aunt_aspic", 5, true)
	var elder: RecruitUnit = kit.put("elder_ooze", 6)
	var before: Vector2i = _body(carry)
	Pass3Oozes.eat(kit.rules, kit.player, carry, _meal())
	assert_eq(_body(carry) - before, Vector2i(16, 20))
	assert_eq(Vector2i(elder.perm_attack, elder.perm_health), Vector2i(4, 5))
	assert_eq(Pass3Oozes.aspic_bonus(kit.player, carry), 1.0)
	kit.player.pass3_loop_guards = false
	assert_eq(Pass3Oozes.aspic_bonus(kit.player, carry), 1.5, "without best-Aspic guard")


func test_normal_aspic_and_golden_elder_have_known_meal_gains() -> void:
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
	carry.add_permanent(30, 30)
	kit.put("aunt_aspic", 4)
	var elder: RecruitUnit = kit.put("elder_ooze", 6, true)
	var before: Vector2i = _body(carry)
	Pass3Oozes.eat(kit.rules, kit.player, carry, _meal())
	assert_eq(_body(carry) - before, Vector2i(12, 15))
	assert_eq(Vector2i(elder.perm_attack, elder.perm_health), Vector2i(8, 10))


func test_ooze_transfer_guard_prevents_aspic_amplification_and_elder_redistribution() -> void:
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
	carry.add_permanent(80, 80)
	kit.put("aunt_aspic", 4)
	var elder: RecruitUnit = kit.put("elder_ooze", 6)
	var before: Vector2i = _body(carry)
	Pass3Oozes.eat(kit.rules, kit.player, carry, _meal(20, 30, "little_dollop"))
	assert_eq(_body(carry) - before, Vector2i(20, 30))
	assert_eq(elder.perm_attack, 0)
	kit.player.pass3_loop_guards = false
	before = _body(carry)
	Pass3Oozes.eat(kit.rules, kit.player, carry, _meal(20, 30, "little_dollop"))
	assert_eq(_body(carry) - before, Vector2i(30, 45), "carry-transfer amplification without guard")
	assert_eq(elder.perm_attack, 10, "redistributed carry without non-Ooze guard")


func test_elder_ignores_smaller_eater_and_units_inside_or_in_hand() -> void:
	kit.put("bubble_and_squeak", 1).add_permanent(100, 100)
	var small: RecruitUnit = kit.put("little_dollop", 0)
	kit.put("elder_ooze", 6)
	var reserve: RecruitUnit = kit.put("moss_ooze")
	Pass3Oozes.eat(kit.rules, kit.player, small, _meal())
	assert_eq(reserve.perm_attack, 0)
	assert_eq(kit.player.board[6].perm_attack, 0)


func test_nell_eats_lowest_tier_into_biggest_neighbour_without_buy_or_swallow() -> void:
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
	carry.add_permanent(30, 30)
	kit.put("dishwater_nell", 5)
	var low: RecruitUnit = kit.shop("field_vole")
	var stats: Vector2i = _body(low)
	kit.shop("hasty_pudding")
	_start()
	assert_eq(Vector2i(carry.perm_attack, carry.perm_health), Vector2i(30, 30) + stats)
	assert_eq(kit.player.shop.size(), 1)
	assert_eq(kit.player.shop[0].def_id(), "hasty_pudding")
	assert_eq(kit.player.buys_this_turn, 0)
	assert_eq(kit.player.gold, 100)
	assert_true(carry.held.is_empty())


func test_golden_nell_feeds_two_distinct_neighbours_bigger_first_and_skips_frozen_shop() -> void:
	var first: RecruitUnit = kit.put("bubble_and_squeak", 1)
	first.add_permanent(30, 30)
	var second: RecruitUnit = kit.put("little_dollop", 2)
	kit.put("dishwater_nell", 5, true)
	var low: RecruitUnit = kit.shop("field_vole")
	var high: RecruitUnit = kit.shop("moss_ooze")
	var low_stats: Vector2i = _body(low)
	var high_stats: Vector2i = _body(high)
	kit.rules.board_changed(kit.player)
	Pass3Oozes.start_turn(kit.rules, kit.player, true)
	assert_eq(kit.player.shop.size(), 2)
	_start()
	assert_eq(Vector2i(first.perm_attack, first.perm_health), Vector2i(30, 30) + low_stats)
	assert_eq(Vector2i(second.perm_attack, second.perm_health), high_stats)


func test_dependent_start_sequence_digest_then_nell_then_slice_with_live_soup() -> void:
	var carry: RecruitUnit = kit.put("little_dollop", 1)
	carry.add_permanent(79, 78)
	carry.held.append(_meal(8, 8))
	kit.put("dishwater_nell", 5)
	kit.put("stone_soup", 4)
	kit.put("cut_and_come_again", 6)
	kit.shop("field_vole")
	_start()
	# 80/80 -> 88/88; Nell eats Vole's 2/3 plus live 11/11 -> 101/102.
	assert_eq(_body(carry), Vector2i(101, 102))
	assert_eq(_body(kit.player.hand[0]), Vector2i(20, 20))
	assert_eq(kit.player.hand[0].def_id(), "slice")


func test_cut_and_come_again_golden_widens_to_two_and_full_hand_loses_slice() -> void:
	kit.put("bubble_and_squeak", 1).add_permanent(97, 96)
	kit.put("cut_and_come_again", 6, true)
	_start()
	assert_eq(kit.player.hand.size(), 2)
	assert_eq(_body(kit.player.hand[0]), Vector2i(20, 20))
	assert_true(kit.player.hand[0].tribes().is_empty())
	assert_eq(kit.player.hand[0].origin, RecruitUnit.ORIGIN_CREATED)
	while kit.rules.has_hand_space(kit.player):
		kit.put("field_vole")
	var count: int = kit.player.hand.size()
	_start()
	assert_eq(kit.player.hand.size(), count)


func test_frumenty_remembers_last_meal_after_it_is_gone_and_replaces_it() -> void:
	var frum: RecruitUnit = kit.put("frumenty", 1)
	Pass3Oozes.eat(kit.rules, kit.player, frum, _meal(8, 10, "ballooning_spider"))
	assert_true(frum.held.is_empty())
	assert_true(frum.combat_spec().has("grants"))
	assert_eq(str(frum.borrowed_text()[0]["entry"]["id"]), "pass3_neutral")
	assert_eq(str(frum.borrowed_text()[0]["entry"]["ability"]), "ballooning_spider")
	Pass3Oozes.eat(kit.rules, kit.player, frum, _meal(8, 10, "stone_soup"))
	assert_true(Pass3Oozes.has(frum, "stone_soup"))
	for grant: Dictionary in frum.borrowed_text():
		var entry: Dictionary = grant["entry"]
		assert_ne(str(entry.get("ability", "")), "ballooning_spider")


func test_golden_frumenty_keeps_two_meals_excludes_digest_and_borrows_split() -> void:
	var frum: RecruitUnit = kit.put("frumenty", 1, true)
	Pass3Oozes.eat(kit.rules, kit.player, frum, _meal(8, 10, "stone_soup"))
	Pass3Oozes.eat(kit.rules, kit.player, frum, _meal(8, 10, "bubble_and_squeak"))
	assert_true(Pass3Oozes.has(frum, "stone_soup"))
	assert_eq(frum.last_meals.size(), 2)
	assert_true(
		frum.borrowed_text().any(
			func(grant: Dictionary) -> bool: return str(grant["entry"]["id"]) == "bubble"
		)
	)
	for grant: Dictionary in frum.borrowed_text():
		var entry: Dictionary = grant["entry"]
		assert_ne(str(entry.get("ability", "")), "bubble_and_squeak")


func test_figgy_pairs_bought_copies_keeps_buffs_and_has_no_alternating_turn_cooldown() -> void:
	kit.put("figgy_duff", 0, true)
	for _time: int in 2:
		var inner: RecruitUnit = _meal(4, 5)
		inner.origin = RecruitUnit.ORIGIN_BOUGHT
		kit.player.board[0].held.append(inner)
		var twin: RecruitUnit = kit.put("field_vole")
		twin.origin = RecruitUnit.ORIGIN_BOUGHT
		twin.add_permanent(2, 3)
		assert_true(HeldUnits.figgy_pair(kit.rules, kit.player))
		var golden: RecruitUnit = kit.player.hand.back()
		assert_true(golden.golden)
		assert_true(golden.reward_pending)
		assert_eq(_body(golden), Vector2i(8, 11))
		kit.player.hand.clear()
		kit.player.round_number += 1


func test_normal_figgy_also_pairs_two_bought_copies_and_refuses_created_copies() -> void:
	var figgy: RecruitUnit = kit.put("figgy_duff", 0)
	var inner: RecruitUnit = _meal(4, 5)
	inner.origin = RecruitUnit.ORIGIN_BOUGHT
	figgy.held.append(inner)
	var twin: RecruitUnit = kit.put("field_vole")
	assert_false(HeldUnits.figgy_pair(kit.rules, kit.player))
	twin.origin = RecruitUnit.ORIGIN_BOUGHT
	assert_true(HeldUnits.figgy_pair(kit.rules, kit.player))
	assert_true(kit.player.hand[0].golden)
	assert_eq(_body(kit.player.hand[0]), Vector2i(6, 8))
	assert_true(kit.player.hand[0].reward_pending)


func test_printed_plus_borrowed_elder_growth_fires_once_per_meal() -> void:
	var carry: RecruitUnit = kit.put("bubble_and_squeak", 1)
	carry.add_permanent(30, 30)
	var elder: RecruitUnit = kit.put("elder_ooze", 6)
	elder.grants.append(
		{
			"entry": {"id": "pass3_ooze", "ability": "elder_ooze", "factor": 1},
			"golden": false,
			"keyword": ""
		}
	)
	Pass3Oozes.eat(kit.rules, kit.player, carry, _meal())
	assert_eq(Vector2i(elder.perm_attack, elder.perm_health), Vector2i(4, 5))


func test_frumenty_really_uses_figgys_last_meal_text_without_a_cooldown() -> void:
	var frum: RecruitUnit = kit.put("frumenty", 0)
	Pass3Oozes.eat(kit.rules, kit.player, frum, _meal(3, 5, "figgy_duff"))
	assert_true(Pass3Oozes.has(frum, "figgy_duff"))
	for _pair: int in 2:
		var inner: RecruitUnit = _meal(4, 5)
		inner.origin = RecruitUnit.ORIGIN_BOUGHT
		frum.held.append(inner)
		var twin: RecruitUnit = kit.put("field_vole")
		twin.origin = RecruitUnit.ORIGIN_BOUGHT
		assert_true(HeldUnits.figgy_pair(kit.rules, kit.player))
		assert_true(kit.player.hand[0].golden)
		kit.player.hand.clear()
		kit.player.round_number += 1


func test_soup_rounds_up_small_bodies_normal_and_golden_and_sums_before_rounding() -> void:
	for golden: bool in [false, true]:
		before_each()
		kit.put("stone_soup", 4, golden)
		if golden:
			kit.put("little_dollop", 0)
		var offer: RecruitUnit = kit.shop("field_vole")
		var base: Vector2i = _body(offer)
		kit.rules.board_changed(kit.player)
		assert_eq(Pass3Oozes.soup_bonus(kit.player), Vector2i(1, 1))
		assert_eq(Vector2i(offer.attack, offer.health), base + Vector2i(1, 1))
		assert_eq(kit.rules.buy(kit.player, 0), "")
		assert_eq(_body(offer), base + Vector2i(1, 1))
		assert_eq(
			Pass3Oozes._portion(Vector2i(2, 3), 0.125),
			Vector2i.ZERO,
			"the general Elder/Slice rounding helper remains floor-based"
		)
