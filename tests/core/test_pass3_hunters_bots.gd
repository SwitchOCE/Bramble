# gdlint:disable=max-public-methods
extends GutTest
## Native Hunters keep, feed and cash real engines through the same legal actions as players.
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const KIT := preload("res://tests/core/recruit_kit.gd")
var _kit: Variant
var _player: PlayerState
var _rules: RecruitRules


func before_each() -> void:
	_kit = KIT.new()
	_kit.setup(GameConfig.full_game())
	_player = _kit.player
	_rules = _kit.rules
	_player.tier = 6
	_player.round_number = 12
	_player.gold = 10


func _brain(strategy: String = "hunters_open_season") -> BotBrain:
	_rules.board_changed(_player)
	var brain: BotBrain = BotBrain.from_name("hard:" + strategy)
	brain._player = _player
	brain._rules = _rules
	brain._round_now = _player.round_number
	brain.value.library = _kit.library
	brain.value.board_owner = _player
	brain.value.recruit_rules = _rules
	brain.value.strategy = brain.value.strategy.duplicate(true)
	brain.value.strategy["max_refreshes"] = 0
	brain.value.strategy["no_spells"] = true
	brain.level.place = BotLevel.PLACE_RULE
	return brain


func _scout(enemies: Dictionary) -> void:
	var specs: Array = []
	specs.resize(BoardGeometry.SLOTS)
	for slot: int in enemies:
		specs[slot] = enemies[slot]
	_player.scout = {
		"specs": specs,
		"views": specs,
		"slots": [[], [], [], [], [], [], []],
		"rules": {},
		"hero_effects": [],
		"tier": 6
	}


func _enemy(attack: int, health: int, id: String = "pill_bug") -> Dictionary:
	return {"def_id": id, "attack": attack, "health": health}


func _layout(brain: BotBrain) -> Array[int]:
	return BotPlacer.rule_layout(_player, brain.value, [])


func _pelt(attack: int, health: int) -> void:
	Pass3Hunters.arrival(
		_rules,
		_player,
		{
			"card": "pelt",
			"count": 1,
			"from_pool": false,
			"attack": attack,
			"health": health,
			"prey": {"id": "mrs_jay", "name": "Mrs Jay", "attack": attack * 3, "health": health * 3}
		}
	)


func test_sable_takes_the_large_trade_and_nip_the_sure_prey() -> void:
	var sable: RecruitUnit = _kit.put("sable", 0)
	var nip: RecruitUnit = _kit.put("little_nip", 1)
	nip.add_permanent(15, 15)
	_scout({0: _enemy(30, 25), 1: _enemy(1, 12)})
	var layout: Array[int] = _layout(_brain())
	assert_eq(
		layout.find(_player.board.find(sable)), 0, "the full quarry-Attack strike makes this a kill"
	)
	assert_eq(layout.find(_player.board.find(nip)), 1, "Nip collects a sure independent Take")


func test_isegrim_loan_is_hunter_only_and_never_replaces_own_quarry() -> void:
	for golden: bool in [false, true]:
		before_each()
		_kit.put("little_nip", 1)
		_kit.put("mountain_glutton", 4)
		_kit.put("old_isegrim", 5, golden)
		_kit.put("pill_bug", 6)
		_scout({1: _enemy(3, 4), 5: _enemy(100, 100)})
		var predicted: Dictionary = BotHunt.forecast(_player, [-1, 1, -1, -1, 4, 5, 6])
		assert_eq(predicted["marks"][1]["hunt_slot"], 1)
		assert_eq(predicted["marks"][4]["hunt_slot"], 5)
		assert_true(predicted["marks"][6].is_empty(), "the neutral never borrows the hunt")


func test_brock_reaches_hunter_neighbours_but_not_neutral_walls() -> void:
	_kit.put("little_nip", 1)
	_kit.put("pill_bug", 4)
	_kit.put("old_brock", 5)
	_kit.put("mountain_glutton", 6)
	_scout({1: _enemy(3, 4), 5: _enemy(80, 90)})
	var predicted: Dictionary = BotHunt.forecast(_player, [-1, 1, -1, -1, 4, 5, 6])
	assert_eq(predicted["marks"][1]["hunt_slot"], 1)
	assert_eq(predicted["marks"][6]["hunt_slot"], 5)
	assert_true(predicted["marks"][4].is_empty())


