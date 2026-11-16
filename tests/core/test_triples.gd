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
	assert_eq(p.all_cards().size(), 1)
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


func test_7_3_6_playing_the_golden_gives_the_triple_reward() -> void:
	for _i: int in 3:
		_buy_copy("t1_plain")
	game.act(0, {"type": "play", "hand": 0, "slot": 0, "target": -1})
	assert_eq(p.hand.size(), 1)
	var reward: Unit = p.hand[0]
	assert_eq(reward.def.id, UnitLibrary.TRIPLE_REWARD_ID)
	assert_eq(reward.pool_copies, 0, "the reward isn't a pool card")
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
	game.recruit.summon(p, &"t1_guard", 6)
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
