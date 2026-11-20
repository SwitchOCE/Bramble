class_name FlowFixture
extends GameFlow
## Live opponents are only used by tests that exercise recruit actions in several seats.

static var _field: String
var bots: Array[Bot] = []


static func live(
	game_content: GameContent, seed_value: int, tribe_ids: PackedStringArray = []
) -> FlowFixture:
	var flow := FlowFixture.new()
	flow.content = game_content
	flow.game_seed = seed_value
	flow.session = game_content.new_session(seed_value, game_content.lobby_names(tribe_ids))
	var seats: Array[Bot] = [null]
	for seat: int in range(1, flow.session.players.size()):
		seats.append(FlowBot.new(Rng.derive(seed_value, "bot:%d" % seat)))
	flow.bots = seats
	return flow


static func test_store() -> LayeredGhostStore:
	if _field.is_empty():
		_field = new_root().path_join("field")
		_cut_field(GameContent.load_default(), GhostStore.new(_field), 14)
	return LayeredGhostStore.new(new_root().path_join("player"), _field)


static func new_root() -> String:
	return GameRecord.directory.path_join(
		"ghost-tests-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	)


static func _cut_field(game_content: GameContent, store: GhostStore, count: int) -> void:
	for index: int in count:
		var seed_value: int = 100 + index
		var game: GameSession = game_content.new_session(seed_value)
		game.config.round_limit = 5
		game.keep_fight_events = false
		var drivers: Array[Bot] = []
		for seat: int in game.players.size():
			drivers.append(FlowBot.new(Rng.derive(seed_value, "bot:%d" % seat)))
		while not game.over:
			game.start_round()
			for player: PlayerState in game.alive_players():
				drivers[player.id].take_turn(game, player.id)
			game.finish_round()
		var cut: Dictionary = GhostRunWriter.cut(
			game.record, "2026-11-20T00:00:00Z", "fixture", "fixture"
		)
		assert(cut["ok"], str(cut.get("message", "")))
		var bytes: PackedByteArray = cut["bytes"]
		var run: Dictionary = CoreUtil.to_dict(JSON.parse_string(bytes.get_string_from_utf8()))
		run["source"]["kind"] = "bot"
		var id: String = store.add(GhostJson.encode(RecordState.value(run)).to_utf8_buffer())
		assert(not id.is_empty(), store.error)


func finish_round() -> Dictionary:
	_bots_take_turns()
	return super.finish_round()


func play_out_round() -> bool:
	session.keep_fight_events = false
	if not session.over:
		session.start_round()
		_bots_take_turns()
		session.finish_round()
	return session.over


func _bots_take_turns() -> void:
	for seat: int in range(1, bots.size()):
		var each: PlayerState = session.player(seat)
		if each.alive and not each.turn_ended:
			bots[seat].take_turn(session, seat)
