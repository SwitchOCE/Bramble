extends GutTest
## Tavern spells (rulebook 6.1.5, 4.2.5, 5.1.2, 5.3.7) and hand items: cards in hand with a play
## effect. Both share the hand limit (7.1.1).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	var config := GameConfig.defaults()
	config.set_value("spells_in_shop", true)
	_kit = KIT.new()
	_kit.setup(config)
	_player = _kit.player
	_rules = _kit.rules


func test_spell_appears_in_the_shop_next_to_units_6_1_5() -> void:
	_rules.start_phase(_player, 2)
	assert_eq(_player.shop_spells.size(), 1, "one spell slot at tier 1")
	assert_eq(_player.shop.size(), 3, "units unchanged")


func test_spell_comes_only_from_the_spell_pool_5_1_2() -> void:
	var before: int = _rules.spell_pool.total_copies()
	_rules.start_phase(_player, 2)
	assert_eq(_rules.spell_pool.total_copies(), before - 1, "one copy out")
	assert_eq(_player.shop_spells[0].pool_copies, 1, "and it holds that copy")


func test_buying_a_spell_costs_its_price_and_goes_to_hand_4_2_5() -> void:
	_rules.start_phase(_player, 2)
	_player.gold = 5
	var cost: int = _player.shop_spells[0].cost()
	assert_eq(_rules.buy_spell(_player, 0), "", "bought")
	assert_eq(_player.gold, 5 - cost, "paid")
	assert_eq([_player.items.size(), _player.shop_spells.size()], [1, 0], "moved to hand")


func test_spell_needs_gold_and_room_4_2_5() -> void:
	_rules.start_phase(_player, 2)
	_player.gold = 0
	if _player.shop_spells[0].cost() > 0:
		assert_eq(_rules.buy_spell(_player, 0), "Not enough gold", "no gold")
	_player.gold = 9
	_kit.card("filler", [])
	for _index: int in _kit.config.get_int("hand_limit"):
		_kit.put("filler")
	assert_eq(_rules.buy_spell(_player, 0), "Hand is full", "no room")


func test_items_count_against_the_hand_limit_7_1_1() -> void:
	_kit.spell("rock", {"effect": "free_refresh"})
	for _index: int in _kit.config.get_int("hand_limit") + 2:
		_rules.give_card(_player, "rock")
	assert_eq(_player.items.size(), _kit.config.get_int("hand_limit"), "the extras are lost")
	_kit.card("filler", [])
	_kit.shop("filler")
	_player.gold = 9
	assert_eq(_rules.buy(_player, 0), "Hand is full", "units share the limit")


func test_casting_applies_the_effect_to_the_aim_6_1_5() -> void:
	_kit.card("post", [], [], 1, 1)
	var unit: RecruitUnit = _kit.put("post", 3)
	_kit.spell(
		"grow", {"effect": "buff", "attack": 2, "health": 2, "target": {"select": "chosen"}}, "unit"
	)
	_rules.give_card(_player, "grow")
	assert_eq(_rules.play_item(_player, 0, 0), "Choose a unit on your board", "empty slot refused")
	assert_eq(_player.items.size(), 1, "still in hand after a refusal")
	assert_eq(_rules.play_item(_player, 0, 3), "", "cast")
	assert_eq([unit.attack, unit.health, _player.items.size()], [3, 3, 0], "buffed; single use")


func test_cast_spell_returns_its_copy_5_3_7() -> void:
	_rules.start_phase(_player, 2)
	var before: int = _rules.spell_pool.total_copies()
	_player.gold = 9
	_rules.buy_spell(_player, 0)
	var item: HandItem = _player.items[0]
	var problem: String = _rules.play_item(_player, 0, _aim_for(item))
	assert_eq(problem, "", "cast")
	_player.pending.clear()
	assert_eq(_rules.spell_pool.total_copies(), before + 1, "the copy went back")


func _aim_for(item: HandItem) -> int:
	if item.aim() == HandItem.AIM_NONE:
		return -1
	_kit.card("post", [], [], 1, 1)
	_kit.put("post", 0)
	return 0


func test_spell_cast_fires_on_spell_cast_item_does_not_3_4_1() -> void:
	_kit.card(
		"sage",
		[KIT.effect("on_spell_cast", {"effect": "buff", "attack": 1, "target": {"select": "self"}})]
	)
	var sage: RecruitUnit = _kit.put("sage", 0)
	_kit.spell("trick", {"effect": "free_refresh"})
	_kit.spell("acorn", {"effect": "free_refresh"}, "none", {"kind": "item"})
	_rules.give_card(_player, "trick")
	_rules.play_item(_player, 0)
	assert_eq(sage.attack, 2, "a spell counts")
	_rules.give_card(_player, "acorn")
	_rules.play_item(_player, 0)
	assert_eq(sage.attack, 2, "an item doesn't")


func test_generated_spell_holds_no_copy_5_3_6() -> void:
	var before: int = _rules.spell_pool.total_copies()
	_rules.give_card(_player, "sample_growth")
	assert_eq(_player.items[0].pool_copies, 0, "made by card text")
	_kit.card("post", [], [], 1, 1)
	_kit.put("post", 0)
	_rules.play_item(_player, 0, 0)
	assert_eq(_rules.spell_pool.total_copies(), before, "nothing extra went back")


func test_sample_acorn_hoards_until_played() -> void:
	_rules.give_card(_player, "sample_acorn")
	_rules.give_card(_player, "sample_acorn")
	_kit.card("post", [], [], 1, 1)
	var unit: RecruitUnit = _kit.put("post", 0)
	_rules.start_phase(_player, 2)
	assert_eq(_player.items.size(), 2, "it stays in hand across turns")
	_rules.play_item(_player, 0, 0)
	assert_eq(unit.attack, 2, "played onto a unit")


func test_shop_refresh_returns_the_spell_5_3_2() -> void:
	_rules.start_phase(_player, 2)
	_player.gold = 9
	var before: int = _rules.spell_pool.total_copies()
	_rules.refresh(_player)
	assert_eq(_rules.spell_pool.total_copies(), before, "one out, one back")
	assert_eq(_player.shop_spells.size(), 1, "a new one offered")


func test_frozen_shop_keeps_its_spell_4_5_2() -> void:
	_rules.start_phase(_player, 2)
	var spell: HandItem = _player.shop_spells[0]
	_rules.toggle_freeze(_player)
	_rules.end_phase(_player)
	_rules.start_phase(_player, 3)
	assert_eq(_player.shop_spells[0], spell, "the same card")


func test_add_card_effect_can_make_a_spell_6_1_5() -> void:
	_kit.card("scribe", [KIT.effect("on_buy", {"effect": "add_card", "card": "sample_growth"})])
	_kit.put("scribe", 0)
	_rules.events.fire(_player, "on_buy")
	assert_eq(_player.items.size(), 1, "the spell arrived")


func test_spell_prices_stay_flat_within_a_turn_4_2_5() -> void:
	_rules.start_phase(_player, 2)
	_player.gold = 30
	var first: int = _player.shop_spells[0].cost()
	var card: Dictionary = _player.shop_spells[0].def
	_rules.buy_spell(_player, 0)
	var again := HandItem.make(card, 99)
	assert_eq(again.cost(), first, "the printed cost")
