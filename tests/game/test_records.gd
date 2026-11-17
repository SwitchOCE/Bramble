extends GutTest
## Records are read back from disk, not replayed from an in-memory copy of the game's inputs.

var _content: GameContent
var _previous_directory: String


func before_all() -> void:
	_content = GameContent.load_default()
	_previous_directory = GameRecord.directory
	GameRecord.directory = "res://build/test-records"


func after_all() -> void:
	GameRecord.directory = _previous_directory


func _play(game_seed: int, turns: int = 3) -> GameSession:
	var game: GameSession = _content.new_session(game_seed)
	game.config.round_limit = turns
	game.keep_fight_events = false
	var bots: Array[Bot] = []
	for seat: int in game.players.size():
		bots.append(FlowBot.new(Rng.derive(game_seed, "bot:%d" % seat)))
	while not game.over:
		game.start_round()
		for player: PlayerState in game.alive_players():
			bots[player.id].take_turn(game, player.id)
		game.finish_round()
	return game


func _entries(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		out.append(CoreUtil.to_dict(JSON.parse_string(line)))
	return out


func test_seeded_games_rebuild_all_turns_and_hidden_state_from_disk() -> void:
	for game_seed: int in [1, 7, 29, 999, 9223372036854775807]:
		var game: GameSession = _play(game_seed)
		var replay: Dictionary = RecordReplay.read(game.record.path)
		assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
		if not CoreUtil.to_bool(replay.get("ok", false)):
			continue
		assert_true(CoreUtil.to_bool(replay["complete"]))
		assert_eq(CoreUtil.to_int(replay["checkpoints"]), game.round_number * 3)
		var rebuilt: GameSession = replay["session"]
		assert_eq(RecordState.state_hash(rebuilt), RecordState.state_hash(game))
		assert_null(rebuilt.record, "replay does not create a second record")


func test_one_changed_action_names_the_first_differing_turn() -> void:
	var game: GameSession = _play(17)
	var entries: Array[Dictionary] = _entries(game.record.path)
	var changed: bool = false
	for entry: Dictionary in entries:
		var action: Dictionary = CoreUtil.to_dict(entry.get("action", {}))
		if (
			entry.get("op") == "act"
			and CoreUtil.to_int(entry.get("turn", 0)) == 2
			and action.get("type") in ["buy", "upgrade", "refresh"]
		):
			entry["action"] = {"type": "freeze"}
			changed = true
			break
	assert_true(changed, "planted a changed action on turn 2")
	if not changed:
		return
	var replay: Dictionary = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_eq(CoreUtil.to_int(replay["turn"]), 2)
	assert_string_contains(str(replay["message"]), "first differing turn 2")


func test_partial_human_game_records_refusals_and_explicit_end_turns() -> void:
	var flow: GameFlow = GameFlow.create(_content, 41, ["mouse", "badger"])
	flow.start_round()
	assert_ne(flow.act({"type": "upgrade"}), "", "refused input is also retained")
	flow.session.end_turn(0)
	flow.finish_round()
	flow.start_round()
	flow.act({"type": "freeze"})
	var replay: Dictionary = RecordReplay.read(flow.session.record.path)
	assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
	assert_false(CoreUtil.to_bool(replay.get("complete", true)), "quit during recruit")
	if replay.get("ok", false):
		var rebuilt: GameSession = replay["session"]
		assert_eq(RecordState.state_hash(rebuilt), RecordState.state_hash(flow.session))
	var header: Dictionary = _entries(flow.session.record.path)[0]
	assert_true(header.has("build"))
	assert_eq(str(header["seed"]), "41")


func test_core_bot_runner_recipe_and_nondefault_config_replay() -> void:
	var content: ContentSet = ContentSet.load_folders(
		["res://src/content/shared", "res://tests/core/content/neutral"]
	)
	var config := GameConfig.new()
	config.players = 4
	config.round_limit = 2
	config.starting_armor = 5
	var game: GameSession = content.session(1234, config)
	while not game.over:
		game.start_round()
		for player: PlayerState in game.alive_players():
			var bot := RandomBot.new(
				Rng.derive(game.seed_value, "bot:%d:%d" % [player.id, game.round_number])
			)
			bot.take_turn(game, player.id)
		game.finish_round()
	var replay: Dictionary = RecordReplay.read(game.record.path)
	assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
	assert_true(CoreUtil.to_bool(replay.get("complete", false)))


func test_fight_boards_are_after_end_turn_with_all_ghost_rules_data() -> void:
	var game: GameSession = _play(17, 2)
	var snapshots: int = 0
	var actions_by_player: Dictionary = {}
	for entry: Dictionary in _entries(game.record.path):
		if entry.get("op") == "act":
			actions_by_player[CoreUtil.to_int(entry["player"])] = true
		if entry.get("op") != "fight_boards":
			continue
		snapshots += 1
		var players: Array = entry["players"]
		assert_eq(players.size(), 8, "all eight players before early fights")
		for raw: Variant in players:
			var player: Dictionary = raw
			for key: String in [
				"id", "tier", "board", "hand", "slots", "counters", "heaps", "standing"
			]:
				assert_true(player.has(key), "ghost has %s" % key)
			var board: Array = player["board"]
			assert_eq(board.size(), game.geometry.slot_count)
			for unit_raw: Variant in board:
				if unit_raw == null:
					continue
				var unit: Dictionary = unit_raw
				var stats: Dictionary = unit["stats"]
				assert_eq(CoreUtil.to_int(stats["turn_attack"]), 0, "this-turn buffs ended")
				assert_true(unit.has("mechanics"))
				assert_true(unit.has("def"), "card id for reconstruction")
	assert_eq(snapshots, 2)
	assert_eq(actions_by_player.size(), 8, "every player's actions")


func test_hash_covers_state_that_the_ui_omits() -> void:
	var game: GameSession = _content.new_session(5)
	game.record_recipe = {}
	game.start_round()
	var previous: String = RecordState.state_hash(game)
	game.player(0).gold_next_turn += 1
	assert_ne(RecordState.state_hash(game), previous)
	previous = RecordState.state_hash(game)
	game.recruit.shop_rng(game.player(0)).next_u32()
	assert_ne(RecordState.state_hash(game), previous, "RNG words")
	previous = RecordState.state_hash(game)
	game.player(0).heap(&"test").add(&"id", 1)
	assert_ne(RecordState.state_hash(game), previous, "heap")
	var heap: CardHeap = game.player(0).heap(&"test")
	heap.entries.clear()
	previous = RecordState.state_hash(game)
	heap.add(&"id", 1)
	heap.entries.clear()
	assert_ne(RecordState.state_hash(game), previous, "heap sequence even when empty")
	previous = RecordState.state_hash(game)
	game.units.take(game.units.ids()[0])
	assert_ne(RecordState.state_hash(game), previous, "shared pool")


func test_same_seed_games_get_separate_files_and_changed_build_is_refused() -> void:
	var first: GameSession = _play(7, 1)
	var second: GameSession = _play(7, 1)
	assert_ne(first.record.path, second.record.path)
	var entries: Array[Dictionary] = _entries(first.record.path)
	var build: Dictionary = entries[0]["build"]
	build["rules_hash"] = "different"
	var replay: Dictionary = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_string_contains(str(replay["message"]), "build differs")


func test_missing_checkpoint_or_unknown_operation_fails() -> void:
	var game: GameSession = _play(7, 1)
	var entries: Array[Dictionary] = _entries(game.record.path)
	entries[1].erase("hash")
	var replay: Dictionary = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_eq(CoreUtil.to_int(replay["turn"]), 1)
	entries = _entries(game.record.path)
	entries[1]["op"] = "bogus"
	replay = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_string_contains(str(replay["message"]), "unknown operation")


func test_ghost_opponents_keep_their_actual_board_and_reserve_hand() -> void:
	var game: GameSession = _play(3, 50)
	var ghost_fights: int = 0
	for entry: Dictionary in _entries(game.record.path):
		if entry.get("op") != "fight_boards":
			continue
		var players: Array = entry["players"]
		for raw: Variant in players:
			var player: Dictionary = raw
			if CoreUtil.to_int(player["id"]) != Matchmaking.GHOST:
				continue
			ghost_fights += 1
			assert_true(player.has("of"))
			assert_eq(CoreUtil.to_array(player["board"]).size(), game.geometry.slot_count)
			assert_true(player.has("hand"))
	assert_gt(ghost_fights, 0, "a complete game encountered the eliminated player's ghost")
	var replay: Dictionary = RecordReplay.read(game.record.path)
	assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
