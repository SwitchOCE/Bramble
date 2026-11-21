extends GutTest
## Rule 7.1.2: overflow gains persist until a hand place opens.

@warning_ignore_start("unsafe_call_argument")

const Kit := preload("res://tests/core/core_kit.gd")


func test_cousin_and_spell_wait_then_join_in_gain_order_on_sell_and_cast() -> void:
	var game: GameSession = Kit.content([], false, true).session(15)
	game.start_round()
	var p: PlayerState = game.player(0)
	p.gold = 10
	Kit.put(game, p, "needle-page", 0)
	p.hand.append(Kit.unit(game, "sp_sharpen"))
	for i: int in 5:
		p.hand.append(Kit.unit(game, "brock-cub", true))
	Kit.set_shop(game, p, ["hayloft-aunt"])
	assert_eq(game.act(0, {"type": "buy", "index": 0}), "")
	assert_eq(p.hand.size(), 7)
	assert_eq(p.waiting_pile.size(), 1)
	var cousin: Unit = p.waiting_pile[0]
	assert_eq(cousin.def.id, &"cousin", "the Aunt's recruit gives a Cousin with a full hand")
	var ctx := RecruitContext.new(game, game.recruit, p)
	var spell: Unit = ctx.give_card(&"sp_sharpen", null)
	assert_not_null(spell)
	assert_eq(p.waiting_pile, [cousin, spell] as Array[Unit])
	assert_null(p.find_uid(spell.uid), "waiting cards aren't selectable")
	assert_eq(game.act(0, {"type": "play", "hand": 7}), "no card at that hand position")
	assert_eq(game.act(0, {"type": "sell", "hand": 7}), "no unit at that hand position")

	assert_eq(game.act(0, {"type": "sell", "hand": 1}), "")
	assert_eq(p.hand.back(), cousin)
	assert_eq(p.waiting_pile, [spell] as Array[Unit])
	assert_eq(game.act(0, {"type": "play", "hand": 0, "target": p.board[0].uid}), "")
	assert_eq(p.hand.back(), spell)
	assert_true(p.waiting_pile.is_empty())
	assert_eq(p.hand.size(), 7)


func test_a_waiting_copy_counts_only_after_joining_and_the_triple_fills_its_vacancies() -> void:
	var game: GameSession = Kit.session()
	game.start_round()
	var p: PlayerState = game.player(0)
	for i: int in 5:
		p.hand.append(Kit.unit(game, "t1_plain", true))
	for i: int in 2:
		p.hand.append(Kit.unit(game, "t1_guard"))
	var ctx := RecruitContext.new(game, game.recruit, p)
	var third: Unit = ctx.give_card(&"t1_guard", null)
	var second: Unit = ctx.give_card(&"sp_sharpen", null)
	var last: Unit = ctx.give_card(&"sp_seek", null)
	game.recruit._settle(p)
	assert_eq(p.waiting_pile, [third, second, last] as Array[Unit])
	assert_true(Kit.log_of(game, "triple").is_empty())
	assert_eq(game.act(0, {"type": "play", "hand": 0, "slot": 0}), "")
	assert_eq(Kit.log_of(game, "triple").size(), 1)
	assert_eq(p.hand[4], second)
	assert_eq(p.hand[5], last)
	assert_true(p.hand[6].golden)
	assert_eq(p.hand[6].def.id, &"t1_guard")
	assert_eq(p.waiting_pile.size(), 1)
	assert_eq(p.waiting_pile[0].def.id, UnitLibrary.TRIPLE_REWARD_ID)


## Reproduce b01's two knights on board, two cubs and four spells in hand, then the third knight.
func test_b01_waiting_reward_survives_the_turn_and_replays_from_the_record() -> void:
	var game: GameSession = GameContent.load_default().new_session(224125, ["Badger"])
	game.start_round()
	_buy(game, 0)
	_buy(game, 3)
	assert_eq(game.act(0, {"type": "play", "hand": 1, "slot": 0}), "")
	_buy(game, 0, true)
	game.finish_round()
	game.start_round()
	_buy(game, 2)
	assert_eq(game.act(0, {"type": "play", "hand": 2, "slot": 2}), "")
	_buy(game, 0, true)
	_buy(game, 1, true)
	_buy(game, 1)
	assert_eq(game.act(0, {"type": "refresh"}), "")
	assert_eq(game.act(0, {"type": "freeze"}), "")
	game.finish_round()
	game.start_round()
	_buy(game, 0, true)
	assert_eq(game.act(0, {"type": "refresh"}), "")
	var p: PlayerState = game.player(0)
	assert_eq(p.hand.size(), 6)
	assert_eq(p.board_count(), 2)
	_buy(game, 2)
	assert_eq(p.hand.size(), 7)
	assert_eq(p.board_count(), 0)
	assert_true(p.hand[6].golden)
	assert_eq(p.hand[6].def.id, &"hedge-knight")
	assert_eq(p.waiting_pile.size(), 1)
	var reward: Unit = p.waiting_pile[0]
	assert_eq(reward.def.id, UnitLibrary.TRIPLE_REWARD_ID)

	game.finish_round()
	game.start_round()
	assert_eq(p.waiting_pile, [reward] as Array[Unit])
	var replay: Dictionary = RecordReplay.read(game.record.path)
	assert_true(CoreUtil.to_bool(replay["ok"]), str(replay.get("message", "")))
	if replay["ok"]:
		var rebuilt: GameSession = replay["session"]
		assert_eq(RecordState.state_hash(rebuilt), RecordState.state_hash(game))
		assert_eq(
			FightSnapshot.units(rebuilt.player(0).waiting_pile), FightSnapshot.units([reward])
		)
	assert_eq(game.act(0, {"type": "play", "hand": 6, "slot": 0}), "")
	assert_eq(p.hand[6], reward)
	assert_true(p.waiting_pile.is_empty())


func _buy(game: GameSession, index: int, spell: bool = false) -> void:
	assert_eq(game.act(0, {"type": "buy", "index": index, "spell": spell}), "")
