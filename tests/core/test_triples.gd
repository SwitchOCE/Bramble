extends GutTest
## 7.3 triples and golden units, with their sell values (4.3.4) and pool copies (5.3.5).

@warning_ignore_start("unsafe_call_argument")

const CoreKit := preload("res://tests/core/core_kit.gd")

var game: GameSession
var p: PlayerState


func before_each() -> void:
	game = CoreKit.session(4)
	game.start_round()
	p = game.player(0)
	p.gold = 100
	CoreKit.set_shop(game, p, [] as Array[String])


func _buy_copy(card_id: String) -> void:
	CoreKit.set_shop(game, p, [card_id] as Array[String])
	assert_eq(game.act(0, {"type": "buy", "spell": false, "index": 0}), "")


func _golden() -> Unit:
	for unit: Unit in p.all_cards():
		if unit.golden:
			return unit
	return null


func test_7_3_1_three_copies_combine_into_a_golden_in_hand() -> void:
	_buy_copy("t1_plain")
	game.act(0, {"type": "play", "hand": 0, "slot": 2, "target": -1})
	_buy_copy("t1_plain")
	_buy_copy("t1_plain")
	var golden: Unit = _golden()
	assert_not_null(golden)
	assert_eq(golden.slot, -1, "in hand")
	assert_null(p.board[2], "the board copy left its slot")
	assert_eq(p.all_cards().size(), 2, "golden and reward are gained together")
	assert_eq([golden.attack(), golden.health()], [4, 8], "7.3.4 double base stats")


func test_7_3_4_golden_keeps_the_copies_buffs() -> void:
	_buy_copy("t1_plain")
	game.act(0, {"type": "play", "hand": 0, "slot": 0, "target": -1})
	p.board[0].stats.perm_attack = 3
	_buy_copy("t1_plain")
	_buy_copy("t1_plain")
	assert_eq(_golden().attack(), 4 + 3)


func test_4_3_4_and_5_3_5_golden_sells_and_returns_by_its_copies() -> void:
	var token_like: Unit = CoreKit.unit(game, "t1_plain")
	token_like.bought_copies = 0
	p.hand.append(token_like)
	var left: int = game.units.copies_left(&"t1_plain")
	_buy_copy("t1_plain")
	_buy_copy("t1_plain")
	var golden: Unit = _golden()
	assert_eq(golden.bought_copies, 2)
	assert_eq(golden.pool_copies, 2)
	game.act(0, {"type": "play", "hand": p.hand.find(golden), "slot": 0, "target": -1})
	var gold: int = p.gold
	game.act(0, {"type": "sell", "slot": 0})
	assert_eq(p.gold, gold + 2, "two Bought copies of a tier 1")
	assert_eq(game.units.copies_left(&"t1_plain"), left, "both pool copies came back")


func test_7_3_6_buy_triple_gives_reward_at_formation_and_never_on_play() -> void:
	for _i: int in 3:
		_buy_copy("t1_plain")
	assert_eq(p.hand.size(), 2, "formation gains both the golden and the spell")
	var golden: Unit = _golden()
	var reward: Unit = p.hand[1]
	assert_eq(reward.def.id, UnitLibrary.TRIPLE_REWARD_ID)
	assert_eq(reward.pool_copies, 0, "the reward isn't a pool card")
	assert_eq(game.act(0, {"type": "play", "hand": p.hand.find(golden), "slot": 0}), "")
	assert_eq(p.hand, [reward] as Array[Unit], "playing gives no second reward")
	p.tier = 2
	game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": -1})
	assert_eq(p.discover_options.size(), 3)
	for card_id: StringName in p.discover_options:
		assert_eq(game.library.get_card(card_id).tier, 3, "the tier above when cast")


func test_7_3_6_at_tier_6_the_reward_discovers_tier_6() -> void:
	p.tier = 6
	p.hand.append(game.new_unit(game.library.get_card(UnitLibrary.TRIPLE_REWARD_ID), false))
	game.act(0, {"type": "play", "hand": 0, "slot": -1, "target": -1})
	for card_id: StringName in p.discover_options:
		assert_eq(game.library.get_card(card_id).tier, 6)


func test_7_3_1_board_triple_goes_to_hand_when_there_is_room() -> void:
	CoreKit.put(game, p, "t1_guard", 5)
	CoreKit.put(game, p, "t1_guard", 2)
	for _i: int in 6:
		p.hand.append(CoreKit.unit(game, "t1_plain", true))
	p.hand.append(CoreKit.unit(game, "t1_guard"))
	game.act(0, {"type": "play", "hand": 6, "slot": 0, "target": -1})
	assert_eq(p.hand.size(), 7, "6 goldens plus the new one")
	assert_eq(_golden_of(&"t1_guard").slot, -1)
	assert_eq(p.board_count(), 0, "all three copies left the board")


