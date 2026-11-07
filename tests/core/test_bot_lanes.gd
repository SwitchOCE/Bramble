# gdlint: disable=max-public-methods
extends GutTest
## Lane assignments, stable scout landmarks and tribe-specific bot shopping.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: KIT
var _player: PlayerState
var _value: BotEval


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_player.tier = 4
	_value = BotEval.make(BotLevel.of(BotLevel.HARD), BotKnowledge.shared())
	_value.library = _kit.library


func _scout(enemies: Dictionary, nests: Array = []) -> void:
	var specs: Array = []
	specs.resize(BoardGeometry.SLOTS)
	for slot: int in enemies:
		specs[slot] = enemies[slot]
	_player.scout = {
		"specs": specs,
		"views": specs,
		"slots": [[], [], [], [], [], [], []],
		"hero_effects": [],
		"rules": {},
		"tier": 4,
		"nests": nests
	}


func _enemy(attack: int, health: int, id: String = "pill_bug") -> Dictionary:
	return {"def_id": id, "attack": attack, "health": health}


func _layout() -> Array[int]:
	return BotPlacer.rule_layout(_player, _value, BotPlacer.pinned_slots(_player))


func test_six_builds_are_distinct_and_only_open_when_their_tribe_is_present() -> void:
	var known: BotKnowledge = BotKnowledge.shared()
	var expected: Array[String] = [
		"bog_bitter",
		"bog_tongues",
		"bog_borrowed",
		"hunters_open_season",
		"hunters_sett",
		"hunters_pact"
	]
	for id: String in expected:
		var strategy: Dictionary = known.strategy(id)
		assert_false(strategy.is_empty(), id)
		assert_false(BotKnowledge.tribes_available(strategy, ["Birds"]), id)
		assert_true(BotKnowledge.tribes_available(strategy, strategy["needs_tribes"]), id)
	assert_ne(known.strategy("hunters_sett")["units"], known.strategy("hunters_pact")["units"])
	assert_ne(known.strategy("bog_bitter")["units"], known.strategy("bog_tongues")["units"])


func test_every_new_pool_card_has_an_explicit_text_value() -> void:
	for card: Dictionary in _kit.library.pool_units("slice"):
		var tribes: Array = card["tribes"]
		if tribes.has("Bog folk") or tribes.has("Hunters"):
			assert_true(BotKnowledge.shared().card(str(card["id"])).has("keep"), str(card["id"]))


func test_nip_and_sable_choose_different_front_quarries() -> void:
	_kit.put("little_nip", 0)
	_kit.put("sable", 1)
	_scout({0: _enemy(10, 5), 1: _enemy(1, 2)})
	var layout: Array[int] = _layout()
	assert_eq(layout[1], 0, "Nip can kill the small quarry")
	assert_eq(layout[0], 1, "Sable earns her bonus on the larger attacker")


func test_toll_bard_keeps_the_durable_enemy_for_its_attacks() -> void:
	_kit.put("little_nip", 0)
	_kit.put("toll_bard", 1)
	_scout({0: _enemy(12, 40), 1: _enemy(1, 2)})
	var layout: Array[int] = _layout()
	assert_eq(layout[0], 1, "the Bard's quarry will survive to pay several times")
	assert_eq(layout[1], 0, "Nip trades with the small unit")


func test_russet_prefers_the_pool_card_that_completes_a_triple() -> void:
	_kit.put("mistress_russet", 0)
	_kit.put("pill_bug")
	_kit.put("pill_bug")
	_scout({0: _enemy(1, 2, "mr_crumb"), 2: _enemy(1, 2, "pill_bug")})
	var layout: Array[int] = _layout()
	assert_eq(layout[2], 0, "a wanted card, rather than the largest stat line")


func test_russet_does_not_chase_created_or_too_high_tier_cards() -> void:
	_player.tier = 2
	_kit.put("mistress_russet", 0)
	_scout({0: _enemy(1, 1, "prince_restored"), 1: _enemy(1, 1, "peat_king"), 2: _enemy(1, 1)})
	assert_eq(_layout()[2], 0, "only the pool card at our tier can be poached")


func test_bufo_takes_the_giant_lane() -> void:
	_kit.put("madame_bufo", 0)
	_kit.put("gideon", 1)
	_scout({0: _enemy(3, 4), 2: _enemy(30, 40)})
	assert_eq(_layout()[2], 0, "Bufo's death cripples the giant")


