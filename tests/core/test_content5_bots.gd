extends GutTest
@warning_ignore_start("unsafe_call_argument")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _brain: BotBrain


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_player.tier = 4
	_player.round_number = 8
	_player.health = 30
	_player.gold = 4
	_brain = BotBrain.from_name("hard:birds_summer_winter")
	_brain._player = _player
	_brain._rules = _kit.rules
	_brain.value.library = _kit.library
	_brain.value.recruit_rules = _kit.rules
	_brain.value.board_owner = _player
	_kit.put("field_vole", 3)


func _scout(units: Dictionary = {}, rings: Dictionary = {}) -> void:
	var specs: Array = []
	var slots: Array = []
	for slot: int in BoardGeometry.SLOTS:
		specs.append(units.get(slot))
		slots.append(rings.get(slot, []))
	_player.scout = {"specs": specs, "slots": slots}


func _spell(id: String) -> void:
	_player.shop_spells.append(HandItem.make(_kit.library.get_card(id), _kit.rules.new_iid()))


func _nest(slot: int, stats: int = 20) -> RecruitUnit:
	var bird := RecruitUnit.make(_kit.library.get_unit("old_tern"), _kit.rules.new_iid())
	bird.attack = stats
	bird.health = stats
	_player.away.append({"unit": bird, "nest": slot, "due": 10, "left": 7})
	return bird


func test_horseshoe_waits_for_a_scouted_ring_before_buying_or_casting() -> void:
	_spell("horseshoe")
	assert_true(_brain._best_offer().is_empty())
	_kit.rules.give_card(_player, "horseshoe")
	_brain._cast_spells(false)
	assert_true(_player.holds_item("horseshoe"), "a blind guess wastes the next-fight spell")
	_scout({}, {2: [{"name": "Hex", "attack": 80, "health": 80}]})
	assert_true(_brain._best_offer().is_empty(), "Hex is not a Ring")


func test_horseshoe_buys_and_targets_the_largest_ring_even_across_an_empty_slot() -> void:
	_scout(
		{0: {"def_id": "pill_bug", "attack": 100, "health": 100}},
		{
			0: [{"name": "Ring", "attack": 2, "health": 2}],
			5: [{"name": "Ring", "attack": 17, "health": 13}]
		}
	)
	_spell("horseshoe")
	var offer: Dictionary = _brain._best_offer()
	assert_eq(offer.get("index"), 0)
	assert_true(_brain._buy_offer(offer))
	assert_eq(_player.items.size(), 0, "used immediately after buying")
	assert_eq(_player.slot_effects[5][0]["name"], "Horseshoe")
	assert_eq(_player.gold, 3)


func test_horseshoe_does_not_spend_twice_on_the_same_ring() -> void:
	_scout({}, {1: [{"name": "Ring", "attack": 9, "health": 9}]})
	assert_eq(_kit.cast("horseshoe", 1), "")
	_spell("horseshoe")
	assert_true(_brain._best_offer().is_empty())


func test_horseshoe_chooses_the_larger_ring_when_rounding_would_tie() -> void:
	_scout(
		{},
		{
			0: [{"name": "Ring", "attack": 3, "health": 3}],
			2: [{"name": "Ring", "attack": 4, "health": 3}]
		}
	)
	var card: Dictionary = _kit.library.get_card("horseshoe")
	assert_eq(_brain._aim_for(HandItem.AIM_ANY_SLOT, card), 2)


func test_stall_buys_a_permanent_upgrade_while_healthy_and_skips_a_dead_second_stall() -> void:
	_spell("market_stall")
	var offer: Dictionary = _brain._best_offer()
	assert_true(_brain._buy_offer(offer))
	assert_eq(_player.market_stalls, 1)
	_player.tier = 6
	_player.gold = 4
	_spell("market_stall")
	assert_true(_brain._best_offer().is_empty(), "normal tier six already shows seven")


func test_stall_values_pipkins_spell_space_but_prioritizes_survival_at_low_health() -> void:
	HeroRules.assign(_player, _kit.library.get_hero("pipkin"))
	_player.tier = 6
	_player.market_stalls = 1
	_spell("market_stall")
	var offer: Dictionary = _brain._best_offer()
	assert_false(offer.is_empty(), "Pipkin receives another spell offer")
	assert_true(_brain._buy_offer(offer))
	assert_eq(_player.market_stalls, 2)
	_player.market_stalls = 0
	_player.health = BotBrain.LOW_HEALTH
	_player.gold = 4
	_spell("market_stall")
	assert_true(
		_brain._best_offer().is_empty(), "four gold of delayed choice cannot save this fight"
	)


