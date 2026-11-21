extends GutTest
## Rulebook 7.2.3/7.2.6: acquisition, never placement, fires unit Recruit effects.

@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/core_kit.gd")
var game: GameSession
var p: PlayerState
var mouse: Unit


func before_each() -> void:
	game = Kit.content([], false, true).session(15)
	game.start_round()
	p = game.player(0)
	p.gold = 100
	mouse = Kit.put(game, p, "needle-page", 0)


func _triggers(id: String) -> int:
	return (
		Kit
		. log_of(game, "trigger")
		. filter(func(e: Dictionary) -> bool: return str(e["mechanic"]) == id)
		. size()
	)


func _offer(id: String) -> void:
	p.discover_options.assign([StringName(id)])


func test_buy_recruits_once_before_play_and_replay() -> void:
	Kit.set_shop(game, p, ["harvest-piper"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "")
	assert_eq(mouse.attack(), 9, "buffed while Piper is still in hand")
	var piper: Unit = p.hand[0]
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	p.remove_from_board(piper)
	p.hand.append(piper)  # Model a return without implementing step 3's new move.
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 2}), "")
	assert_eq(mouse.attack(), 9)
	assert_eq(_triggers("mouse_piper"), 1)


func test_discover_pick_recruits_once_and_only_buffs_board_mice() -> void:
	var held: Unit = Kit.unit(game, "needle-page")
	p.hand.append(held)
	_offer("harvest-piper")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_eq(mouse.attack(), 9)
	assert_eq(held.attack(), 4)
	assert_eq(_triggers("mouse_piper"), 1)


func test_triple_reward_pick_recruits_once() -> void:
	p.tier = 1
	p.hand.append(Kit.unit(game, String(UnitLibrary.TRIPLE_REWARD_ID)))
	assert_eq(game.act(p.id, {"type": "play", "hand": 0}), "")
	assert_eq(_triggers("triple_reward"), 1)
	assert_false(p.discover_options.is_empty())
	_offer("harvest-piper")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_eq(mouse.attack(), 9)
	assert_eq(_triggers("mouse_piper"), 1)


func test_effect_adding_to_hand_recruits_once() -> void:
	var ctx := RecruitContext.new(game, game.recruit, p)
	var piper: Unit = ctx.give_card(&"harvest-piper", mouse)
	assert_not_null(piper)
	assert_eq(mouse.attack(), 9)
	assert_eq(_triggers("mouse_piper"), 1)


func test_waiting_generated_unit_and_discover_pick_recruit_on_gain_only() -> void:
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	var ctx := RecruitContext.new(game, game.recruit, p)
	assert_not_null(ctx.give_card(&"harvest-piper", mouse))
	assert_eq(mouse.attack(), 9)
	_offer("harvest-piper")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_true(p.discover_options.is_empty())
	assert_eq(mouse.attack(), 14)
	assert_eq(p.waiting_pile.size(), 2)
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_true(p.waiting_pile.is_empty())
	assert_eq(_triggers("mouse_piper"), 2)
	assert_eq(mouse.attack(), 14)


func test_bought_third_copy_fires_only_the_golden_before_play() -> void:
	p.hand.append(Kit.unit(game, "harvest-piper"))
	p.hand.append(Kit.unit(game, "harvest-piper"))
	Kit.set_shop(game, p, ["harvest-piper"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "")
	assert_eq(mouse.attack(), 14, "only +10 from the golden; the bought third copy gives no +5")
	assert_eq(_triggers("mouse_piper"), 1)
	assert_true(p.hand[0].golden)
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_eq(mouse.attack(), 14)
	assert_eq(_triggers("mouse_piper"), 1)


func test_full_hand_board_triple_still_recruits_golden() -> void:
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	for slot: int in [1, 2, 3]:
		Kit.put(game, p, "harvest-piper", slot)
	game.recruit._settle(p)
	assert_true(p.board[1].golden)
	assert_eq(mouse.attack(), 14)
	assert_eq(_triggers("mouse_piper"), 1)


func test_buy_and_pick_list_hand_board_and_self_targets() -> void:
	var hand: Unit = Kit.unit(game, "brock-cub")
	p.hand.append(hand)
	p.hand.append(Kit.unit(game, String(UnitLibrary.TRIPLE_REWARD_ID)))
	Kit.set_shop(game, p, ["master-at-arms"])
	for action: String in ["buy", "pick"]:
		if action == "pick":
			_offer("master-at-arms")
		var targets: Array[int] = []
		for offered: Dictionary in game.legal_actions(p.id):
			if offered["type"] != action:
				continue
			if offered["index"] == 0 and not CoreUtil.to_bool(offered.get("spell", false)):
				targets.append(offered["target"])
		assert_eq(targets, [-1, mouse.uid, hand.uid])


func test_buy_and_pick_can_directly_target_hand_or_board() -> void:
	var hand: Unit = Kit.unit(game, "brock-cub")
	p.hand.append(hand)
	Kit.set_shop(game, p, ["master-at-arms"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0, "target": hand.uid}), "")
	_offer("master-at-arms")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0, "target": mouse.uid}), "")
	assert_eq(hand.view()["totals"]["badger_fury"]["fury"], 2)
	assert_eq(mouse.view()["totals"]["badger_fury"]["fury"], 1)
	assert_eq(_triggers("badger_arms_master"), 2)