func test_front_taker_wins_the_shared_take_before_isegrim() -> void:
	_kit.put("little_nip", 2)
	_kit.put("mountain_glutton", 4)
	_kit.put("old_isegrim", 5)
	_scout({2: _enemy(50, 50)})
	var predicted: Dictionary = BotHunt.forecast(_player, [-1, -1, 2, -1, 4, 5, -1])
	var identity: int = predicted["marks"][2]["hunt_identity"]
	assert_eq(predicted["owners"][identity], 2)


func test_lodger_stands_beside_two_takers_and_search_keeps_them() -> void:
	var lodger: RecruitUnit = _kit.put("lodger", 0)
	var nip: RecruitUnit = _kit.put("little_nip", 1)
	nip.add_permanent(10, 10)
	var sable: RecruitUnit = _kit.put("sable", 3)
	_scout({0: _enemy(2, 4), 2: _enemy(4, 5)})
	var brain: BotBrain = _brain()
	var layout: Array[int] = _layout(brain)
	var next: Array[int] = BoardGeometry.adjacent(layout.find(_player.board.find(lodger)))
	assert_true(next.has(layout.find(_player.board.find(nip))))
	assert_true(next.has(layout.find(_player.board.find(sable))))
	var pins: Array[int] = BotPlacer._search_pins(_player, brain.value, layout, [])
	assert_true(pins.has(layout.find(_player.board.find(nip))))
	assert_true(pins.has(layout.find(_player.board.find(sable))))


func test_russet_forecast_prices_permanent_buffs_without_copying_ring_or_combat_buffs() -> void:
	var russet: RecruitUnit = _kit.put("mistress_russet", 0)
	var brain: BotBrain = _brain()
	var prey: Dictionary = _enemy(1000, 1000)
	prey["stat_layers"] = {
		"perm_attack": 0, "perm_health": 0, "combat_attack": 900, "combat_health": 900
	}
	var plain: float = BotHunt.poach_value(_player, brain.value, russet, prey)
	prey["attack"] = 10000
	assert_eq(BotHunt.poach_value(_player, brain.value, russet, prey), plain)
	prey["stat_layers"]["perm_attack"] = 60
	prey["stat_layers"]["perm_health"] = 60
	assert_gt(BotHunt.poach_value(_player, brain.value, russet, prey), plain)


func test_glutton_requires_a_real_take_source_on_a_non_hunter_board() -> void:
	_kit.put("mrs_burdock", 0)
	_kit.put("mr_crumb", 1)
	_kit.put("pill_bug", 2)
	var glutton: RecruitUnit = _kit.shop("mountain_glutton")
	var brain: BotBrain = _brain("hedgerow_parish")
	_scout({0: _enemy(40, 60)})
	assert_eq(BotHunt.text_value(glutton, _player, brain.value), 0.0, "no Take can pay this growth")
	_kit.put("little_nip", 3)
	assert_almost_eq(BotHunt.text_value(glutton, _player, brain.value), 200.0 / 3.0, 0.0001)
	_player.board[3] = null
	_kit.put("old_isegrim", 3)
	assert_gt(BotHunt.text_value(glutton, _player, brain.value), 0.0, "Isegrim owns a real hunt")
	_player.board[3] = null
	_kit.put("old_brock", 3)
	assert_gt(BotHunt.text_value(glutton, _player, brain.value), 0.0, "Brock can lend a real hunt")


func test_russet_purchase_values_only_eligible_scouted_permanent_layers() -> void:
	var russet: RecruitUnit = _kit.shop("mistress_russet")
	var golden := RecruitUnit.make(_kit.library.get_unit("mistress_russet"), 901, true)
	var brain: BotBrain = _brain("hedgerow_parish")
	assert_eq(BotHunt.text_value(russet, _player, brain.value), 0.0, "no scouted opportunity")
	var prey := RecruitUnit.make(_kit.library.get_unit("mrs_sorrel"), 902)
	_scout({0: prey.combat_spec()})
	_player.scout["views"][0] = prey.view()
	assert_eq(BotHunt.text_value(russet, _player, brain.value), 6.0, "an eligible paid copy")
	prey.combat_attack = 900
	prey.combat_health = 900
	prey.aura_attack = 500
	prey.aura_health = 500
	_scout({0: prey.combat_spec()})
	_player.scout["views"][0] = prey.view()
	assert_eq(BotHunt.text_value(russet, _player, brain.value), 6.0, "temporary layers never copy")
	prey.add_permanent(9, 15)
	_scout({0: prey.combat_spec()})
	_player.scout["views"][0] = prey.view()
	assert_eq(BotHunt.text_value(russet, _player, brain.value), 22.0, "B copies floor(9*2/3)+10")
	assert_eq(
		BotHunt.text_value(golden, _player, brain.value), 30.0, "gold copies all permanent buffs"
	)
	_player.tier = 1
	assert_eq(
		BotHunt.text_value(russet, _player, brain.value), 0.0, "over-tier prey cannot be copied"
	)
	_player.tier = 6
	var token := RecruitUnit.make(_kit.library.get_unit("shrewlet"), 903)
	token.add_permanent(900, 900)
	_scout({0: token.combat_spec()})
	_player.scout["views"][0] = token.view()
	assert_eq(BotHunt.text_value(russet, _player, brain.value), 0.0, "non-pool prey gives no offer")
	var mirror := RecruitUnit.make(_kit.library.get_unit("mistress_russet"), 904)
	mirror.add_permanent(9, 15)
	_scout({0: mirror.combat_spec()})
	_player.scout["views"][0] = mirror.view()
	assert_eq(
		BotHunt.text_value(russet, _player, brain.value), 22.0, "a Russet copy never recurses"
	)


