extends GutTest
## C15: free moves preserve the copy, hand sales share listeners, and working commits sources.

@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/core_kit.gd")
const Locust := preload("res://src/content/locust/lib/locust.gd")
const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


class PriceModifier:
	extends Mechanic
	var query: StringName
	var delta: int

	func modify_int(
		q: StringName, value: int, _p: PlayerState, _u: Unit, _params: MechanicParams
	) -> int:
		return value + delta if q == query else value


var game: GameSession
var p: PlayerState


func before_each() -> void:
	game = Kit.content([], false, true).session(25)
	game.start_round()
	p = game.player(0)
	p.gold = 100


func _hand(id: String, bought: int = 1) -> Unit:
	var unit: Unit = game.new_unit(game.library.get_card(StringName(id)), false)
	unit.bought_copies = bought
	p.hand.append(unit)
	return unit


func _modifier(query: StringName, delta: int, slot: int = 0) -> Unit:
	var unit: Unit = Kit.put(game, p, "brock-cub", slot)
	var effect := PriceModifier.new()
	effect.query = query
	effect.delta = delta
	var id := StringName("core_test_price_%d" % slot)
	assert_true(game.registry.register(id, effect))
	unit.mechanics.append(game.registry.bind(MechanicSpec.new(id), false, true))
	return unit


func test_board_to_hand_preserves_origin_buffs_grants_and_turn_counters_without_recruit() -> void:
	var unit: Unit = Kit.put(game, p, "harvest-piper", 0)
	var mouse: Unit = Kit.put(game, p, "needle-page", 1)
	unit.bought_copies = 2
	unit.stats.perm_attack = 7
	unit.stats.turn_health = 4
	unit.counters[&"core_test_counter"] = 2
	unit.turn_counters[&"ability:pigeon_lance_corporal"] = 1
	assert_true(unit.grant_effect(game.registry, &"badger_fury", {"fury": 3}))
	var gold: int = p.gold
	for i: int in 3:
		assert_eq(game.act(p.id, {"type": "to_hand", "slot": 0}), "")
		assert_null(p.board[0])
		assert_eq(p.hand[0], unit)
		assert_eq(unit.slot, -1)
		assert_eq(unit.bought_copies, 2)
		assert_eq([unit.stats.perm_attack, unit.stats.turn_health], [7, 4])
		assert_eq(unit.counter(&"core_test_counter"), 2)
		assert_eq(unit.turn_counter(&"ability:pigeon_lance_corporal"), 1)
		assert_true(unit.has_mechanic(&"badger_fury"))
		assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 0}), "")
	assert_eq(p.gold, gold)
	assert_eq(mouse.attack(), 4, "moving and replaying Piper never recruits it")
	assert_eq(Kit.log_of(game, "gain").size(), 0)


func test_full_hand_refuses_return_without_changing_the_board() -> void:
	var unit: Unit = Kit.put(game, p, "brock-cub", 0)
	for i: int in 7:
		_hand("needle-page")
	assert_eq(game.act(p.id, {"type": "to_hand", "slot": 0}), "hand is full")
	assert_eq(p.board[0], unit)
	assert_eq(p.hand.size(), 7)
	assert_eq(Kit.log_of(game, "to_hand").size(), 0)
	assert_false(
		game.legal_actions(p.id).any(func(a: Dictionary) -> bool: return a["type"] == "to_hand")
	)


func test_hand_sale_matches_bought_created_and_mixed_golden_board_values() -> void:
	for bought: int in [0, 1, 2, 3]:
		var unit: Unit = _hand("master-at-arms", bought)
		unit.golden = bought > 1
		var expected: int = game.rules.sell_value(p, unit)
		var gold: int = p.gold
		assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
		assert_eq(p.gold, gold + expected)
		assert_eq(expected, bought * 2)
		assert_true(p.hand.is_empty())
	_hand("sp_sharpen")
	var spell_gold: int = p.gold
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "spells can't be sold")
	assert_eq(p.gold, spell_gold)
	assert_eq(p.hand.size(), 1)