func test_7_3_7_all_three_on_the_board_with_a_full_hand() -> void:
	for slot: int in [3, 1]:
		CoreKit.put(game, p, "t1_guard", slot)
	for _i: int in 7:
		p.hand.append(CoreKit.unit(game, "t1_plain", true))
	# A Recruit Phase summon is the third copy: it lands on the board.
	RecruitContext.new(game, game.recruit, p).summon(&"t1_guard", 6)
	game.recruit.end_turn(p)
	var golden: Unit = _golden_of(&"t1_guard")
	assert_not_null(golden)
	assert_eq(golden.slot, 1, "the first vacated slot in reading order")


func _golden_of(card_id: StringName) -> Unit:
	for unit: Unit in p.all_cards():
		if unit.golden and unit.def.id == card_id:
			return unit
	return null


func test_7_3_5_golden_doubles_numbers_not_thresholds() -> void:
	var avenger: Unit = CoreKit.unit(game, "t5_avenger", true)
	var params: MechanicParams = avenger.mechanics[0].params
	assert_eq(params.num(&"attack"), 8, "+4 doubled")
	assert_eq(params.num(&"every"), 3, "the counter keeps its number")


func test_7_3_3_created_copies_count_toward_triples() -> void:
	for _i: int in 2:
		var created: Unit = CoreKit.unit(game, "t1_plain")
		created.bought_copies = 0
		p.hand.append(created)
	_buy_copy("t1_plain")
	assert_not_null(_golden())
	assert_eq(_golden().bought_copies, 1)


func test_7_3_4_temporary_debuffs_cannot_lower_a_triple_below_golden_base() -> void:
	var golden: Unit = _combine_with_modifiers(Vector2i.ZERO, Vector2i(-1, -2))
	assert_not_null(golden)
	if golden == null:
		return
	assert_eq([golden.attack(), golden.health()], [4, 8], "7.3.4 floors both stats at formation")
	golden.stats.end_turn()
	assert_eq([golden.attack(), golden.health()], [4, 8], "expiry creates no extra buff")


func test_7_3_4_permanent_debuffs_offset_temporary_buffs_before_the_floor() -> void:
	var golden: Unit = _combine_with_modifiers(Vector2i(-1, 2), Vector2i(2, -1))
	assert_not_null(golden)
	if golden == null:
		return
	assert_eq([golden.attack(), golden.health()], [7, 11], "all buffs and debuffs offset first")
	golden.stats.end_turn()
	assert_eq([golden.attack(), golden.health()], [4, 14], "only temporary layers expire")


func test_7_3_4_temporary_debuff_floor_preserves_permanent_buffs() -> void:
	var golden: Unit = _combine_with_modifiers(Vector2i(1, 2), Vector2i(-2, -3))
	assert_not_null(golden)
	if golden == null:
		return
	assert_eq([golden.attack(), golden.health()], [4, 8], "temporary debuffs stop at the base")
	golden.stats.end_turn()
	assert_eq([golden.attack(), golden.health()], [7, 14], "the permanent buffs remain")


func test_7_3_4_negative_totals_floor_after_all_modifiers_merge() -> void:
	var golden: Unit = _combine_with_modifiers(Vector2i(-2, -3), Vector2i(1, 2))
	assert_not_null(golden)
	if golden == null:
		return
	assert_eq([golden.attack(), golden.health()], [4, 8], "negative merged totals use the base")
	golden.stats.end_turn()
	assert_eq([golden.attack(), golden.health()], [4, 8], "expiry leaves the lasting floor")


func test_7_3_4_formation_floor_does_not_restrict_later_stat_changes() -> void:
	for layer: String in ["set", "perm", "turn", "combat", "aura", "slot"]:
		p.hand.clear()
		var golden: Unit = _combine_with_modifiers(Vector2i.ZERO, Vector2i(-1, -2))
		assert_not_null(golden)
		if golden == null:
			continue
		var value: int = 1 if layer == "set" else -3
		golden.stats.set(layer + "_attack", value)
		golden.stats.set(layer + "_health", value)
		var expected: Vector2i = Vector2i.ONE if layer == "set" else Vector2i(1, 5)
		assert_eq(
			Vector2i(golden.attack(), golden.health()), expected, layer + ": normal later changes"
		)
		var combat_copy: CombatUnit = CombatUnit.from_unit(golden, 100, 0)
		assert_eq(
			Vector2i(combat_copy.attack(), combat_copy.max_health()), expected, layer + ": copied"
		)


func _combine_with_modifiers(perm: Vector2i, turn: Vector2i) -> Unit:
	for i: int in 3:
		var copy: Unit = CoreKit.unit(game, "t1_plain")
		copy.stats.perm_attack = perm.x
		copy.stats.perm_health = perm.y
		copy.stats.turn_attack = turn.x
		copy.stats.turn_health = turn.y
		p.hand.append(copy)
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 0, "target": -1}), "")
	return _golden()