func test_owl_values_back_row_hunts_and_the_highway_bot_buys_it() -> void:
	var owl := RecruitUnit.make(_kit.library.get_unit("barn_owl"), 900)
	_scout({0: {"def_id": "pill_bug", "attack": 20, "health": 20}})
	var empty_back: float = _brain.value.buy_value(owl, _player)
	_scout({4: {"def_id": "elder_ooze", "attack": 12, "health": 3}})
	assert_gt(_brain.value.buy_value(owl, _player), empty_back)
	_brain.value.strategy = _brain.knowledge.strategy("birds_highway")
	_kit.shop("fieldfare")
	_kit.shop("barn_owl")
	var offer: Dictionary = _brain._best_offer()
	assert_eq(offer.get("index"), 1)
	assert_true(_brain._buy_offer(offer))
	assert_true(
		_player.all_units().any(func(unit: RecruitUnit) -> bool: return unit.def_id() == "barn_owl")
	)


func test_owl_declines_loaned_quarry_and_avoids_a_front_row_mire_binding() -> void:
	_kit.put("barn_owl", 0)
	_kit.put("laird_of_sett", 4)
	_scout(
		{
			0: {"def_id": "madame_bufo", "attack": 30, "health": 30},
			1: {"def_id": "pill_bug", "attack": 1, "health": 2},
			5: {"def_id": "elder_ooze", "attack": 8, "health": 3}
		}
	)
	assert_eq(BotLanes._quarry_slot(_player, BoardSearch.identity_layout(), 0), -1)
	var layout: Array[int] = BotPlacer.rule_layout(_player, _brain.value, [])
	assert_ne(layout.find(0), 0, "Swoop remains useful outside Bufo's patch")


func test_redwing_is_bought_and_arranged_between_two_useful_eggs() -> void:
	_nest(0)
	_nest(2)
	_kit.shop("fieldfare")
	_kit.shop("redwing")
	var offer: Dictionary = _brain._best_offer()
	assert_eq(offer.get("index"), 1)
	assert_true(_brain._buy_offer(offer))
	var source: int = -1
	for slot: int in BoardGeometry.SLOTS:
		if _player.board[slot] != null and _player.board[slot].def_id() == "redwing":
			source = slot
	var layout: Array[int] = BotPlacer.rule_layout(_player, _brain.value, [])
	assert_eq(layout[1], source, "one Redwing tends both Nests")
	BotPlacer.apply_layout(_player, _kit.rules, layout)
	assert_eq(BotEggs.worth(_player, 0), 40.0)
	assert_eq(BotEggs.worth(_player, 2), 40.0)


func test_redwing_flight_cost_includes_lost_egg_support_and_support_reduces_other_flight_cost(
) -> void:
	_nest(0)
	var redwing: RecruitUnit = _kit.put("redwing", 1)
	var tern: RecruitUnit = _kit.put("old_tern", 2)
	tern.attack = 12
	tern.health = 12
	var supported: float = BotHeld.trip_score(tern, _player, _brain.value)
	assert_lt(BotHeld.trip_score(redwing, _player, _brain.value), -20.0)
	_player.board[1] = null
	assert_gt(supported, BotHeld.trip_score(tern, _player, _brain.value))


func test_redwing_replaces_a_small_recruit_when_the_only_gaps_are_strong_eggs() -> void:
	_nest(0)
	_nest(2)
	_kit.put("pill_bug", 1)
	_kit.put("marsh_frog", 4)
	_kit.put("pixie_scout", 5)
	_kit.put("carrion_crow", 6)
	_kit.shop("redwing")
	var offer: Dictionary = _brain._best_offer()
	assert_false(offer.is_empty())
	assert_true(_brain._buy_offer(offer))
	assert_eq(_player.hand.size(), 0, "the bought support is actually fielded")
	assert_true(
		_player.board.any(
			func(unit: RecruitUnit) -> bool: return unit != null and unit.def_id() == "redwing"
		)
	)
	assert_null(_player.board[0], "the large Egg stays uncovered")
	assert_null(_player.board[2], "the other large Egg stays uncovered")


func test_bird_strategies_include_the_new_cards_without_changing_their_measured_priors() -> void:
	for id: String in ["birds_highway", "birds_passage", "birds_summer_winter"]:
		var strategy: Dictionary = BotKnowledge.shared().strategy(id)
		var units: Dictionary = strategy["units"]
		assert_true(units.has("barn_owl"))
		assert_true(units.has("redwing"))
	assert_eq(BotKnowledge.shared().strategy("birds_highway")["power"], 8.0)
	assert_eq(BotKnowledge.shared().strategy("birds_passage")["power"], 3.0)
	assert_eq(BotKnowledge.shared().strategy("birds_summer_winter")["power"], 1.0)
