extends GutTest
## Rulebook 7.1.2/7.2.6: waiting units recruit after the action that frees a hand place.

@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/core_kit.gd")


class StartTurnGift:
	extends Mechanic

	func on_start_of_turn(
		ctx: RecruitContext, unit: Unit, _report: FightReport, _params: MechanicParams
	) -> void:
		ctx.give_card(&"harvest-piper", unit)


class GiveHandReserve:
	extends Mechanic

	func on_played(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
		for card: Unit in ctx.player.hand:
			if not card.is_spell():
				ctx.give_keyword(card, &"pigeon_reserve", unit)


class SaleEffects:
	extends Mechanic

	func on_sold(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
		for card: Unit in ctx.player.hand:
			ctx.buff(card, 1, 0, true, unit)
		ctx.give_card(&"sp_seek", unit)

	func on_any_sold(ctx: RecruitContext, unit: Unit, _sold: Unit, _params: MechanicParams) -> void:
		for card: Unit in ctx.player.hand:
			ctx.buff(card, 0, 1, true, unit)


class RecruitReadsAttack:
	extends Mechanic

	func on_recruited(
		ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams
	) -> void:
		ctx.buff(unit, ctx.player.board[0].attack(), 0, true, unit)


class EndTurnGift:
	extends Mechanic

	func on_end_of_turn(ctx: RecruitContext, unit: Unit, _params: MechanicParams) -> void:
		ctx.give_card(&"master-at-arms", unit)


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


func test_waiting_generated_unit_and_discover_pick_recruit_in_join_order() -> void:
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	var ctx := RecruitContext.new(game, game.recruit, p)
	var first: Unit = ctx.give_card(&"harvest-piper", mouse)
	assert_not_null(first)
	_offer("harvest-piper")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_true(p.discover_options.is_empty())
	assert_eq(mouse.attack(), 4)
	assert_eq(_triggers("mouse_piper"), 0)
	assert_eq(p.waiting_pile.size(), 2)
	var second: Unit = p.waiting_pile[1]
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(p.hand.back(), first)
	assert_eq(mouse.attack(), 9)
	assert_eq(_triggers("mouse_piper"), 1)
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_eq(p.hand.back(), second)
	assert_true(p.waiting_pile.is_empty())
	assert_eq(_triggers("mouse_piper"), 2)
	assert_eq(mouse.attack(), 14)


func test_waiting_triple_reward_pick_recruits_when_space_opens() -> void:
	p.tier = 1
	game.config.discover_options = game.library.ids().size()  # Offer every eligible unit.
	p.hand.append(Kit.unit(game, String(UnitLibrary.TRIPLE_REWARD_ID)))
	for i: int in 6:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	var ctx := RecruitContext.new(game, game.recruit, p)
	assert_not_null(ctx.give_card(&"sp_seek", null))
	assert_eq(game.act(p.id, {"type": "play", "hand": 0}), "")
	assert_eq(_triggers("triple_reward"), 1)
	assert_eq(p.hand.size(), 7, "an older waiting spell took the reward's hand place")
	var offer: int = p.discover_options.find(&"harvest-piper")
	assert_gte(offer, 0)
	assert_eq(game.act(p.id, {"type": "pick", "index": offer}), "")
	var piper: Unit = p.waiting_pile[0]
	assert_eq(_triggers("mouse_piper"), 0)
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(p.hand.back(), piper)
	assert_eq(mouse.attack(), 9)
	assert_eq(_triggers("mouse_piper"), 1)


func test_start_turn_gift_waits_across_turns_and_recruits_once_with_fresh_flags() -> void:
	var id: StringName = &"core_test_waiting_start_turn_gift"
	assert_true(game.registry.register(id, StartTurnGift.new()))
	mouse.mechanics.append(game.registry.bind(MechanicSpec.new(id), false, true))
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	game.recruit.start_turn(p)
	assert_true(mouse.worked_this_turn, "the giver worked even though its gift waits")
	var piper: Unit = p.waiting_pile[0]
	assert_eq(piper.def.id, &"harvest-piper")
	assert_eq(_triggers("mouse_piper"), 0)
	piper.worked_this_turn = true
	piper.turn_counters[&"test"] = 1
	piper.stats.turn_attack = 2
	mouse.mechanics.pop_back()
	game.end_turn(p.id)
	game.recruit.start_turn(p)
	assert_eq(p.waiting_pile, [piper] as Array[Unit])
	assert_eq(_triggers("mouse_piper"), 0)
	assert_eq(piper.turn_counter(&"test"), 0)
	assert_eq(piper.stats.turn_attack, 0)
	assert_false(piper.worked_this_turn)
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(p.hand.back(), piper)
	assert_eq(mouse.attack(), 9)
	assert_eq(_triggers("mouse_piper"), 1)
	assert_false(piper.worked_this_turn, "Recruit itself does not commit the source")


func test_waiting_third_piper_joins_and_only_its_golden_recruits() -> void:
	p.hand.append(Kit.unit(game, "harvest-piper"))
	Kit.put(game, p, "harvest-piper", 1)
	for i: int in 6:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	_offer("harvest-piper")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	var waiting: Unit = p.waiting_pile[0]
	assert_eq(mouse.attack(), 4)
	assert_eq(_triggers("mouse_piper"), 0)
	assert_true(Kit.log_of(game, "triple").is_empty())
	assert_eq(game.act(p.id, {"type": "play", "hand": 1, "slot": 2}), "")
	assert_true(p.waiting_pile.is_empty())
	assert_null(p.find_uid(waiting.uid))
	assert_null(p.board[1])
	var golden: Unit = p.hand[5]
	assert_true(golden.golden)
	assert_eq(golden.def.id, &"harvest-piper")
	assert_eq(mouse.attack(), 14)
	assert_eq(_triggers("mouse_piper"), 1)
	assert_eq(Kit.log_of(game, "trigger").back()["uid"], golden.uid)


func test_waiting_targeted_pick_chooses_from_the_hand_and_board_at_join() -> void:
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	_offer("master-at-arms")
	var pick: Dictionary = {"type": "pick", "index": 0}
	assert_eq(game.legal_actions(p.id), [pick] as Array[Dictionary])
	assert_eq(game.act(p.id, pick), "")
	var master: Unit = p.waiting_pile[0]
	assert_true(p.recruit_choices.is_empty())
	assert_eq(_triggers("badger_arms_master"), 0)
	var played: Unit = p.hand[0]
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_eq(p.recruit_choices, [master] as Array[Unit])
	assert_eq(p.hand.back(), master)
	assert_true(game.legal_actions(p.id).has({"type": "recruit_target", "target": master.uid}))
	assert_eq(game.act(p.id, {"type": "recruit_target", "target": played.uid}), "")
	assert_eq(_triggers("badger_arms_master"), 1)
	assert_eq(played.view()["totals"]["badger_fury"]["fury"], 3)


func test_waiting_pick_refuses_an_explicit_target_without_consuming_the_offer() -> void:
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	_offer("master-at-arms")
	for target: int in [mouse.uid, -1, -2]:
		assert_eq(
			game.act(p.id, {"type": "pick", "index": 0, "target": target}),
			"choose a recruit target when the card joins your hand"
		)
	assert_eq(p.discover_options, [&"master-at-arms"] as Array[StringName])
	assert_true(p.waiting_pile.is_empty())
	assert_true(p.recruit_choices.is_empty())
	assert_true(Kit.log_of(game, "pick").is_empty())
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	assert_eq(p.waiting_pile.size(), 1)


func test_sell_effects_finish_before_the_waiting_card_joins_and_recruits() -> void:
	var id: StringName = &"core_test_waiting_sale_effects"
	assert_true(game.registry.register(id, SaleEffects.new()))
	for i: int in 7:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	var sale: BoundMechanic = game.registry.bind(MechanicSpec.new(id), false, true)
	p.hand[0].mechanics.append(sale)
	mouse.mechanics.append(sale)
	var ctx := RecruitContext.new(game, game.recruit, p)
	var piper: Unit = ctx.give_card(&"harvest-piper", null)
	assert_eq(game.act(p.id, {"type": "sell", "hand": 0}), "")
	assert_eq(p.hand.back(), piper)
	assert_eq(p.hand[0].stats.perm_attack, 1, "the sold unit buffed the existing hand")
	assert_eq(p.hand[0].stats.perm_health, 1, "the sale listener buffed the existing hand")
	assert_eq(piper.stats.perm_attack, 0, "the waiting card missed the Sell effect")
	assert_eq(piper.stats.perm_health, 0, "the waiting card missed the any-sold effect")
	assert_eq(p.waiting_pile.size(), 1, "the sale's gift queued behind the older card")
	assert_eq(p.waiting_pile[0].def.id, &"sp_seek")
	assert_eq(mouse.attack(), 9, "Piper recruited after the sale")
	var buffs: Array[Dictionary] = Kit.log_of(game, "buff")
	var joined: Dictionary = Kit.log_of(game, "waiting_join")[0]
	assert_lt(game.events.find(buffs[-2]), game.events.find(joined))
	assert_lt(game.events.find(joined), game.events.find(buffs[-1]))


func test_cast_finishes_before_waiting_quartermaster_joins_and_checks_targets() -> void:
	var spell: Unit = Kit.unit(game, "sp_sharpen")
	var id: StringName = &"core_test_give_hand_reserve"
	assert_true(game.registry.register(id, GiveHandReserve.new()))
	spell.mechanics.append(game.registry.bind(MechanicSpec.new(id), false, true))
	p.hand.append(spell)
	for i: int in 2:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	for i: int in 4:
		p.hand.append(Kit.unit(game, "sp_sharpen"))
	_offer("quartermaster")
	assert_eq(game.act(p.id, {"type": "pick", "index": 0}), "")
	var officer: Unit = p.waiting_pile[0]
	assert_eq(
		game.act(p.id, {"type": "play", "hand": 0, "target": officer.uid}), "not a valid target"
	)
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "target": mouse.uid}), "")
	assert_eq(mouse.attack(), 6)
	assert_eq(p.hand.back(), officer)
	assert_true(p.hand[0].has_mechanic(&"pigeon_reserve"))
	assert_true(p.hand[1].has_mechanic(&"pigeon_reserve"))
	assert_false(officer.has_mechanic(&"pigeon_reserve"), "the spell never saw the waiting card")
	assert_eq(_triggers("pigeon_quartermaster"), 0, "the spell used the eligible targets first")
	assert_true(p.recruit_choices.is_empty())
	assert_true(game.legal_actions(p.id).has({"type": "end_turn"}))