func test_snap_build_places_a_mirer_across_the_protected_carry() -> void:
	_kit.put("madame_bufo", 0)
	_kit.put("vaulting_hopkin", 4)
	_scout({0: _enemy(3, 4), 5: _enemy(18, 8)})
	var layout: Array[int] = _layout()
	assert_eq(layout[5], 0, "the back carry is Mired for Hopkin")
	assert_true(BoardGeometry.is_back(layout.find(4)), "Hopkin keeps his early back-row attack")


func test_mirers_avoid_empty_nests_and_combat_eggs() -> void:
	_kit.put("madame_bufo", 0)
	_kit.put("vaulting_hopkin", 4)
	_scout({1: _enemy(4, 6), 5: {"def_id": HeldUnits.EGG, "egg": true}}, [0, 5])
	var layout: Array[int] = _layout()
	assert_eq(layout[1], 0, "an attacking enemy is worth catching; an Egg is harmless")


func test_brother_wolf_stands_between_two_quarry_leaders() -> void:
	_kit.put("brother_wolf", 0)
	_kit.put("sable", 1)
	_kit.put("little_nip", 3)
	var layout: Array[int] = _layout()
	var wolf: int = layout.find(0)
	assert_eq(BoardGeometry.adjacent(wolf).size(), 2, "the wolf can join twice")
	assert_true(BoardGeometry.adjacent(wolf).has(layout.find(1)))
	assert_true(BoardGeometry.adjacent(wolf).has(layout.find(3)))


func test_old_brock_uses_b2_to_lend_reach_to_four_borrowers() -> void:
	_kit.put("old_brock", 4)
	_kit.put("wick", 0)
	_kit.put("lodger", 1)
	_kit.put("mountain_glutton", 5)
	_kit.put("madame_ermeline", 6)
	_scout({0: _enemy(3, 6), 4: _enemy(1, 3), 5: _enemy(25, 20), 6: _enemy(1, 3)})
	var layout: Array[int] = _layout()
	assert_eq(layout[5], 4, "B2 has four neighbours and faces their carry")
	var borrowers: int = 0
	for slot: int in BoardGeometry.neighbours(5):
		if layout[slot] >= 0 and BotLanes._quarry_slot(_player, layout, slot) == 5:
			borrowers += 1
	assert_eq(borrowers, 4, "all four attacks can use Brock's back-row mark")


func test_lane_assignment_respects_a_pinned_mirer() -> void:
	var toad: RecruitUnit = _kit.put("madame_bufo", 0)
	_player.bands[0] = toad.iid
	_scout({0: _enemy(1, 2), 2: _enemy(30, 30)})
	assert_eq(_layout()[0], 0, "the band still pins the unit")


func test_lane_assignment_keeps_a_nest_dependent_unit_on_its_nest() -> void:
	_kit.put("great_lump", 1)
	_kit.put("madame_bufo", 0)
	var bird := RecruitUnit.make(_kit.library.get_unit("old_tern"), 900)
	_player.away.append({"unit": bird, "nest": 1, "due": 7, "left": 2})
	_scout({0: _enemy(1, 2), 1: _enemy(30, 30), 2: _enemy(10, 10)})
	var layout: Array[int] = _layout()
	assert_eq(layout[1], 1, "the Lump cannot leave its Nest for Bufo's matchup")
	assert_eq(layout[2], 0, "Bufo takes the best available lane")


func test_generic_carry_stays_in_place_and_is_protected_from_noisy_search() -> void:
	_kit.put("pill_bug", 0)
	_kit.put("earwig_mother", 1)
	_kit.put("mrs_sorrel", 2)
	var carry: RecruitUnit = _kit.put("alderman_dozey", 6)
	carry.perm_attack = 40
	carry.perm_health = 40
	_scout({0: _enemy(3, 6), 1: _enemy(2, 4), 6: _enemy(20, 20)})
	for _round: int in 3:
		var layout: Array[int] = _layout()
		assert_eq(layout[6], 6, "a carry remains a useful scout landmark")
		assert_has(BotPlacer._search_pins(_player, _value, layout, []), 6)
		BotPlacer.apply_layout(_player, _kit.rules, layout)