func test_invalid_recruit_target_changes_nothing() -> void:
	Kit.set_shop(game, p, ["master-at-arms"])
	var gold: int = p.gold
	var enemy: Unit = Kit.put(game, game.player(1), "brock-cub", 0)
	assert_ne(game.act(p.id, {"type": "buy", "index": 0, "target": enemy.uid}), "")
	assert_eq(p.gold, gold)
	assert_eq(p.shop_units[0], &"master-at-arms")
	assert_true(p.hand.is_empty())
	_offer("master-at-arms")
	assert_ne(game.act(p.id, {"type": "pick", "index": 0, "target": enemy.uid}), "")
	assert_eq(p.discover_options, [&"master-at-arms"] as Array[StringName])


func test_pending_recruit_keeps_the_choice_until_aimed_once() -> void:
	Kit.set_shop(game, p, ["master-at-arms"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0}), "")
	var master: Unit = p.hand[0]
	assert_eq(_triggers("badger_arms_master"), 0)
	assert_ne(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_eq(game.act(p.id, {"type": "recruit_target", "target": master.uid}), "")
	assert_true(master.has_mechanic(&"badger_fury"))
	assert_ne(game.act(p.id, {"type": "recruit_target", "target": master.uid}), "")
	assert_eq(_triggers("badger_arms_master"), 1)


func test_end_turn_auto_resolves_discover_and_targeted_golden() -> void:
	p.hand.append(Kit.unit(game, "master-at-arms"))
	p.hand.append(Kit.unit(game, "master-at-arms"))
	_offer("master-at-arms")
	game.end_turn(p.id)
	assert_true(p.turn_ended)
	assert_true(p.discover_options.is_empty())
	assert_true(p.recruit_choices.is_empty())
	assert_true(p.hand[0].golden)
	assert_eq(
		p.hand[0].view()["totals"]["badger_fury"]["fury"], 2, "only the golden recruit gives Fury"
	)
	assert_eq(_triggers("badger_arms_master"), 1)


func test_only_self_available_is_always_a_legal_choice() -> void:
	p.remove_from_board(mouse)
	Kit.set_shop(game, p, ["master-at-arms"])
	assert_eq(game.act(p.id, {"type": "buy", "index": 0, "target": -1}), "")
	assert_true(p.hand[0].has_mechanic(&"badger_fury"))
	assert_true(p.recruit_choices.is_empty())


func test_spell_gain_does_nothing_until_cast() -> void:
	var spell: Unit = game.new_unit(game.library.get_card(&"sp_sharpen"), false)
	assert_true(game.recruit._gain(p, spell))
	assert_eq(mouse.attack(), 4)
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "target": mouse.uid}), "")
	assert_eq(mouse.attack(), 6)
	assert_eq(_triggers("play_buff"), 1)


func test_discovered_third_copy_fires_only_the_golden() -> void:
	p.hand.append(Kit.unit(game, "harvest-piper"))
	Kit.put(game, p, "harvest-piper", 1)
	_offer("harvest-piper")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_eq(mouse.attack(), 14, "+10 only, across a hand and board pair")
	assert_eq(_triggers("mouse_piper"), 1)
	assert_true(p.hand[0].golden)
	assert_null(p.board[1])


func test_generated_third_copy_fires_only_the_golden() -> void:
	p.hand.append(Kit.unit(game, "harvest-piper"))
	p.hand.append(Kit.unit(game, "harvest-piper"))
	var ctx := RecruitContext.new(game, game.recruit, p)
	assert_not_null(ctx.give_card(&"harvest-piper", mouse))
	assert_eq(_triggers("mouse_piper"), 0, "the generated third copy never fires")
	game.recruit._settle(p)
	assert_eq(mouse.attack(), 14)
	assert_eq(_triggers("mouse_piper"), 1)
	assert_true(p.hand[0].golden)


func test_second_copy_and_fourth_gain_still_recruit_normally() -> void:
	p.hand.append(Kit.unit(game, "harvest-piper"))
	var ctx := RecruitContext.new(game, game.recruit, p)
	assert_not_null(ctx.give_card(&"harvest-piper", mouse))
	assert_eq(mouse.attack(), 9, "second copy recruits")
	assert_not_null(ctx.give_card(&"harvest-piper", mouse))
	assert_eq(mouse.attack(), 9, "third copy waits to merge without recruiting")
	assert_not_null(ctx.give_card(&"harvest-piper", mouse))
	assert_eq(mouse.attack(), 14, "fourth gain still recruits before the enclosing action settles")
	game.recruit._settle(p)
	assert_eq(mouse.attack(), 24, "two normal triggers plus the doubled golden")
	assert_eq(_triggers("mouse_piper"), 3)
	assert_eq(p.hand.size(), 3, "one normal copy, one golden and its reward")
