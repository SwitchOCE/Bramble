# gdlint:disable=max-public-methods
extends GutTest
## Hard uses legal turns while keeping Bog's positional growth engine alive.
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
	_player.round_number = 12
	_player.tier = 6
	_player.gold = 10


func _brain(strategy: String = "bog_tongues") -> BotBrain:
	_rules.board_changed(_player)
	var brain: BotBrain = BotBrain.from_name("hard:" + strategy)
	brain._player = _player
	brain._rules = _rules
	brain._round_now = _player.round_number
	brain.value.library = _rules.library
	brain.value.recruit_rules = _rules
	brain.value.board_owner = _player
	brain.value.strategy = brain.value.strategy.duplicate(true)
	brain.value.strategy["max_refreshes"] = 0
	brain.value.strategy["no_spells"] = true
	brain.level.place = BotLevel.PLACE_RULE
	return brain


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
		"tier": 6,
		"nests": nests
	}


func _enemy(attack: int, health: int, id: String = "pill_bug") -> Dictionary:
	return {"def_id": id, "attack": attack, "health": health}


func _layout(brain: BotBrain) -> Array[int]:
	return BotPlacer.rule_layout(_player, brain.value, BotPlacer.pinned_slots(_player))


func _slot_of(layout: Array[int], unit: RecruitUnit) -> int:
	return layout.find(_player.board.find(unit))


func test_soak_faces_a_real_attacker_instead_of_an_egg_or_zero_attack_wall() -> void:
	var toad: RecruitUnit = _kit.put("bridge_toad", 1)
	_scout({0: _enemy(0, 100, HeldUnits.EGG), 2: _enemy(24, 50), 5: _enemy(0, 500)}, [0])
	assert_eq(_slot_of(_layout(_brain()), toad), 2)


func test_safe_carry_drinks_the_giant_but_bufo_takes_a_lethal_giant() -> void:
	var diva: RecruitUnit = _kit.put("gideon", 0)
	diva.add_permanent(60, 60)
	var bufo: RecruitUnit = _kit.put("madame_bufo", 1)
	var brain: BotBrain = _brain()
	_scout({0: _enemy(40, 500), 2: _enemy(10, 500)})
	assert_eq(_slot_of(_layout(brain), diva), 0, "surviving the bite pays the carry's own Soak")
	_scout({0: _enemy(200, 500), 2: _enemy(10, 500)})
	assert_eq(_slot_of(_layout(brain), bufo), 0, "more than twice the Diva's Health calls for Bufo")


func test_court_keeps_its_carry_between_tiddy_and_the_frog() -> void:
	var tiddy: RecruitUnit = _kit.put("tiddy_mun", 0)
	var diva: RecruitUnit = _kit.put("gideon", 1)
	diva.add_permanent(100, 100)
	var frog: RecruitUnit = _kit.put("prince_restored", 2)
	_kit.put("warty_nan", 3)
	var hopkin: RecruitUnit = _kit.put("vaulting_hopkin", 5)
	_scout({1: _enemy(30, 500), 3: _enemy(8, 30)})
	var brain: BotBrain = _brain()
	var layout: Array[int] = _layout(brain)
	assert_eq(_slot_of(layout, tiddy), 0)
	assert_eq(_slot_of(layout, diva), 1)
	assert_eq(_slot_of(layout, frog), 2)
	assert_true(BoardGeometry.in_front_of(_slot_of(layout, hopkin)).has(_slot_of(layout, diva)))
	BotPlacer.apply_layout(_player, _rules, layout)
	assert_eq(_slot_of(_layout(brain), diva), 1, "the next arrange keeps a useful scout landmark")


func test_swamp_tiddy_shares_between_two_soak_units() -> void:
	var tiddy: RecruitUnit = _kit.put("tiddy_mun", 0)
	_kit.put("bridge_toad", 1)
	_kit.put("gideon", 2)
	var layout: Array[int] = _layout(_brain("bog_bitter"))
	var neighbours: int = 0
	for slot: int in BoardGeometry.adjacent(_slot_of(layout, tiddy)):
		if layout[slot] >= 0 and BotBog.has(_player.board[layout[slot]], "soak"):
			neighbours += 1
	assert_eq(neighbours, 2)