func test_play_applies_the_units_aura_before_the_waiting_card_recruits() -> void:
	var banner: Unit = Kit.unit(game, "t3_banner")
	p.hand.append(banner)
	for i: int in 6:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	var ctx := RecruitContext.new(game, game.recruit, p)
	var waiting: Unit = ctx.give_card(&"t1_plain", null)
	var id: StringName = &"core_test_waiting_recruit_reads_attack"
	assert_true(game.registry.register(id, RecruitReadsAttack.new()))
	waiting.mechanics.append(game.registry.bind(MechanicSpec.new(id), false, true))
	assert_eq(mouse.attack(), 4)
	assert_eq(game.act(p.id, {"type": "play", "hand": 0, "slot": 1}), "")
	assert_eq(p.board[1], banner)
	assert_eq(p.hand.back(), waiting)
	assert_true(p.waiting_pile.is_empty())
	assert_eq(waiting.stats.perm_attack, 6, "Recruit read the mouse after Banner's +2 aura")


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


func test_end_turn_resolves_the_target_of_a_golden_formed_by_an_end_of_turn_gift() -> void:
	var id: StringName = &"core_test_waiting_end_turn_gift"
	assert_true(game.registry.register(id, EndTurnGift.new()))
	mouse.mechanics.append(game.registry.bind(MechanicSpec.new(id), false, true))
	p.hand.append(Kit.unit(game, "master-at-arms"))
	p.hand.append(Kit.unit(game, "master-at-arms"))
	game.end_turn(p.id)
	assert_true(p.turn_ended)
	assert_true(p.recruit_choices.is_empty())
	assert_eq(p.hand[0].def.id, &"master-at-arms")
	assert_true(p.hand[0].golden)
	assert_eq(p.hand[0].view()["totals"]["badger_fury"]["fury"], 2)
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
