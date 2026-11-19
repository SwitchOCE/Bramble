extends GutTest
## The flow's bots spend spare gold and use abilities; the fight log reaches the replay whole.

const CoreKit := preload("res://tests/core/core_kit.gd")
const SHARED: String = "res://src/content/shared"
const TEST_CARDS: String = "res://tests/core/content/test"


## The most gold any bot ends a turn holding, over a bot-only game from round `from` on.
func _most_gold_kept(content: GameContent, make: Callable, game_seed: int, from: int) -> int:
	var session: GameSession = content.new_session(game_seed)
	var bots: Array[Bot] = []
	for seat: int in session.players.size():
		bots.append(make.call(Rng.derive(game_seed, "bot:%d" % seat)))
	var most: int = 0
	while not session.over and session.round_number < 40:
		session.start_round()
		for seat: int in bots.size():
			var each: PlayerState = session.player(seat)
			if each.alive:
				bots[seat].take_turn(session, seat)
				if session.round_number >= from:
					most = maxi(most, each.gold)
		session.finish_round()
	return most


func test_flow_bots_do_not_hoard_gold() -> void:
	var content: GameContent = GameContent.load_folders([SHARED])
	var simple: int = 0
	var flow: int = 0
	for game_seed: int in [1, 2, 3]:
		simple = maxi(
			simple,
			_most_gold_kept(content, func(rng: Rng) -> Bot: return SimpleBot.new(rng), game_seed, 8)
		)
		flow = maxi(
			flow,
			_most_gold_kept(content, func(rng: Rng) -> Bot: return FlowBot.new(rng), game_seed, 8)
		)
	gut.p(
		(
			"most gold kept at the end of a turn from round 8: SimpleBot %d, FlowBot %d"
			% [simple, flow]
		)
	)
	assert_lt(flow, simple, "FlowBot spends what SimpleBot keeps")
	assert_lt(flow, 20, "FlowBot never sits on a pile of gold")


func test_flow_bot_uses_abilities() -> void:
	var content: GameContent = GameContent.load_folders([SHARED, TEST_CARDS])
	var session: GameSession = content.new_session(4)
	session.start_round()
	var me: PlayerState = session.player(0)
	var officer: Unit = session.new_unit(content.library.get_card(&"b3_officer"), false)
	officer.bought_copies = 1
	me.place(officer, 0)
	me.gold = 40
	var bot := FlowBot.new(Rng.derive(4, "bot"))
	var took: Array[String] = []
	bot.take_turn(session, 0, func(action: Dictionary) -> void: took.append(str(action["type"])))
	assert_true(took.has("ability"), "the Officer's Order was used: %s" % [took])
	assert_eq(bot.refused, 0, "nothing refused")


func test_a_reserve_unit_steps_onto_the_replays_board_and_fight_gold_is_counted() -> void:
	var events: Array = [
		{"type": "combat_start"},
		{"type": "reserve", "uid": 9, "side": 0, "slot": 2, "id": "b2_reservist"},
		{"type": "gold", "side": 0, "amount": 2, "next_turn": true},
		{"type": "gold", "side": 1, "amount": 5, "next_turn": true},
	]
	var replay: FightReplay = FightReplay.build({"you_side": 0}, events, {})
	var row: Array = replay.boards[0]
	var stepped: Dictionary = row[2]
	assert_eq(CoreUtil.to_int(stepped["uid"]), 9, "drawn as a unit entering its slot")
	assert_eq(ViewAdapter.fight_gold(events, 0), 2, "gold the human's side earned")


func test_flow_bot_buys_with_a_target_and_resolves_a_golden_recruit_choice() -> void:
	var content: GameContent = GameContent.load_default()
	var session: GameSession = content.new_session(15)
	session.start_round()
	var me: PlayerState = session.player(0)
	me.gold = 5
	me.tier = 6
	for i: int in 2:
		me.hand.append(session.new_unit(content.library.get_card(&"master-at-arms"), false))
	CoreKit.set_shop(session, me, ["master-at-arms"] as Array[String])
	var bot := FlowBot.new(Rng.derive(15, "bot"))
	var took: Array[String] = []
	var buys: Array[Dictionary] = []
	bot.take_turn(
		session,
		0,
		func(action: Dictionary) -> void:
			took.append(str(action["type"]))
			if action["type"] == "buy":
				buys.append(action)
	)
	assert_true(took.has("recruit_target"), "golden's doubled recruit effect was aimed")
	assert_false(buys.is_empty())
	assert_true(buys[0].has("target"), "buy selects a legal recruit target")
	assert_true(me.recruit_choices.is_empty())
	assert_true(me.turn_ended)
	assert_eq(bot.refused, 0, bot.last_refusal)