func test_all_eight_seats_receive_their_next_opponents_last_board() -> void:
	var config: GameConfig = GameConfig.full_game()
	config.set_value("human_bot", "hard")
	config.set_value("bots", ["hard", "hard", "hard", "hard", "hard", "hard", "hard"])
	var session: GameSession = GameSession.create(56, _kit.library, config)
	assert_eq(session.end_turn(), "")
	for player: PlayerState in session._players:
		assert_false(
			player.scout.is_empty(), "seat %d sees the opponent it is about to fight" % player.id
		)
		var opponent: int = session._opponent_of(player.id)
		assert_eq(player.scout["specs"], session._players[opponent].fought_specs)


func test_poached_shop_price_is_used_for_affordability_and_value_per_gold() -> void:
	_player.gold = 1
	_player.shop.clear()
	_kit.shop("sable")
	var poached: RecruitUnit = _kit.shop("little_nip")
	poached.poached_discount = 2
	var brain: BotBrain = BotBrain.from_name("hard:hunters_open_season")
	brain._player = _player
	brain._rules = _kit.rules
	var offer: Dictionary = brain._best_offer()
	assert_false(offer.is_empty(), "one gold buys the discounted card")
	assert_eq(offer.get("index"), 1)
	assert_eq(offer.get("cost"), 1)
	assert_true(brain._buy_offer(offer), "the evaluated offer is also legal to buy")


func test_each_build_actually_buys_its_core_card_from_a_mixed_shop() -> void:
	var choices: Dictionary = {
		"bog_bitter": ["gideon", "old_lutra"],
		"bog_tongues": ["vaulting_hopkin", "madame_bufo"],
		"bog_borrowed": ["natterjack_chorus", "gideon"],
		"hunters_open_season": ["mistress_russet", "madame_bufo"],
		"hunters_sett": ["old_brock", "madame_ermeline"],
		"hunters_pact": ["brother_wolf", "old_lutra"]
	}
	for id: String in choices:
		before_each()
		_player.shop.clear()
		_player.shop_spells.clear()
		_player.gold = 3
		_player.upgrade_cost = 99
		_player.round_number = 5
		var cards: Array = choices[id]
		_kit.shop(str(cards[1]))
		_kit.shop(str(cards[0]))
		var brain: BotBrain = BotBrain.from_name("hard:%s" % id)
		brain.play_turn(_player, _kit.rules, 5)
		var bought: Array[String] = []
		for unit: RecruitUnit in _player.owned_units():
			bought.append(unit.def_id())
		assert_has(bought, str(cards[0]), "%s buys the card its engine needs" % id)


func test_laird_keeps_own_quarries_and_gives_other_units_their_own_lane() -> void:
	_kit.put("laird_of_sett", 4)
	_kit.put("sable", 0)
	_kit.put("pill_bug", 1)
	_kit.put("wick", 2)
	_scout({0: _enemy(8, 6), 1: _enemy(4, 6), 2: _enemy(3, 6), 4: _enemy(1, 6)})
	var layout: Array[int] = [0, 1, 2, -1, 4, -1, -1]
	for slot: int in [0, 1, 2, 4]:
		assert_eq(BotLanes._quarry_slot(_player, layout, slot), slot, "own lane, not the Laird's")


func test_old_brock_does_not_replace_a_hunters_own_front_quarry() -> void:
	_kit.put("old_brock", 5)
	_kit.put("sable", 1)
	_kit.put("wick", 2)
	_scout({1: _enemy(8, 6), 5: _enemy(20, 20)})
	var layout: Array[int] = [-1, 1, 2, -1, -1, 5, -1]
	assert_eq(BotLanes._quarry_slot(_player, layout, 1), 1, "Sable keeps her own quarry")
	assert_eq(BotLanes._quarry_slot(_player, layout, 2), 5, "Wick borrows Brock's")


func test_poach_and_belly_discounts_are_both_counted_before_buying() -> void:
	_player.gold = 0
	_player.shop.clear()
	var ooze: RecruitUnit = _kit.put("little_dollop", 0)
	_kit.put("mrs_sorrel", 1)
	var poached: RecruitUnit = _kit.shop("little_nip")
	poached.poached_discount = 2
	var brain: BotBrain = BotBrain.from_name("hard:hunters_open_season")
	brain._player = _player
	brain._rules = _kit.rules
	var offer: Dictionary = brain._best_offer()
	assert_false(offer.is_empty(), "the two discounts make this purchase free")
	assert_eq(offer.get("cost"), 0)
	assert_true(brain._buy_offer(offer))
	assert_eq(ooze.held.size(), 1, "the evaluated Belly route is the one actually used")
	assert_eq(_player.gold, 0)
