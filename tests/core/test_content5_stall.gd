extends GutTest
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument")

const Kit := preload("res://tests/core/recruit_kit.gd")

var _kit: Kit
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = Kit.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_player.tier = 4
	_player.gold = 50


func test_stall_revised_data_and_two_permanent_current_tier_slots() -> void:
	var card: Dictionary = _kit.library.get_card("market_stall")
	assert_eq(card.get("tier"), 4)
	assert_eq(card.get("cost"), 4)
	assert_eq(
		card.get("text"),
		"For the rest of the game, your shop shows 1 more unit, of your tier. At most 2 Stalls."
	)
	assert_eq(_kit.cast("market_stall"), "")
	assert_eq(_kit.cast("market_stall"), "")
	assert_eq(_player.market_stalls, 2)
	for tier: int in [4, 5, 6]:
		_player.tier = tier
		_rules.replace_shop(_player)
		assert_eq(_player.shop.size(), 7)
		var bonuses: int = MarketStalls.unit_bonus(_rules, _player)
		for index: int in range(7 - bonuses, 7):
			assert_eq(_player.shop[index].tier(), tier, "extra offers match current tier")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 10)
	assert_eq(_player.shop.size(), 7, "upgrade persists next turn")


func test_exact_tier_extra_offer_survives_refresh_and_tier_up_keeps_existing_offers() -> void:
	assert_eq(_kit.cast("market_stall"), "")
	_rules.replace_shop(_player)
	var bonus: RecruitUnit = _player.shop[5]
	assert_eq(bonus.tier(), 4)
	_player.upgrade_cost = 0
	assert_eq(_rules.tier_up(_player), "")
	assert_eq(_player.shop[5], bonus, "tier up does not replace existing cards")
	_rules.replace_shop(_player)
	assert_eq(_player.shop[5].tier(), 5)


func test_spell_is_not_offered_with_two_active_or_held_stalls_and_pool_is_intact() -> void:
	_player.market_stalls = 1
	_rules.give_card(_player, "market_stall")
	var before: int = _rules.spell_pool.copies_left("market_stall")
	for _roll: int in 30:
		_rules.replace_shop(_player)
		for item: HandItem in _player.shop_spells:
			assert_ne(item.def_id(), "market_stall")
	assert_eq(_rules.spell_pool.copies_left("market_stall"), before)
	for _pick: int in 10:
		_rules.discover(_player, {"kind": "spell", "tier": 4, "count": 20})
		var options: PackedStringArray = _player.pending[0]["options"]
		assert_false(options.has("market_stall"))
		assert_eq(_rules.choose(_player, 0), "")
		_player.items.clear()
		_rules.give_card(_player, "market_stall")


func test_buying_second_stall_removes_other_stall_offers_and_third_cannot_cast() -> void:
	_player.market_stalls = 1
	for _copy: int in 2:
		var item := HandItem.make(_kit.library.get_card("market_stall"), _rules.new_iid())
		assert_true(_rules.spell_pool.take("market_stall"))
		item.pool_copies = 1
		_player.shop_spells.append(item)
	var before: int = _rules.spell_pool.copies_left("market_stall")
	assert_eq(_rules.buy_spell(_player, 0), "")
	assert_eq(_player.gold, 46)
	assert_eq(_player.shop_spells.size(), 0)
	assert_eq(_rules.spell_pool.copies_left("market_stall"), before + 1)
	assert_eq(_rules.play_item(_player, 0), "")
	assert_eq(_player.market_stalls, 2)
	assert_eq(_kit.cast("market_stall"), "At most 2 Stalls")
	assert_eq(_player.market_stalls, 2)


func test_hungry_gap_reduces_capped_stall_shop_for_one_turn_including_frozen() -> void:
	_player.tier = 6
	_player.market_stalls = 2
	_rules.start_phase(_player, 8)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_kit.cast("hungry_gap"), "")
	assert_eq(_rules.toggle_freeze(_player), "")
	var first: RecruitUnit = _player.shop[0]
	_rules.end_phase(_player)
	_rules.start_phase(_player, 9)
	assert_eq(_player.shop.size(), 6)
	assert_eq(_player.shop[0], first, "frozen cards retain identity")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 10)
	assert_eq(_player.shop.size(), 7)