func test_chorus_lends_to_the_two_largest_unsoaked_bog_units() -> void:
	var nan: RecruitUnit = _kit.put("warty_nan", 0)
	nan.add_permanent(30, 30)
	_kit.put("bridge_toad", 1)
	var bufo: RecruitUnit = _kit.put("madame_bufo", 2)
	bufo.add_permanent(20, 20)
	_kit.put("gideon", 3)
	var chorus: RecruitUnit = _kit.put("natterjack_chorus", 4)
	_scout({0: _enemy(15, 60), 2: _enemy(20, 60), 3: _enemy(10, 60)})
	var layout: Array[int] = _layout(_brain("bog_borrowed"))
	var adjacent: Array[int] = BoardGeometry.adjacent(_slot_of(layout, chorus))
	assert_true(adjacent.has(_slot_of(layout, nan)))
	assert_true(adjacent.has(_slot_of(layout, bufo)))
	var pins: Array[int] = BotPlacer._search_pins(_player, _brain("bog_borrowed").value, layout, [])
	assert_true(pins.has(_slot_of(layout, nan)), "combat search keeps the lender's live recipients")
	assert_true(pins.has(_slot_of(layout, bufo)))


func test_frog_favours_the_largest_neighbour_including_other_tribes() -> void:
	var frog: RecruitUnit = _kit.put("his_highness", 0)
	var diva: RecruitUnit = _kit.put("gideon", 2)
	diva.add_permanent(100, 100)
	var neutral: RecruitUnit = _kit.put("pill_bug", 3)
	neutral.add_permanent(1000, 1000)
	_kit.put("bridge_toad", 4)
	_player.bog_kisses = 2
	var layout: Array[int] = _layout(_brain())
	assert_true(BoardGeometry.adjacent(_slot_of(layout, frog)).has(_slot_of(layout, neutral)))


func test_jenny_pulls_the_next_target_after_lantern_lures_the_biggest() -> void:
	_kit.put("lantern_man", 0)
	_kit.put("jenny_greenteeth", 4)
	_scout({1: _enemy(100, 100), 4: _enemy(10, 10), 5: _enemy(80, 80)})
	var layout: Array[int] = [0, -1, -1, -1, 4, -1, -1]
	var predicted: Dictionary = BotBog.forecast(_player, layout)
	assert_eq(predicted["patches"][1], 0)
	assert_eq(predicted["enemies"][4]["attack"], 80)
	assert_eq(predicted["patches"][4], 4)


func test_jenny_chooses_the_row_with_the_best_enemy_lantern_leaves() -> void:
	_kit.put("lantern_man", 0)
	var jenny: RecruitUnit = _kit.put("jenny_greenteeth", 1)
	_scout({0: _enemy(200, 200), 1: _enemy(2, 2), 6: _enemy(90, 90)})
	assert_true(BoardGeometry.is_back(_slot_of(_layout(_brain()), jenny)))


func test_hidden_lantern_target_stays_an_identity_and_jenny_pulls_another_enemy() -> void:
	_kit.put("lantern_man", 0)
	_kit.put("jenny_greenteeth", 4)
	var belly: Dictionary = _enemy(3, 3)
	belly["held"] = [_enemy(200, 200, "gideon")]
	_scout({4: belly, 5: _enemy(80, 80)})
	var layout: Array[int] = [0, -1, -1, -1, 4, -1, -1]
	var predicted: Dictionary = BotBog.forecast(_player, layout)
	assert_eq(predicted["pending"].size(), 1)
	assert_eq(predicted["pending"][0]["enemy"]["def_id"], "gideon")
	assert_eq(predicted["pending"][0]["ability"], "lantern")
	assert_eq(predicted["enemies"][4]["attack"], 80)
	assert_eq(predicted["patches"][4], 4, "the hidden lure does not steal its holder's patch")


func test_hopkin_stands_behind_the_big_front_attacker() -> void:
	var diva: RecruitUnit = _kit.put("gideon", 3)
	diva.add_permanent(100, 100)
	var hopkin: RecruitUnit = _kit.put("vaulting_hopkin", 4)
	_kit.put("bridge_toad", 0)
	var layout: Array[int] = _layout(_brain())
	assert_true(BoardGeometry.is_back(_slot_of(layout, hopkin)))
	assert_true(BoardGeometry.in_front_of(_slot_of(layout, hopkin)).has(_slot_of(layout, diva)))


func test_court_holds_highness_only_until_twice_median_or_round_ten() -> void:
	var toad: RecruitUnit = _kit.put("bridge_toad", 0)
	_kit.put("warty_nan", 1)
	_kit.put("madame_bufo", 2)
	var frog: RecruitUnit = _kit.put("his_highness")
	_player.round_number = 7
	var brain: BotBrain = _brain()
	brain._play_hand()
	assert_true(_player.hand.has(frog))
	toad.add_permanent(10, 10)
	brain._play_hand()
	assert_true(_player.board.has(frog), "a useful neighbour releases the first frog immediately")
	assert_false(
		BotBog.hold_frog(_player, _kit.put("his_highness"), brain.value),
		"a live frog already advances the shared count"
	)


