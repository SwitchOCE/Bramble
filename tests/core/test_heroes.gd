extends GutTest
## Prototype supply is an explicit test fixture; the live library keeps all prototypes retired.
## Heroes (rulebook 2.2) and the small rule-query list: refresh cost, tier-up cost, income, shop
## size, sell value (architecture-notes 1-2).
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")

var _kit: KIT
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(null, false, LegacyPrototypes.library())
	_player = _kit.player
	_rules = _kit.rules


func _rule(query: String, op: String, value: int) -> Dictionary:
	return {"query": query, "op": op, "value": value}


func _hero(power: Dictionary, extra: Dictionary = {}) -> Dictionary:
	var hero: Dictionary = {"id": "test_hero", "name": "Test", "text": "", "power": power}
	hero.merge(extra, true)
	return hero


func test_passive_hero_triggers_like_a_card_2_2_7() -> void:
	var entry: Dictionary = KIT.effect("start_of_turn", {"effect": "gold", "amount": 2})
	HeroRules.assign(_player, _hero({"kind": "passive", "effects": [entry]}))
	_player.gold = 0
	_rules.start_phase(_player, 1)
	assert_eq(_player.gold, 3 + 2, "income plus the hero's 2")


func test_hero_every_n_counts_on_the_player_2_2_7() -> void:
	var hero: Dictionary = _kit.library.get_hero("sample_hoarder")
	HeroRules.assign(_player, hero)
	_rules.start_phase(_player, 1)
	assert_eq(_player.items.size(), 0, "first turn nothing")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	assert_eq(_player.items.size(), 1, "second turn an Acorn")


func test_activated_power_costs_gold_and_uses_2_2_7() -> void:
	var power: Dictionary = {
		"kind": "activated", "cost": 2, "uses_per_turn": 1, "do": {"effect": "free_refresh"}
	}
	HeroRules.assign(_player, _hero(power))
	_player.gold = 3
	assert_eq(_rules.use_power(_player), "", "used")
	assert_eq([_player.gold, _player.free_refreshes], [1, 1], "paid and worked")
	assert_eq(_rules.use_power(_player), "Already used this turn", "once")
	_rules.end_phase(_player)
	_rules.start_phase(_player, 2)
	assert_eq(_player.power_uses_left, 1, "back next turn")


func test_passive_or_no_hero_has_no_power_to_use_2_2_7() -> void:
	assert_eq(_rules.use_power(_player), "No power to use", "no hero")
	HeroRules.assign(_player, _kit.library.get_hero("sample_hoarder"))
	assert_eq(_rules.use_power(_player), "No power to use", "passive")


func test_power_needs_gold_and_a_good_aim_2_2_7() -> void:
	HeroRules.assign(_player, _kit.library.get_hero("sample_painter"))
	_player.gold = 1
	assert_eq(_rules.use_power(_player, 0), "Not enough gold", "short")
	_player.gold = 5
	assert_eq(_rules.use_power(_player, -1), "Choose a slot", "needs a slot")
	assert_eq(_player.power_uses_left, 1, "a refusal costs nothing")
	assert_eq(_rules.use_power(_player, 2), "", "painted")
	var effects: Array = _player.slot_effects[2]
	assert_eq(effects.size(), 1, "the slot has it")


func test_hero_armor_absorbs_damage_first_2_2_6() -> void:
	HeroRules.assign(_player, _hero({"kind": "passive"}, {"armor": 3}))
	var health: int = _player.health
	HeroRules.take_hero_damage(_player, 2)
	assert_eq([_player.armor, _player.health], [1, health], "armor first")
	HeroRules.take_hero_damage(_player, 4)
	assert_eq([_player.armor, _player.health], [0, health - 3], "then health")


func test_hero_health_override_2_2_5() -> void:
	HeroRules.assign(_player, _hero({"kind": "passive"}, {"health": 25}))
	assert_eq(_player.health, 25, "from the hero file")


func test_hero_start_of_combat_goes_before_units_9_3_1() -> void:
	_kit.card("post", [], [], 1, 1)
	var entry: Dictionary = KIT.effect(
		"start_of_combat",
		{"effect": "buff", "attack": 5, "health": 5, "target": {"select": "friendly"}}
	)
	var result: Dictionary = _kit.fight_with_slots(
		{0: "post"}, {0: "post"}, [{}, {}], [[entry], []]
	)
	assert_eq(result["winner"], 0, "the hero's buff decided it")


func test_refresh_cost_query() -> void:
	var base: int = _rules.refresh_cost(_player)
	_player.rule_handlers.append(_rule("refresh_cost", "add", 2))
	assert_eq(_rules.refresh_cost(_player), base + 2, "more")
	_player.rule_handlers.append(_rule("refresh_cost", "set", 0))
	assert_eq(_rules.refresh_cost(_player), 0, "then free: handlers run in order")