func test_pipkin_converts_capped_stalls_into_spell_slots_but_keeps_buy_limit() -> void:
	HeroRules.assign(_player, _kit.library.get_hero("pipkin"))
	_player.market_stalls = 2
	_rules.replace_shop(_player)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_player.shop_spells.size(), 3)
	_player.gold = 50
	assert_eq(_rules.buy(_player, 0), "")
	assert_eq(_rules.buy(_player, 0), "")
	assert_ne(_rules.buy(_player, 0), "", "Pipkin still buys at most two units")
	_player.tier = 6
	_rules.replace_shop(_player)
	assert_eq(_player.shop.size(), 7, "Pipkin also respects unit cap at tier 6")
	assert_eq(_player.shop_spells.size(), 3)
	assert_eq(_kit.cast("hungry_gap"), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 8)
	assert_eq(_player.shop.size(), 6)
	assert_eq(_player.shop_spells.size(), 3, "Gap changes units, not converted spell slots")


func test_stone_soup_reaches_the_extra_units_and_frozen_shop_keeps_them() -> void:
	_player.market_stalls = 2
	_kit.put("stone_soup", 0)
	_kit.put("mrs_posset", 1)
	_rules.replace_shop(_player)
	var extra: RecruitUnit = _player.shop[6]
	var stats := Vector2i(extra.attack, extra.health)
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, 1), "")
	assert_eq(Vector2i(extra.attack, extra.health), stats + Vector2i.ONE)
	assert_eq(_rules.toggle_freeze(_player), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 8)
	assert_true(_player.shop.has(extra))
	assert_eq(Vector2i(extra.attack, extra.health), stats, "Soup washes out as usual")
	assert_eq(_player.shop.size(), 7)


func test_poach_reserves_room_under_seven_and_defers_excess_without_losing_copies() -> void:
	_player.market_stalls = 2
	for _copy: int in 8:
		assert_true(_rules.pool.take("pill_bug"))
		var unit := RecruitUnit.make(_kit.library.get_unit("pill_bug"), _rules.new_iid())
		unit.pool_copies = 1
		unit.poached_discount = 1
		_player.poached_pending.append(unit)
	_rules.start_phase(_player, 8)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_player.poached_pending.size(), 1)
	assert_eq(MarketStalls.poached_count(_player), 7)
	_rules.end_phase(_player)
	_rules.start_phase(_player, 9)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_player.poached_pending.size(), 0)
	assert_eq(MarketStalls.poached_count(_player), 1)


func test_hungry_gap_limits_poached_offers_to_six_and_preserves_the_remainder() -> void:
	_player.market_stalls = 2
	var held: Array[RecruitUnit] = []
	for _copy: int in 7:
		assert_true(_rules.pool.take("pill_bug"))
		var unit := RecruitUnit.make(_kit.library.get_unit("pill_bug"), _rules.new_iid())
		unit.pool_copies = 1
		unit.poached_discount = 1
		held.append(unit)
		_player.poached_pending.append(unit)
	var copies: int = _rules.pool.copies_left("pill_bug")
	assert_eq(_kit.cast("hungry_gap"), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 8)
	assert_eq(_player.shop.size(), 6, "Gap removes a slot even with seven Poach offers")
	assert_eq(MarketStalls.poached_count(_player), 6)
	assert_eq(_player.poached_pending.size(), 1)
	assert_eq(_player.poached_pending[0], held[6], "the overflow offer stays pending")
	assert_eq(_rules.pool.copies_left("pill_bug"), copies, "no held copy returns early")
	_rules.replace_shop(_player)
	assert_eq(_player.shop.size(), 6, "refreshes respect the same reduced total capacity")
	assert_eq(_player.poached_pending[0], held[6])
	_rules.end_phase(_player)
	_rules.start_phase(_player, 9)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_player.poached_pending.size(), 0)
	assert_true(_player.shop.has(held[6]), "the deferred offer arrives after the Gap")
