extends GutTest

@warning_ignore_start("unsafe_call_argument")

const FIXTURE: String = "res://tests/core/fixtures/ghost_run.json"
const MADE: String = "2026-11-20T12:00:00Z"


func test_cuts_finished_live_seat_with_record_provenance_and_fight_payload() -> void:
	var store := GhostStore.new(GameRecord.directory.path_join("writer-opponents"))
	var id: String = store.add(FileAccess.get_file_as_bytes(FIXTURE))
	assert_ne(id, "", store.error)
	var game: GameSession = _new_game(store, id)
	game.start_round()
	assert_eq(game.act(0, {"type": "freeze"}), "")
	game.end_turn(0)
	var player: PlayerState = game.player(0)
	var economy: Array[int] = [player.health, player.armor, player.gold]
	game.finish_round()
	var result: Dictionary = GhostRunWriter.cut(game.record, MADE, "player-42", "local", store)
	assert_true(CoreUtil.to_bool(result["ok"]), str(result.get("message", "")))
	if not result["ok"]:
		return
	var bytes: PackedByteArray = result["bytes"]
	var run: Dictionary = CoreUtil.to_dict(
		RecordState.value(JSON.parse_string(bytes.get_string_from_utf8()))
	)
	assert_eq(result["id"], GhostJson.sha256(bytes))
	assert_eq(
		run["source"],
		{
			"kind": "player",
			"label": "local",
			"player": "player-42",
			"rating": null,
			"record_sha256": FileAccess.get_sha256(game.record.path),
			"record_mode": "async",
			"game_seed": "-8172",
			"seat": 0,
		}
	)
	assert_eq(run["rules"], RecordBuild.identity())
	assert_eq(run["made"], MADE)
	assert_eq(run["placement"], player.placement)
	assert_eq(run["ended"], "round_limit")
	assert_eq(run["last_turn"], 1)
	var turn: Dictionary = run["turns"][0]
	assert_eq([turn["health"], turn["armor"], turn["gold"]], economy)
	assert_eq(turn["acts"], [{"action": {"type": "freeze"}, "result": ""}])
	var decoded: Dictionary = RecordReplay.decode(FileAccess.get_file_as_bytes(game.record.path))
	var entries: Array[Dictionary] = decoded["entries"]
	var fights: Array[Dictionary] = entries.filter(
		func(entry: Dictionary) -> bool: return entry["op"] == "fight_boards"
	)
	var fight: Dictionary = fights[0]
	assert_eq(turn["payload"], RecordState.value(fight["players"][0]))
	assert_eq(store.add(bytes), result["id"])


func test_rejects_unfinished_records_missing_opponents_and_missing_time() -> void:
	var store := GhostStore.new(GameRecord.directory.path_join("writer-unfinished-opponents"))
	var id: String = store.add(FileAccess.get_file_as_bytes(FIXTURE))
	assert_ne(id, "", store.error)
	var game: GameSession = _new_game(store, id)
	game.start_round()
	var unfinished: Dictionary = GhostRunWriter.cut(game.record, MADE, "player", "local", store)
	assert_eq(unfinished, {"ok": false, "message": "game record is unfinished"})
	var no_store: Dictionary = GhostRunWriter.cut(game.record, MADE, "player", "local")
	assert_string_contains(str(no_store.get("message")), "no ghost store for run")
	assert_eq(
		GhostRunWriter.cut(game.record, "", "player", "local", store),
		{
			"ok": false,
			"message": "missing made time",
		}
	)


func _new_game(store: GhostStore, id: String) -> GameSession:
	var content: GameContent = GameContent.load_default()
	var fetched: Dictionary = store.fetch(id, content.library, content.registry)
	var run: GhostRun = fetched["run"]
	var runs: Dictionary[int, GhostRun] = {}
	for seat: int in range(1, 8):
		runs[seat] = run
	var game: GameSession = content.new_async_session(-8172, runs)
	game.config.round_limit = 1
	return game