func test_hand_sales_feed_gorger_glutton_compost_and_sweetbriar() -> void:
	var gorger: Unit = Kit.put(game, p, "gorger", 0)
	var glutton: Unit = Kit.put(game, p, "granary-glutton", 1)
	var briar: Unit = Kit.put(game, p, "sweetbriar", 2)
	_hand("green-recruit")
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(gorger.turn_counter(Locust.ATE), 1)
	assert_true(gorger.worked_this_turn)
	assert_true(briar.worked_this_turn)
	assert_false(glutton.worked_this_turn, "the same sale is eaten only once")
	assert_eq(p.heap(Compost.HEAP).size(), 1)
	_hand("green-recruit")
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_true(glutton.worked_this_turn)
	assert_eq(p.heap(Compost.HEAP).size(), 2)
	assert_gt(p.board_count(), 3, "sold hand unit's death summons still resolve")


func test_order_locks_its_source_but_a_locked_unit_can_still_be_sold() -> void:
	var officer: Unit = Kit.put(game, p, "lance-corporal", 4)
	assert_eq(
		game.act(
			p.id, {"type": "ability", "uid": officer.uid, "mechanic": "pigeon_lance_corporal"}
		),
		""
	)
	assert_true(officer.worked_this_turn)
	assert_eq(officer.turn_counter(&"ability:pigeon_lance_corporal"), 1)
	assert_eq(
		game.act(p.id, {"type": "to_hand", "slot": 4}), "Worked this turn: stays for the fight."
	)
	assert_eq(p.board[4], officer)
	assert_eq(game.act(p.id, {"type": "sell", "slot": 4}), "")
	assert_null(p.board[4])


func test_next_turn_clears_locks_and_order_counters() -> void:
	var officer: Unit = Kit.put(game, p, "lance-corporal", 4)
	officer.worked_this_turn = true
	officer.turn_counters[&"ability:pigeon_lance_corporal"] = 1
	game.recruit.start_turn(p)
	assert_false(officer.worked_this_turn)
	assert_eq(officer.turn_counter(&"ability:pigeon_lance_corporal"), 0)
	assert_eq(game.act(p.id, {"type": "to_hand", "slot": 4}), "")


func test_start_turn_gain_locks_only_if_the_card_reaches_hand() -> void:
	var runner: Unit = Kit.put(game, p, "horde-runner", 0)
	for i: int in 7:
		_hand("needle-page")
	game.recruit.start_turn(p)
	assert_false(runner.worked_this_turn, "a full-hand loss did no work")
	p.hand.clear()
	game.recruit.start_turn(p)
	assert_true(runner.worked_this_turn)
	assert_eq(p.hand[0].def.id, &"hopper")


func test_price_previews_and_refused_actions_do_not_lock() -> void:
	var source: Unit = _modifier(Rules.UNIT_PRICE, -1)
	Kit.set_shop(game, p, ["needle-page"])
	game.legal_actions(p.id)
	game.view_for(p.id)
	assert_eq(game.rules.unit_price(p, game.library.get_card(&"needle-page")), 1)
	assert_false(source.worked_this_turn)
	p.gold = 0
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "not enough gold")
	assert_false(source.worked_this_turn)
	p.gold = 1
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "")
	assert_true(source.worked_this_turn)


func test_spell_refresh_upgrade_and_income_modifiers_commit_only_on_use() -> void:
	var source: Unit = _modifier(Rules.SPELL_PRICE, -1)
	p.shop_spells.assign([&"sp_sharpen"])
	assert_eq(game.act(p.id, {"type": "buy", "spell": true, "index": 0}), "")
	assert_true(source.worked_this_turn)
	var bound: BoundMechanic = source.mechanics.back()
	var effect: PriceModifier = bound.mechanic as PriceModifier
	for query: StringName in [Rules.REFRESH_COST, Rules.UPGRADE_COST]:
		source.worked_this_turn = false
		effect.query = query
		assert_eq(
			game.act(p.id, {"type": "refresh" if query == Rules.REFRESH_COST else "upgrade"}), ""
		)
		assert_true(source.worked_this_turn)
	effect.query = Rules.INCOME
	effect.delta = 2
	game.rules.income(p, 2)
	source.worked_this_turn = false
	assert_false(source.worked_this_turn)
	game.recruit.start_turn(p)
	assert_true(source.worked_this_turn, "reset happens before this morning's modified income")


