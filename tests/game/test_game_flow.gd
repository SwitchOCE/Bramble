extends GutTest
## The game flow plays a whole game: a scripted human in seat 0, bots in the rest.

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


## Plays the human's turn with a SimpleBot's choices, through the flow as a screen would.
func _human_turn(flow: GameFlow, bot: SimpleBot) -> int:
	var refused: int = 0
	for _step: int in Bot.MAX_ACTIONS:
		if flow.human().turn_ended:
			break
		var action: Dictionary = bot.choose(flow.session, flow.human())
		if flow.act(action) != "":
			refused += 1
			break
	return refused


func test_stand_in_content_loads_clean() -> void:
	assert_eq(_content.library.errors, PackedStringArray(), "no card errors")
	assert_gt(_content.library.pool_cards(false).size(), 10, "units to buy")
	assert_eq(_content.art_for("t1_plain"), "hedgehog-1", "stand-in art name")


func test_a_whole_game_ends_with_eight_placements() -> void:
	var flow: GameFlow = GameFlow.create(_content, 7)
	var human_bot := SimpleBot.new(Rng.derive(7, "human"))
	var refused: int = 0
	var fights_seen: int = 0
	for _round: int in 60:
		if flow.is_over() or not flow.human_alive():
			break
		flow.start_round()
		refused += _human_turn(flow, human_bot)
		var fight: Dictionary = flow.finish_round()
		if not fight.is_empty():
			fights_seen += 1
			var events: Array = fight["events"]
			var first: Dictionary = events[0]
			assert_eq(str(first["type"]), "combat_start", "a fight log")
			var before: Dictionary = fight["before"]
			assert_true(before.has("you"), "the human's view before the fight")
	if not flow.is_over():
		flow.play_out()
	assert_true(flow.is_over(), "the game ended")
	assert_eq(refused, 0, "the core refused none of the human's legal actions")
	assert_gt(fights_seen, 2, "the human fought")
	var places: Array = []
	for row: Dictionary in flow.standings():
		places.append(row["place"])
	assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8], "eight distinct placements")


func test_a_refused_action_returns_the_reason() -> void:
	var flow: GameFlow = GameFlow.create(_content, 3)
	flow.start_round()
	var reason: String = flow.act({"type": "upgrade"})
	assert_ne(reason, "", "turn 1 cannot afford the upgrade")


func test_bots_play_and_the_human_has_an_opponent() -> void:
	var flow: GameFlow = GameFlow.create(_content, 11)
	flow.start_round()
	assert_ne(flow.session.opponent_of(GameFlow.HUMAN), -2, "paired")
	flow.act({"type": "end_turn"})
	flow.finish_round()
	var bought: int = 0
	for seat: int in range(1, 8):
		bought += flow.session.player(seat).board_count()
	assert_gt(bought, 0, "the bots bought and played units")