func test_7_3_6_discover_pick_triple_gives_reward_immediately() -> void:
	p.hand.append(CoreKit.unit(game, "t1_plain"))
	CoreKit.put(game, p, "t1_plain", 2)
	assert_true(game.units.take(&"t1_plain"))
	p.discover_options.assign([&"t1_plain"])
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_not_null(_golden())
	assert_eq(_reward_count(), 1)
	assert_true(p.discover_options.is_empty(), "the reward is not cast automatically")


func test_7_3_6_generated_gain_triple_gives_reward_when_settled() -> void:
	p.hand.append(CoreKit.unit(game, "t1_plain"))
	p.hand.append(CoreKit.unit(game, "t1_plain"))
	var ctx := RecruitContext.new(game, game.recruit, p)
	assert_not_null(ctx.give_card(&"t1_plain", null))
	game.recruit._settle(p)
	assert_not_null(_golden())
	assert_eq(_reward_count(), 1)
	var formed: Array[Dictionary] = CoreKit.log_of(game, "triple")
	assert_eq(formed.size(), 1)
	var reward: Unit = p.hand[1]
	assert_eq(formed[0]["reward_uid"], reward.uid, "presentation associates the actual reward")


func test_7_3_6_reward_lost_when_golden_fills_the_last_hand_space() -> void:
	for i: int in 6:
		p.hand.append(CoreKit.unit(game, "t1_plain", true))
	for slot: int in [0, 2, 5]:
		CoreKit.put(game, p, "t1_guard", slot)
	game.recruit._settle(p)
	assert_eq(_golden_of(&"t1_guard").slot, -1, "golden uses the last hand place")
	assert_eq(p.hand.size(), 7)
	assert_eq(_reward_count(), 0)
	var lost: Array[Dictionary] = CoreKit.log_of(game, "card_lost")
	assert_eq(lost.size(), 1)
	assert_eq(lost[0]["id"], String(UnitLibrary.TRIPLE_REWARD_ID))
	assert_eq(CoreKit.log_of(game, "triple")[0]["reward_uid"], -1)
	assert_eq(game.act(p.id, {"type": "play", "hand": 6, "slot": 0}), "")
	assert_eq(_reward_count(), 0, "playing cannot recover the lost reward")


func test_7_3_7_board_fallback_loses_reward_through_normal_full_hand_path() -> void:
	for i: int in 7:
		p.hand.append(CoreKit.unit(game, "t1_plain", true))
	for slot: int in [1, 3, 5]:
		CoreKit.put(game, p, "t1_guard", slot)
	game.recruit._settle(p)
	assert_eq(_golden_of(&"t1_guard").slot, 1)
	assert_eq(p.hand.size(), 7)
	assert_eq(_reward_count(), 0)
	assert_eq(CoreKit.log_of(game, "card_lost")[0]["id"], String(UnitLibrary.TRIPLE_REWARD_ID))
	assert_eq(CoreKit.log_of(game, "triple")[0]["reward_uid"], -1)


func _reward_count() -> int:
	return (
		p.hand.filter(func(u: Unit) -> bool: return u.def.id == UnitLibrary.TRIPLE_REWARD_ID).size()
	)


func test_reward_can_cast_before_golden_is_played_and_reads_tier_at_cast() -> void:
	for i: int in 3:
		_buy_copy("t1_plain")
	var golden: Unit = _golden()
	assert_eq(golden.slot, -1)
	assert_eq(game.act(p.id, {"type": "upgrade"}), "")
	assert_eq(p.tier, 2)
	assert_eq(game.act(p.id, {"type": "play", "hand": 1, "slot": -1}), "")
	assert_eq(p.hand, [golden] as Array[Unit], "reward can be cast before playing the golden")
	assert_eq(p.discover_options.size(), 3)
	for id: StringName in p.discover_options:
		assert_eq(game.library.get_card(id).tier, 3, "uses tier 2 at cast, not tier 1 at formation")


func test_triple_pulls_a_locked_board_copy_into_the_golden_in_hand() -> void:
	var content: ContentSet = CoreKit.content(["thorn"], false)
	var session: GameSession = content.session(25)
	session.start_round()
	var player: PlayerState = session.player(0)
	player.gold = 100
	var layer: Unit = CoreKit.put(session, player, "hedge-layer", 4)
	CoreKit.set_shop(session, player, ["t1_plain"] as Array[String])
	assert_eq(
		session.act(
			player.id,
			{"type": "ability", "uid": layer.uid, "mechanic": "thorn_bury_gold", "target": 0}
		),
		""
	)
	assert_true(layer.worked_this_turn, "the board copy used its Order")
	for i: int in 2:
		CoreKit.set_shop(session, player, ["hedge-layer"] as Array[String])
		assert_eq(session.act(player.id, {"type": "buy", "index": 0}), "")
	assert_null(player.board[4], "the triple takes priority over the work lock")
	var golden: Unit = player.hand[0]
	assert_true(golden.golden)
	assert_eq(golden.def.id, &"hedge-layer")
	assert_eq(golden.slot, -1, "golden goes to hand even when a source was locked")
	assert_eq(player.hand[1].def.id, UnitLibrary.TRIPLE_REWARD_ID)