func test_a_non_hunter_build_still_values_and_keeps_a_live_pack_splash() -> void:
	var grizel: RecruitUnit = _kit.put("grizel", 0)
	var leader: RecruitUnit = _kit.put("pill_bug", 1)
	leader.add_permanent(80, 80)
	var brain: BotBrain = _brain("fairies_rings")
	assert_true(BotHunt.keep_engine(_player, grizel))
	assert_gt(BotHunt.text_value(grizel, _player, brain.value), 0.0)
	var layout: Array[int] = _layout(brain)
	assert_true(
		BoardGeometry.adjacent(layout.find(_player.board.find(grizel))).has(
			layout.find(_player.board.find(leader))
		)
	)


func test_hard_spends_a_real_pelt_on_the_small_glutton_and_skips_a_huge_neutral() -> void:
	var nip: RecruitUnit = _kit.put("little_nip", 0)
	nip.add_permanent(100, 100)
	var glutton: RecruitUnit = _kit.put("mountain_glutton", 5)
	var neutral: RecruitUnit = _kit.put("pill_bug", 2)
	neutral.add_permanent(1000, 1000)
	_pelt(12, 17)
	assert_eq(_player.items.size(), 1)
	var brain: BotBrain = _brain()
	brain.play_turn(_player, _rules, _player.round_number)
	assert_true(_player.items.is_empty(), "Pelts are cashed on their arrival turn")
	assert_eq(glutton.perm_attack, 12)
	assert_eq(glutton.perm_health, 17)
	assert_eq(neutral.perm_attack, 1000)


func test_pelts_spread_to_the_smallest_taker_after_glutton_reaches_his_share() -> void:
	var glutton: RecruitUnit = _kit.put("mountain_glutton", 5)
	glutton.add_permanent(300, 300)
	var nip: RecruitUnit = _kit.put("little_nip", 0)
	nip.add_permanent(20, 20)
	var sable: RecruitUnit = _kit.put("sable", 1)
	var lutra: RecruitUnit = _kit.put("old_lutra", 4)
	lutra.add_permanent(10, 10)
	_pelt(7, 9)
	var brain: BotBrain = _brain()
	brain._cast_spells(false)
	assert_true(_player.items.is_empty())
	assert_eq(sable.perm_attack, 7)
	assert_eq(sable.perm_health, 9)
	assert_eq(glutton.perm_attack, 300)


func test_a_full_price_poached_copy_is_bought_and_keeps_its_actual_buffs() -> void:
	_player.gold = 3
	_kit.shop("sable")
	var copy: RecruitUnit = _kit.shop("pill_bug")
	copy.add_permanent(50, 50)
	copy.set("poached_offer", true)
	var brain: BotBrain = _brain()
	var offer: Dictionary = brain._best_offer()
	assert_eq(offer.get("index"), 1)
	assert_eq(offer.get("cost"), 3, "poached identity is independent of a discount")
	assert_true(brain._buy_offer(offer))
	assert_true(_player.board.has(copy))
	assert_eq(copy.perm_attack, 50)
	assert_eq(_player.gold, 0)


func test_a_triple_overrides_the_copy_size_threshold() -> void:
	_kit.put("pill_bug", 0)
	_kit.put("pill_bug", 1)
	var other: RecruitUnit = _kit.shop("sable")
	other.add_permanent(100, 100)
	var copy: RecruitUnit = _kit.shop("pill_bug")
	copy.set("poached_offer", true)
	var brain: BotBrain = _brain()
	assert_true(BotHunt.wants_poached(_player, copy))
	assert_eq(brain._best_offer().get("index"), 1)


