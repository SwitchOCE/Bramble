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
	assert_eq(card.get("text"), "Your shop permanently shows 1 more unit of your tier.")
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


func test_hungry_gap_reduces_stall_refills_for_one_turn() -> void:
	_player.tier = 6
	_player.market_stalls = 2
	_rules.start_phase(_player, 8)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_kit.cast("hungry_gap"), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 9)
	assert_eq(_player.shop.size(), 6)
	_rules.end_phase(_player)
	_rules.start_phase(_player, 10)
	assert_eq(_player.shop.size(), 7)


func test_frozen_offers_stay_when_hungry_gap_lowers_the_refill_target() -> void:
	for stalls: int in [0, 2]:
		_player.tier = 6
		_player.market_stalls = stalls
		_rules.start_phase(_player, 8)
		var kept: Array[RecruitUnit] = _player.shop.duplicate()
		assert_eq(_kit.cast("hungry_gap"), "")
		assert_eq(_rules.toggle_freeze(_player), "")
		_rules.end_phase(_player)
		_rules.start_phase(_player, 9)
		assert_eq(_player.shop, kept, "existing frozen offers retain their identity and number")
		assert_eq(_rules.shop_size(6, _player), 5 if stalls == 0 else 6)
		_rules.replace_shop(_player)
		assert_eq(_player.shop.size(), 5 if stalls == 0 else 6, "Gap applies to the next refill")
		_rules.end_phase(_player)
		_rules.start_phase(_player, 10)
		assert_eq(_player.shop.size(), 6 if stalls == 0 else 7)
		_rules.end_phase(_player)


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
	assert_eq(_player.shop.size(), 8, "Stalls do not shrink Pipkin's existing tier-6 shop")
	assert_eq(_player.shop_spells.size(), 3)
	assert_eq(_kit.cast("hungry_gap"), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 8)
	assert_eq(_player.shop.size(), 7)
	assert_eq(_player.shop_spells.size(), 3, "Gap changes units, not converted spell slots")


func test_stone_soup_leaves_extra_shop_units_unchanged_when_frozen() -> void:
	_player.market_stalls = 2
	_kit.put("stone_soup", 0)
	_kit.put("mrs_posset", 1)
	_rules.replace_shop(_player)
	var extra: RecruitUnit = _player.shop[6]
	var stats := Vector2i(extra.attack, extra.health)
	assert_eq(_rules.swallow(_player, HeldUnits.SHOP, 0, 1), "")
	assert_eq(Vector2i(extra.attack, extra.health), stats)
	assert_eq(_rules.toggle_freeze(_player), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 8)
	assert_true(_player.shop.has(extra))
	assert_eq(Vector2i(extra.attack, extra.health), stats, "Soup no longer changes shop stats")
	assert_eq(_player.shop.size(), 7)


func test_poach_bonus_offers_keep_their_existing_admission_and_expiry_rules() -> void:
	for stalls: int in [0, 2]:
		_player.market_stalls = stalls
		var held: Array[RecruitUnit] = _add_poached(8)
		_rules.start_phase(_player, 8)
		assert_eq(_player.shop.size(), 13 + stalls, "Poach remains separate bonus offers")
		assert_eq(HunterRecruit.normal_shop_count(_player), 5 + stalls)
		assert_eq(_player.poached_pending.size(), 0, "all Poach offers arrive together")
		for index: int in held.size():
			assert_eq(
				_player.shop[5 + stalls + index], held[index], "normal shop fills before Poach"
			)
		_rules.replace_shop(_player)
		assert_eq(_player.shop.size(), 13 + stalls, "refresh keeps every Poach bonus offer")
		for unit: RecruitUnit in held:
			assert_true(_player.shop.has(unit))
		_rules.end_phase(_player)
		_rules.start_phase(_player, 9)
		assert_eq(_player.shop.size(), 5 + stalls, "the previous turn's Poach offers expire")
		assert_eq(_player.poached_pending.size(), 0, "no old offers are deferred")
		_rules.end_phase(_player)


func test_hungry_gap_subtracts_from_normal_shop_without_changing_poach_offers() -> void:
	for stalls: int in [0, 2]:
		_player.market_stalls = stalls
		var held: Array[RecruitUnit] = _add_poached(7)
		assert_eq(_kit.cast("hungry_gap"), "")
		_rules.end_phase(_player)
		_rules.start_phase(_player, 8)
		assert_eq(_player.shop.size(), 11 + stalls)
		assert_eq(HunterRecruit.normal_shop_count(_player), 4 + stalls)
		assert_eq(_player.poached_pending.size(), 0)
		for unit: RecruitUnit in held:
			assert_true(_player.shop.has(unit), "Hungry Gap never defers a Poach offer")
		_rules.replace_shop(_player)
		assert_eq(_player.shop.size(), 11 + stalls)
		_rules.end_phase(_player)
		_rules.start_phase(_player, 9)
		assert_eq(_player.shop.size(), 5 + stalls)
		_rules.end_phase(_player)


func test_pipkin_without_stalls_keeps_eight_tier_six_units_and_existing_gap_subtraction() -> void:
	HeroRules.assign(_player, _kit.library.get_hero("pipkin"))
	_player.tier = 6
	_rules.start_phase(_player, 8)
	assert_eq(_player.market_stalls, 0)
	assert_eq(_rules.shop_size(6, _player), 8)
	assert_eq(_player.shop.size(), 8)
	assert_eq(_player.shop_spells.size(), 1)
	assert_eq(_kit.cast("hungry_gap"), "")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 9)
	assert_eq(_player.shop.size(), 7)
	_rules.end_phase(_player)
	_rules.start_phase(_player, 10)
	assert_eq(_player.shop.size(), 8)


func test_existing_heroes_keep_all_baseline_shop_sizes_without_stalls() -> void:
	var baseline: Array[int] = [4, 4, 4, 5, 5, 6]
	for hero: Dictionary in _kit.library.all_heroes():
		var player := PlayerState.new()
		_rules.setup_player(player)
		HeroRules.assign(player, hero)
		for tier: int in range(1, 7):
			player.tier = tier
			var expected: int = baseline[tier - 1] + (2 if str(hero["id"]) == "pipkin" else 0)
			assert_eq(_rules.shop_size(tier), baseline[tier - 1])
			assert_eq(_rules.shop_size(tier, player), expected, str(hero["id"]))
			_rules.replace_shop(player)
			assert_eq(player.shop.size(), expected, str(hero["id"]))
		_rules.end_phase(player)


func _add_poached(count: int) -> Array[RecruitUnit]:
	var held: Array[RecruitUnit] = []
	for _copy: int in count:
		assert_true(_rules.pool.take("pill_bug"))
		var unit := RecruitUnit.make(_kit.library.get_unit("pill_bug"), _rules.new_iid())
		unit.pool_copies = 1
		unit.poached_discount = 1
		held.append(unit)
		_player.poached_pending.append(unit)
	return held