func test_capped_away_price_modifier_does_not_lock() -> void:
	var first: Unit = _modifier(Rules.UNIT_PRICE, -10, 0)
	var redundant: Unit = _modifier(Rules.UNIT_PRICE, -2, 1)
	Kit.set_shop(game, p, ["needle-page"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "")
	assert_true(first.worked_this_turn)
	assert_false(redundant.worked_this_turn)


func test_recruit_effects_do_not_lock_source_or_recipient() -> void:
	var mouse: Unit = Kit.put(game, p, "needle-page", 0)
	Kit.set_shop(game, p, ["harvest-piper"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "")
	assert_false(mouse.worked_this_turn)
	assert_false(p.hand[0].worked_this_turn)


func test_death_and_hopper_multipliers_lock_when_used() -> void:
	var gorger: Unit = Kit.put(game, p, "gorger", 0)
	var dirge: Unit = Kit.put(game, p, "dirge-singer", 4)
	_hand("green-recruit")
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_true(dirge.worked_this_turn)
	assert_true(gorger.worked_this_turn)
	p.board.clear()
	p.board.resize(game.geometry.slot_count)
	var mother: Unit = Kit.put(game, p, "mother-of-thousands", 0)
	Kit.put(game, p, "gorger", 1)
	_hand("green-recruit")
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_true(mother.worked_this_turn)


func test_slot_multiplier_locks_only_the_strongest_source() -> void:
	var small: Unit = Kit.put(game, p, "regimental-sergeant-major", 0)
	var big: Unit = Kit.unit(game, "regimental-sergeant-major", true)
	p.place(big, 1)
	var officer: Unit = Kit.put(game, p, "lance-corporal", 4)
	assert_eq(
		game.act(
			p.id, {"type": "ability", "uid": officer.uid, "mechanic": "pigeon_lance_corporal"}
		),
		""
	)
	assert_false(small.worked_this_turn)
	assert_true(big.worked_this_turn)


func test_bury_multiplier_commits_midden_and_nested_sweetbriar() -> void:
	var midden: Unit = Kit.put(game, p, "mother-midden", 0)
	var briar: Unit = Kit.put(game, p, "sweetbriar", 1)
	var layer: Unit = Kit.put(game, p, "hedge-layer", 2)
	Kit.set_shop(game, p, ["needle-page"])
	assert_eq(
		game.act(
			p.id, {"type": "ability", "uid": layer.uid, "mechanic": "thorn_bury_gold", "target": 0}
		),
		""
	)
	assert_true(midden.worked_this_turn)
	assert_true(briar.worked_this_turn)
	assert_true(layer.worked_this_turn)


func test_start_turn_gold_and_end_turn_effects_lock_their_own_sources() -> void:
	var mint: Unit = Kit.put(game, p, "brock-cub", 0)
	mint.mechanics.append(game.registry.bind_given(&"start_turn_gold", {"amount": 2}))
	game.recruit.start_turn(p)
	assert_true(mint.worked_this_turn)
	var whetstone: Unit = Kit.put(game, p, "whetstone-vole", 1)
	game.end_turn(p.id)
	assert_true(whetstone.worked_this_turn)


func test_stronger_death_multiplier_supersedes_weaker_copy() -> void:
	Kit.put(game, p, "gorger", 0)
	var small: Unit = Kit.put(game, p, "dirge-singer", 4)
	var big: Unit = Kit.unit(game, "dirge-singer", true)
	p.place(big, 5)
	_hand("green-recruit")
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_false(small.worked_this_turn)
	assert_true(big.worked_this_turn)


func test_board_fallback_golden_recruit_stays_exempt_from_work() -> void:
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	for slot: int in [0, 1, 2]:
		Kit.put(game, p, "harvest-piper", slot)
	Kit.put(game, p, "needle-page", 3)
	game.recruit._settle(p)
	assert_true(p.board[0].golden)
	assert_false(p.board[0].worked_this_turn)
	assert_false(p.board[3].worked_this_turn)


func test_zone_actions_are_listed_for_units_and_exclude_spells_and_locked_returns() -> void:
	var unit: Unit = Kit.put(game, p, "brock-cub", 0)
	_hand("needle-page")
	_hand("sp_sharpen")
	var legal: Array[Dictionary] = game.legal_actions(p.id)
	assert_true(legal.has({"type": "to_hand", "slot": 0}))
	assert_true(legal.has({"type": "sell", "hand": 0}))
	assert_false(legal.has({"type": "sell", "hand": 1}))
	unit.worked_this_turn = true
	assert_false(game.legal_actions(p.id).has({"type": "to_hand", "slot": 0}))
	assert_true(game.legal_actions(p.id).has({"type": "sell", "slot": 0}))
