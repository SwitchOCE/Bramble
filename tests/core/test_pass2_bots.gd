# gdlint:disable=max-public-methods
extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const K := preload("res://tests/core/recruit_kit.gd")
var _kit: K
var _brain: BotBrain


func before_each() -> void:
	_kit = K.new()
	_kit.setup(GameConfig.full_game(), true)
	_kit.rules.start_phase(_kit.player, 4)
	_kit.player.gold = 20
	_brain = BotBrain.from_name("hard")
	_brain._player = _kit.player
	_brain._rules = _kit.rules
	_brain.value.board_owner = _kit.player


func test_soup_makes_a_swallow_worth_considering_once_without_changing_routes() -> void:
	var soup: RecruitUnit = _kit.put("stone_soup", 0)
	_kit.put("pill_bug", 1)
	_kit.put("young_pretender", 2)
	_kit.put("moss_ooze", 4)
	var candidate: RecruitUnit = _kit.shop("pill_bug")
	_brain.value.strategy = {}
	assert_true(BotHeld.buys_into_belly(_kit.player, _brain.value, candidate, 0, false))
	soup.limits["stone_soup"] = 1
	assert_false(BotHeld.buys_into_belly(_kit.player, _brain.value, candidate, 0, false))
	assert_eq(_brain.value.strategy, {}, "the card score does not choose a tribe")


func test_lamp_only_values_a_discount_that_can_be_used() -> void:
	var lamp: RecruitUnit = _kit.shop("lamp_moth")
	assert_eq(BotContent5.lamp_value(lamp, _kit.player), BotEval.GOLD_POINTS)
	_kit.player.upgrade_cost = 0
	assert_eq(BotContent5.lamp_value(lamp, _kit.player), 0.0)
	_kit.player.upgrade_cost = 10
	_kit.player.tier = 6
	assert_eq(BotContent5.lamp_value(lamp, _kit.player), 0.0)
	assert_true(_brain.value.pays_on_play(lamp))


func test_deliberate_shy_thank_values_gold_and_silkys_actual_ring_room() -> void:
	var hob: RecruitUnit = _kit.put("hob_in_the_hearth", 4)
	var before: float = BotContent5.shy_departure_value(hob, _kit.player)
	_kit.put("silky", 5)
	assert_eq(BotContent5.shy_departure_value(hob, _kit.player), before + 4.0)
	BoardUpkeep.add_ring(_kit.player, 4, {"attack": 4, "health": 4})
	assert_eq(BotContent5.shy_departure_value(hob, _kit.player), before)
	var silky: RecruitUnit = _kit.player.board[5]
	assert_eq(BotContent5.shy_departure_value(silky, _kit.player, 0), 9.0, "Silky Rings herself")


func test_shy_shop_unit_has_no_future_tribe_bonus_value() -> void:
	_kit.player.tribe_bonuses["Fairies"] = 3
	var hob: RecruitUnit = _kit.shop("hob_in_the_hearth")
	assert_eq(BotCommitment.future_bonus(hob, _kit.player), 0.0)


func test_tom_tit_values_the_health_it_adds_to_actual_eggs() -> void:
	var bird: RecruitUnit = _kit.put("old_tern")
	bird.attack = 10
	bird.health = 20
	_kit.player.away.append({"unit": bird, "nest": 0, "due": 6, "left": 3})
	var tit: RecruitUnit = _kit.shop("tom_tit")
	var with_egg: float = _brain.value.buy_value(tit, _kit.player)
	_kit.player.away.clear()
	assert_gt(with_egg, _brain.value.buy_value(tit, _kit.player))