func test_round_ten_and_swamp_never_delay_highness_for_the_hold_rule() -> void:
	_kit.put("bridge_toad", 0)
	_kit.put("warty_nan", 1)
	var frog: RecruitUnit = _kit.put("his_highness")
	_player.round_number = 9
	assert_false(BotBog.hold_frog(_player, frog, _brain("bog_bitter").value))
	_player.round_number = 10
	var brain: BotBrain = _brain()
	brain._play_hand()
	assert_true(_player.board.has(frog))


func test_a_legal_shopping_turn_keeps_the_toll_engine_frog_and_grown_carry() -> void:
	var tiddy: RecruitUnit = _kit.put("tiddy_mun", 0)
	var diva: RecruitUnit = _kit.put("gideon", 1)
	diva.add_permanent(80, 80)
	var frog: RecruitUnit = _kit.put("his_highness", 2)
	_kit.put("bridge_toad", 3)
	_kit.put("young_pretender", 4)
	_kit.put("peat_cutter", 5)
	_kit.put("spitfire_sal", 6)
	_kit.shop("prima_donna")
	_kit.shop("jenny_greenteeth")
	_kit.shop("lantern_man")
	_player.bog_toll = 30
	_player.bog_kisses = 2
	var buys: int = _player.units_bought
	var brain: BotBrain = _brain()
	brain.play_turn(_player, _rules, _player.round_number)
	assert_true(_player.board.has(tiddy))
	assert_true(_player.board.has(diva))
	assert_true(_player.board.has(frog))
	assert_gt(_player.units_bought, buys, "the bot still makes a legal upgrade around its engine")
	assert_gte(_player.gold, 0)
	assert_lte(_player.board_count(), BoardGeometry.SLOTS)
	assert_false(_player.is_choosing())


func test_retained_engine_cashes_an_actual_bite_toll_and_third_kiss() -> void:
	var tiddy: RecruitUnit = _kit.put("tiddy_mun", 0)
	var diva: RecruitUnit = _kit.put("gideon", 1)
	diva.add_permanent(100, 100)
	_kit.put("his_highness", 2)
	_player.bog_kisses = 2
	var brain: BotBrain = _brain()
	brain.play_turn(_player, _rules, _player.round_number)
	var before: int = diva.perm_attack
	_kit.fight_board({1: _enemy(100, 100)}, 1)
	assert_gt(_player.bog_toll, 0)
	assert_eq(_player.bog_kisses, 3)
	assert_gt(diva.perm_attack, before, "the retained frog doubles the adjacent carry in combat")
	var after_kiss: int = diva.perm_attack
	_kit.pass_turn()
	assert_true(_player.board.has(tiddy))
	assert_gt(
		diva.perm_attack, after_kiss, "the next turn pays both its Soak and adjacent Tiddy Toll"
	)


func test_king_does_not_make_the_bot_sell_a_strong_body_for_an_empty_slot() -> void:
	_kit.put("peat_king", 0)
	for slot: int in range(1, BoardGeometry.SLOTS):
		var unit: RecruitUnit = _kit.put("bridge_toad", slot)
		unit.add_permanent(30 + slot, 30 + slot)
	var owned: Array[RecruitUnit] = _player.board.duplicate()
	var brain: BotBrain = _brain("bog_bitter")
	brain.play_turn(_player, _rules, _player.round_number)
	assert_eq(_player.board_count(), BoardGeometry.SLOTS)
	for unit: RecruitUnit in owned:
		assert_true(_player.board.has(unit))


func test_king_can_cash_a_cheap_body_for_a_valuable_scouted_early_sink() -> void:
	var ids: Array[String] = [
		"peat_king",
		"gideon",
		"warty_nan",
		"bridge_toad",
		"tiddy_mun",
		"his_highness",
		"young_pretender"
	]
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = _kit.put(ids[slot], slot)
		if slot < 4:
			unit.add_permanent(100, 100)
	_player.board[6].origin = RecruitUnit.ORIGIN_BOUGHT
	_scout({1: _enemy(30, 30)})
	var brain: BotBrain = _brain()
	var gold: int = _player.gold
	BotBog.prepare_fight(brain)
	assert_null(_player.board[6])
	assert_eq(_player.board_count(), 6)
	assert_gt(_player.gold, gold, "the gap uses the real sale action")