func test_tier_up_cost_query() -> void:
	var base: int = _rules.tier_up_cost(_player)
	_player.rule_handlers.append(_rule("tier_up_cost", "add", -1))
	assert_eq(_rules.tier_up_cost(_player), base - 1, "a coin off")
	_player.gold = base - 1
	assert_eq(_rules.tier_up(_player), "", "and the action uses it")
	assert_eq(_player.gold, 0, "charged the asked price")


func test_income_query() -> void:
	_player.rule_handlers.append(_rule("income", "add", 2))
	_player.gold = 0
	_rules.start_phase(_player, 1)
	assert_eq(_player.gold, 5, "3 + 2")


func test_shop_size_query() -> void:
	_player.rule_handlers.append(_rule("shop_size", "add", 1))
	_rules.start_phase(_player, 2)
	assert_eq(_player.shop.size(), _kit.config.get_int_at("shop_units_by_tier", 0) + 1, "one more")


func test_sell_value_query() -> void:
	_kit.card("post", [], [], 1, 1)
	_kit.put("post", 0).origin = RecruitUnit.ORIGIN_BOUGHT
	_player.rule_handlers.append(_rule("sell_value", "max", 3))
	_player.gold = 0
	_rules.sell(_player, 0)
	assert_eq(_player.gold, 3, "sells higher")


func test_rule_with_a_condition_uses_effect_conditions() -> void:
	HeroRules.assign(_player, _kit.library.get_hero("sample_thrifty"))
	assert_eq(_rules.refresh_cost(_player), 0, "first is free")
	_player.gold = 5
	_rules.refresh(_player)
	assert_eq(_rules.refresh_cost(_player), 1, "then it isn't")
	assert_eq(_rules.tier_up_cost(_player), _player.upgrade_cost + 1, "upgrades cost one more")


func test_rule_effect_for_a_turn_ends_with_the_turn() -> void:
	var entry: Dictionary = {
		"effect": "rule", "query": "refresh_cost", "op": "set", "value": 0, "duration": "turn"
	}
	_kit.spell("cheap", entry)
	_rules.give_card(_player, "cheap")
	_rules.play_item(_player, 0)
	assert_eq(_rules.refresh_cost(_player), 0, "this turn")
	_rules.end_phase(_player)
	assert_eq(_rules.refresh_cost(_player), 1, "not next")


func test_heroes_offered_never_repeat_across_players_2_2_1() -> void:
	var roster: Array[Dictionary] = []
	for index: int in 30:
		roster.append({"id": "hero_%02d" % index})
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var offers: Array = HeroRules.deal(roster, PackedStringArray(), 8, 3, rng)
	var seen: Dictionary = {}
	for offer: PackedStringArray in offers:
		assert_eq(offer.size(), 3, "three each")
		for id: String in offer:
			assert_false(seen.has(id), "no repeats")
			seen[id] = true


func test_small_roster_still_offers_distinct_heroes_to_each_player_2_2_1() -> void:
	var library := TestLibraries.current()
	var rng := RandomNumberGenerator.new()
	var offers: Array = HeroRules.deal(library.all_heroes(), PackedStringArray(), 8, 3, rng)
	for offer: PackedStringArray in offers:
		assert_eq(offer.size(), 3, "reused only across players")


func test_hero_needing_an_absent_tribe_isnt_offered_2_2_4() -> void:
	var roster: Array[Dictionary] = [{"id": "a", "requires_tribe": "oak"}, {"id": "b"}]
	var rng := RandomNumberGenerator.new()
	var offers: Array = HeroRules.deal(roster, PackedStringArray(["ash"]), 1, 3, rng)
	assert_eq(offers[0], PackedStringArray(["b"]), "only b")


func test_session_waits_for_the_hero_choice_2_2_1() -> void:
	var config := GameConfig.defaults()
	config.set_value("hero_choice", true)
	var session := GameSession.create(4, TestLibraries.current(), config)
	var state: Dictionary = session.get_state()
	assert_eq(state["phase"], "hero_choice", "first thing")
	assert_eq(state["pending_choice"]["kind"], "hero", "offered")
	assert_eq(state["pending_choice"]["options"].size(), 3, "three")
	assert_eq(session.buy(0), GameSession.CHOOSE_HERO, "nothing else yet")
	assert_eq(session.end_turn(), GameSession.CHOOSE_HERO, "not even end turn")
	assert_eq(session.choose(1), "", "chosen")
	state = session.get_state()
	assert_eq(state["phase"], "recruit", "game starts")
	assert_eq(state["round"], 1, "round 1")
	assert_not_null(state["hero"], "and the hero is shown")


func test_defaults_have_no_hero_step_2_2() -> void:
	var session := GameSession.create(4, TestLibraries.current(), GameConfig.defaults())
	assert_eq(session.get_state()["phase"], "recruit", "tests and old callers see no change")
	assert_null(session.get_state()["hero"], "no hero")
