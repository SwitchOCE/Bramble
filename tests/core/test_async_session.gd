extends GutTest

@warning_ignore_start("unsafe_call_argument")

const A1_PATH: String = "res://tests/core/fixtures/ghost_run.json"
# First three turns of seats 0 and 1 of a live records.sh game (seed 1001).
const FLOW_PATH: String = "res://tests/core/fixtures/async_run_0.json"
const RANDOM_PATH: String = "res://tests/core/fixtures/async_run_1.json"
# Seed 1001's first two turns. Regenerate after content changes: scripts/records.sh games=1
# first_seed=1001 directory=<dir>, then hash that record through turn 2's finish as below.
const LIVE_REFERENCE: String = "cb8cf48274140598649f5fe4146e19d081a87259c524dce38b078dc81ae54ec4"

var _content: GameContent
var _short: GhostRun
var _flow: GhostRun
var _random: GhostRun
var _store: GhostStore


class FightProbe:
	extends Mechanic

	func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
		combat.bridge(unit.side).add_gold(1, unit)
		combat.buff(unit, 1, 1, unit, true)

	func on_start_of_turn(
		ctx: RecruitContext, unit: Unit, report: FightReport, _params: MechanicParams
	) -> void:
		if report != null:
			ctx.buff(unit, 1, 1, true, unit)


func before_all() -> void:
	_content = GameContent.load_default()
	_store = GhostStore.new(GameRecord.directory.path_join("async-store"))
	_short = _put_run(A1_PATH, _store)
	_flow = _put_run(FLOW_PATH, _store)
	_random = _put_run(RANDOM_PATH, _store)


func _run_path(store: GhostStore, id: String) -> String:
	return store.directory.path_join("runs").path_join(id.left(2)).path_join(id + ".json")


func _put_run(source: String, store: GhostStore) -> GhostRun:
	var loaded: Dictionary = GhostRun.read(source, _content.library, _content.registry)
	assert_true(CoreUtil.to_bool(loaded["ok"]), str(loaded.get("message", source)))
	var run: GhostRun = loaded["run"]
	var path: String = _run_path(store, run.id)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(FileAccess.get_file_as_bytes(source))
	file.close()
	return run


func _lobby(other: GhostRun) -> Dictionary[int, GhostRun]:
	var runs: Dictionary[int, GhostRun] = {1: other}
	for seat: int in range(2, 8):
		runs[seat] = _flow
	return runs


func _rounds(game: GameSession, count: int) -> void:
	for _turn: int in count:
		game.start_round()
		game.finish_round()