func test_replacement_sale_moves_a_grown_hunter_beside_his_heir_and_cashes_it() -> void:
	var heir: RecruitUnit = _kit.put("young_brock", 0)
	heir.add_permanent(100, 100)
	for slot: int in range(1, 6):
		var id: String = _kit.card("heir_filler_%d" % slot, [], [], 1000, 1000)
		_kit.put(id, slot)
	var old: RecruitUnit = _kit.put("mistress_russet", 6)
	old.add_permanent(20, 20)
	_player.tribe_bonuses["Hunters"] = 7
	var replacement: RecruitUnit = _kit.put("laird_of_sett")
	replacement.add_permanent(300, 300)
	var brain: BotBrain = _brain()
	var inherited: Vector2i = Vector2i(old.attack - old.tribe_attack, old.health - old.tribe_health)
	var before: Vector2i = Vector2i(heir.perm_attack, heir.perm_health)
	brain._play_hand()
	assert_false(_player.board.has(old))
	assert_true(_player.board.has(replacement))
	assert_eq(Vector2i(heir.perm_attack, heir.perm_health), before + inherited)
	assert_eq(_player.board_count(), 7)


func test_pack_engine_is_retained_and_its_real_take_and_pack_rewards_land_next_turn() -> void:
	var nip: RecruitUnit = _kit.put("little_nip", 0)
	nip.add_permanent(20, 20)
	var wick: RecruitUnit = _kit.put("wick", 1)
	wick.add_permanent(10, 10)
	var glutton: RecruitUnit = _kit.put("mountain_glutton", 5)
	var grizel: RecruitUnit = _kit.put("grizel", 6)
	_scout({0: _enemy(6, 6)})
	var brain: BotBrain = _brain("hunters_pact")
	assert_true(BotHunt.keep_engine(_player, glutton))
	assert_true(BotHunt.keep_engine(_player, grizel))
	brain.play_turn(_player, _rules, _player.round_number)
	assert_true(_player.board.has(glutton))
	assert_true(_player.board.has(grizel))
	var nip_slot: int = _player.board.find(nip)
	assert_true(BoardGeometry.adjacent(nip_slot).has(_player.board.find(wick)))
	_kit.fight_board({nip_slot: _enemy(6, 6)}, 1)
	assert_eq(nip.perm_attack, 20, "pending rewards do not grow the fighting body")
	assert_eq(glutton.perm_attack, 0)
	assert_gt(_player.pending_gains.size(), 0)
	_rules.start_phase(_player, 13)
	assert_gt(nip.perm_attack, 20)
	assert_gt(wick.perm_attack, 10, "the retained Grizel feeds a real pack kill")
	assert_gt(glutton.perm_attack, 0)


func test_open_season_keeps_its_small_engines_and_laird_doubles_take_text_only() -> void:
	var nip: RecruitUnit = _kit.put("little_nip", 0)
	nip.add_permanent(30, 30)
	var glutton: RecruitUnit = _kit.put("mountain_glutton", 4)
	var laird: RecruitUnit = _kit.put("laird_of_sett", 5)
	var ermeline: RecruitUnit = _kit.put("madame_ermeline", 3)
	var brain: BotBrain = _brain()
	assert_true(BotHunt.keep_engine(_player, laird))
	assert_true(BotHunt.keep_engine(_player, ermeline))
	brain.play_turn(_player, _rules, _player.round_number)
	assert_true(_player.board.has(laird))
	assert_true(_player.board.has(ermeline))
	var slot: int = _player.board.find(nip)
	_kit.fight_board({slot: _enemy(12, 15)}, 1)
	_rules.start_phase(_player, 13)
	assert_gt(glutton.perm_attack, 0)
	assert_gt(
		nip.perm_attack - 30,
		glutton.perm_attack,
		"Laird repeats Nip's Take but not Glutton's after-Take reward"
	)
	assert_gt(
		_player.items.size(), 0, "the retained Ermeline supplies a Pelt even after this fight"
	)
	var before: int = nip.perm_attack + glutton.perm_attack + laird.perm_attack
	brain = _brain()
	brain._cast_spells(false)
	assert_true(_player.items.is_empty())
	assert_gt(nip.perm_attack + glutton.perm_attack + laird.perm_attack, before)