func _entries(path: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		entries.append(CoreUtil.to_dict(JSON.parse_string(line)))
	return entries


func _fight_boards(game: GameSession, turn: int) -> Dictionary:
	for entry: Dictionary in _entries(game.record.path):
		if entry["op"] == "fight_boards" and entry["turn"] == turn:
			return entry
	return {}


func test_a_live_seat_and_seven_run_seats_play_out_after_live_elimination() -> void:
	var game: GameSession = _content.new_async_session(1001, _lobby(_short))
	game.keep_fight_events = false
	for seat: int in game.players.size():
		assert_eq(game.player(seat).health, game.config.starting_health)
		assert_eq(game.player(seat).armor, game.config.starting_armor)
	while not game.over:
		game.start_round()
		assert_eq(game.player(1).gold, 0)
		assert_true(game.player(1).turn_ended)
		assert_eq(game.player(1).shop_units.size(), 0)
		for seat: int in range(1, 8):
			assert_eq(game.legal_actions(seat).size(), 0)
		game.finish_round()
	assert_false(game.player(0).alive)
	assert_lt(game.player(0).eliminated_round, game.round_number)
	var places: Array = game.placements().values()
	places.sort()
	assert_eq(places, range(1, 9))


func test_async_record_replays_all_checkpoints_and_accepts_foreign_shipped_content_paths() -> void:
	var game: GameSession = _content.new_async_session(1002, _lobby(_short))
	game.config.round_limit = 5
	var bot := FlowBot.new(Rng.derive(game.seed_value, "bot:0"))
	while not game.over:
		game.start_round()
		bot.take_turn(game, 0)
		game.finish_round()
	var entries: Array[Dictionary] = _entries(game.record.path)
	var header: Dictionary = entries[0]
	assert_eq(header["format"], 4.0)
	assert_eq(header["mode"], "async")
	assert_eq(CoreUtil.to_array(header["runs"]).size(), 7)
	for entry: Dictionary in entries:
		if entry["op"] in ["act", "end"]:
			assert_eq(entry["player"], 0.0)
	var replay: Dictionary = RecordReplay.read(game.record.path, _store)
	assert_true(CoreUtil.to_bool(replay["ok"]), str(replay.get("message", "")))
	if replay.get("ok"):
		assert_true(CoreUtil.to_bool(replay["complete"]))
		assert_eq(replay["checkpoints"], game.round_number * 3)
		var rebuilt: GameSession = replay["session"]
		assert_eq(RecordState.state_hash(rebuilt), RecordState.state_hash(game))
		assert_eq(rebuilt.run_ids, game.run_ids)
	var recipe: Dictionary = header["recipe"]
	var paths: Array = recipe["paths"]
	for i: int in paths.size():
		paths[i] = "/another-checkout/src/content/" + str(paths[i]).get_file()
	var relocated: Dictionary = RecordReplay.rebuild(entries, _store)
	assert_true(CoreUtil.to_bool(relocated["ok"]), str(relocated.get("message", "")))


func test_eight_live_seats_match_the_pinned_live_record() -> void:
	var game: GameSession = _content.new_session(1001)
	var bots: Array[Bot] = []
	for seat: int in game.players.size():
		var stream: Rng = Rng.derive(game.seed_value, "bot:%d" % seat)
		if seat % 2 == 0:
			bots.append(FlowBot.new(stream))
		else:
			bots.append(RandomBot.new(stream))
	for _turn: int in 2:
		game.start_round()
		for seat: int in game.players.size():
			bots[seat].take_turn(game, seat)
		game.finish_round()
	var entries: Array[Dictionary] = _entries(game.record.path)
	var header: Dictionary = entries[0]
	assert_eq(header["format"], 4.0)
	assert_eq(header["mode"], "live")
	assert_eq(header["runs"], [])
	assert_true(CoreUtil.to_bool(RecordReplay.read(game.record.path)["ok"]))
	# The prefix comes from scripts/records.sh (seed 1001, turns 1-2), without header metadata.
	for key: String in ["format", "build", "mode", "runs"]:
		header.erase(key)
	assert_eq(JSON.stringify(RecordState.value(entries)).sha256_text(), LIVE_REFERENCE)


func test_swapping_a_valid_run_id_in_the_record_fails_at_turn_zero() -> void:
	var game: GameSession = _content.new_async_session(1003, _lobby(_short))
	_rounds(game, 1)
	var entries: Array[Dictionary] = _entries(game.record.path)
	var runs: Array = entries[0]["runs"]
	var swapped: Dictionary = runs[0]
	swapped["id"] = _flow.id
	var planted: String = game.record.path.get_basename() + "-changed-run.jsonl"
	var file := FileAccess.open(planted, FileAccess.WRITE)
	for entry: Dictionary in entries:
		file.store_line(JSON.stringify(entry))
	file.close()
	var replay: Dictionary = RecordReplay.read(planted, _store)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_eq(replay["turn"], 0)
	assert_string_contains(str(replay["message"]), "first differing turn 0: initial state differs")


func test_a_missing_run_and_one_changed_byte_fail_before_turn_one_and_name_the_run() -> void:
	var game: GameSession = _content.new_async_session(1004, _lobby(_short))
	_rounds(game, 1)
	var missing_store := GhostStore.new(GameRecord.directory.path_join("missing-store"))
	var missing: Dictionary = RecordReplay.read(game.record.path, missing_store)
	assert_false(CoreUtil.to_bool(missing["ok"]))
	assert_eq(missing["turn"], 0)
	assert_string_contains(str(missing["message"]), "run %s: cannot open" % _short.id)

	var tampered := GhostStore.new(GameRecord.directory.path_join("tampered-store"))
	_put_run(A1_PATH, tampered)
	var path: String = _run_path(tampered, _short.id)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	# Leave the JSON and payloads valid by changing only the final newline to a space.
	bytes[bytes.size() - 1] = 32
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()
	var altered: Dictionary = RecordReplay.read(game.record.path, tampered)
	assert_false(CoreUtil.to_bool(altered["ok"]))
	assert_eq(altered["turn"], 0)
	assert_string_contains(str(altered["message"]), "run %s: SHA-256 mismatch" % _short.id)


func test_an_ended_run_keeps_its_last_board_and_logs_the_reason() -> void:
	var game: GameSession = _content.new_async_session(1005, _lobby(_short))
	_rounds(game, _short.last_turn - 1)
	var player: PlayerState = game.player(1)
	game.start_round()
	assert_eq(player.board_units().size(), 0, "turn four's Sentry is hidden during recruit")
	assert_eq(player.tier, 2)
	assert_ne(game.act(1, {"type": "end_turn"}), "")
	game.end_turn(1)
	game.finish_round()
	var last: Array = FightSnapshot.units(player.board)
	assert_eq(player.board_units().size(), 1)
	assert_eq(player.board_units()[0].uid, GhostRun.UID_STRIDE + 63)
	game.start_round()
	game.finish_round()
	assert_eq(FightSnapshot.units(player.board), last)
	assert_eq(player.slots[3].renown, 1, "the Sentry never ran End of Turn a second time")
	var next_round: int = _short.last_turn + 1
	var fight_boards: Dictionary = _fight_boards(game, next_round)
	var board_sources: Array = fight_boards["run_boards"]
	assert_eq(
		RecordState.value(board_sources[0]), {"seat": 1, "run_turn": 4, "reason": "run_ended"}
	)
	assert_has(
		game.events,
		{"type": "run_board", "round": next_round, "seat": 1, "run_turn": 4, "reason": "run_ended"}
	)
	assert_has(
		game.events,
		{"type": "run_board", "round": 4, "seat": 1, "run_turn": 4, "reason": "same_turn"}
	)


func test_run_against_run_both_sides_fight_without_persistent_effects() -> void:
	var content: GameContent = GameContent.load_default()
	content.registry.register(&"core_async_probe", FightProbe.new())
	var data: Dictionary = CoreUtil.to_dict(
		JSON.parse_string(FileAccess.get_file_as_string(FLOW_PATH))
	)
	var turns: Array = data["turns"]
	var turn: Dictionary = turns[0]
	var payload: Dictionary = turn["payload"]
	var board: Array = payload["board"]
	var saved_attack: int = 0
	for i: int in board.size():
		if board[i] != null:
			var unit: Dictionary = board[i]
			var stats: Dictionary = CoreUtil.to_dict(unit.get("stats"))
			saved_attack = CoreUtil.to_int(stats.get("perm_attack", 0))
			unit["grants"] = [["core_async_probe"]]
			break
	var parsed: Dictionary = GhostRun.parse(
		JSON.stringify(data).to_utf8_buffer(), content.library, content.registry
	)
	assert_true(CoreUtil.to_bool(parsed["ok"]), str(parsed.get("message", "")))
	var run: GhostRun = parsed["run"]
	var runs: Dictionary[int, GhostRun] = {}
	for seat: int in range(1, 8):
		runs[seat] = run
	var game: GameSession = content.new_async_session(1006, runs)
	game.record_recipe = {}
	game.start_round()
	var fights: Array[Dictionary] = game.finish_round()
	var tested: int = 0
	for fight: Dictionary in fights:
		var seats: Array = fight["players"]
		if seats.has(0):
			continue
		var buffed: Array[int] = []
		for event: Dictionary in fight["events"]:
			if event["type"] == "buff":
				assert_false(CoreUtil.to_bool(event["permanent"]))
				buffed.append(CoreUtil.to_int(event["side"]))
		buffed.sort()
		assert_eq(buffed, [0, 1], "both sides applied their combat effect")
		for seat: int in seats:
			var player: PlayerState = game.player(seat)
			assert_eq(player.gold_next_turn, 0)
			assert_null(player.last_fight_report, "the recorded seat receives no report")
			assert_eq(player.board_units()[0].stats.perm_attack, saved_attack)
		var first: PlayerState = game.player(CoreUtil.to_int(seats[0]))
		var second: PlayerState = game.player(CoreUtil.to_int(seats[1]))
		assert_ne(first.board_units()[0].uid, second.board_units()[0].uid)
		tested += 1
	assert_eq(tested, 3)
	game.start_round()
	for seat: int in range(1, 8):
		assert_eq(game.player(seat).gold, 0)
		assert_eq(game.player(seat).board_units()[0].stats.perm_attack, saved_attack)


func test_a_stand_in_uses_the_eliminated_run_seats_last_fought_board() -> void:
	var game: GameSession = _content.new_async_session(1007, _lobby(_random))
	_rounds(game, 1)
	game.start_round()
	game.player(1).health = 1
	var opponent: int = game.opponent_of(1)
	if opponent == 0:
		var unit: Unit = game.new_unit(_content.library.get_card(&"hedge-knight"), false)
		unit.stats.perm_attack = 100
		unit.stats.perm_health = 100
		unit.slot = 0
		game.player(0).board[0] = unit
	game.finish_round()
	assert_false(game.player(1).alive)
	assert_eq(game.ghost_of, 1)
	var last_fought: Array = FightSnapshot.units(game.player(1).board)
	assert_eq(last_fought, FightSnapshot.units(game.ghost_board))
	assert_eq(game.player(1).board_units().size(), 1, "turn two brought a Husk Sentry")
	assert_eq(CoreUtil.to_array(_random.payload_for_round(3)["board"]).count(null), 7)
	game.start_round()
	assert_true(game.pairings.any(func(pair: Array) -> bool: return pair.has(Matchmaking.GHOST)))
	game.finish_round()
	var players: Array = _fight_boards(game, 3)["players"]
	var stand_in: Dictionary = players.back()
	assert_eq(stand_in["id"], -1.0)
	assert_eq(stand_in["of"], 1.0)
	assert_eq(RecordState.value(stand_in["board"]), last_fought)
