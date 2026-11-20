extends SceneTree
## Local record verification: -- record=<file> OR games=50 first_seed=1 [plant=1].
## Add ghost_store=<folder> for async generation or replay.
## The planted action replaces a successful buy with a freeze on turn 2; detection is required.


func _initialize() -> void:
	var options: Dictionary = {
		"games": "50",
		"first_seed": "1",
		"plant": "0",
		"record": "",
		"ghost_store": "",
		"directory": "res://build/records"
	}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		if not options.has(key) or not arg.contains("="):
			printerr("records: unknown argument %s" % arg)
			quit(2)
			return
		options[key] = arg.substr(key.length() + 1)
	quit(_check(options))


func _check(options: Dictionary) -> int:
	var store_path: String = str(options["ghost_store"])
	var store: GhostStore = GhostStore.new(store_path) if store_path != "" else null
	if str(options["record"]) != "":
		var result: Dictionary = RecordReplay.read(str(options["record"]), store)
		print("records: %s" % _describe(result))
		return 0 if CoreUtil.to_bool(result.get("ok", false)) else 1
	GameRecord.directory = str(options["directory"])
	var games: int = str(options["games"]).to_int()
	var first: int = str(options["first_seed"]).to_int()
	if games <= 0:
		printerr("records: games must be positive")
		return 2
	var ids: PackedStringArray = []
	if store != null:
		ids = _run_ids(store.directory)
		if ids.size() < 7:
			printerr("records: need at least 7 runs in %s" % store.directory)
			return 2
	return _check_games(games, first, store, ids, str(options["plant"]) == "1")


func _check_games(
	games: int, first: int, store: GhostStore, ids: PackedStringArray, plant: bool
) -> int:
	var content: GameContent = GameContent.load_default()
	var rounds: int = 0
	var checkpoints: int = 0
	var sizes: Array[int] = []
	var last_path: String = ""
	for index: int in games:
		var game_seed: int = first + index
		var game: GameSession = _new_game(content, game_seed, store, ids, index)
		if game == null:
			return 1
		game.keep_fight_events = false
		var bots: Dictionary[int, Bot] = {}
		for seat: int in game.players.size():
			# Exercise both purposeful play and random legal actions, with every shipped tribe.
			if game.runs.has(seat):
				continue
			var stream: Rng = Rng.derive(game_seed, "bot:%d" % seat)
			if seat % 2 == 0:
				bots[seat] = FlowBot.new(stream)
			else:
				bots[seat] = RandomBot.new(stream)
		while not game.over:
			game.start_round()
			for player: PlayerState in game.alive_players():
				if bots.has(player.id):
					bots[player.id].take_turn(game, player.id)
			game.finish_round()
			game.events.clear()
			game.fights.clear()
		last_path = game.record.path
		var result: Dictionary = RecordReplay.read(last_path, store)
		if not CoreUtil.to_bool(result.get("complete", false)):
			printerr("records: seed %d %s (%s)" % [game_seed, _describe(result), last_path])
			return 1
		for bot: Bot in bots.values():
			if bot.refused != 0:
				printerr("records: seed %d bot refused %s" % [game_seed, bot.last_refusal])
				return 1
		rounds += game.round_number
		checkpoints += CoreUtil.to_int(result["checkpoints"])
		var file: FileAccess = FileAccess.open(last_path, FileAccess.READ)
		sizes.append(file.get_length())
		print(
			(
				"records: seed %d matched %d turns (%d bytes)"
				% [game_seed, game.round_number, file.get_length()]
			)
		)
	sizes.sort()
	print(
		(
			"records: PASS %d%s games, %d seeds (%d..%d), %d turns, %d checkpoints; median %d bytes"
			% [
				games,
				" async" if store != null else "",
				games,
				first,
				first + games - 1,
				rounds,
				checkpoints,
				sizes[floori(sizes.size() / 2.0)]
			]
		)
	)
	if plant and not _plant(last_path, store):
		return 1
	return 0


func _run_ids(directory: String) -> PackedStringArray:
	var runs_path: String = directory.path_join("runs")
	var ids: PackedStringArray = []
	for shard: String in DirAccess.get_directories_at(runs_path):
		for file: String in DirAccess.get_files_at(runs_path.path_join(shard)):
			var id: String = file.get_basename()
			if file.ends_with(".json") and id.length() == 64 and id.left(2) == shard:
				ids.append(id)
	ids.sort()
	return ids


func _new_game(
	content: GameContent, seed_value: int, store: GhostStore, ids: PackedStringArray, index: int
) -> GameSession:
	if store == null:
		return content.new_session(seed_value)
	var runs: Dictionary[int, GhostRun] = {}
	for seat: int in range(1, 8):
		var id: String = ids[(index + seat - 1) % ids.size()]
		var result: Dictionary = store.fetch(id, content.library, content.registry)
		if not CoreUtil.to_bool(result["ok"]):
			printerr("records: %s" % result["message"])
			return null
		runs[seat] = result["run"]
	return content.new_async_session(seed_value, runs)


func _plant(path: String, store: GhostStore) -> bool:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n", false)
	var changed: bool = false
	for index: int in lines.size():
		var entry: Dictionary = CoreUtil.to_dict(JSON.parse_string(lines[index]))
		var action: Dictionary = CoreUtil.to_dict(entry.get("action", {}))
		if (
			entry.get("op") == "act"
			and CoreUtil.to_int(entry.get("turn", 0)) == 2
			and action.get("type") == "buy"
		):
			entry["action"] = {"type": "freeze"}
			lines[index] = JSON.stringify(entry)
			changed = true
			break
	if not changed:
		printerr("records: plant failed: no turn 2 buy")
		return false
	var planted: String = path.get_basename() + "-changed-action.jsonl"
	var file: FileAccess = FileAccess.open(planted, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	var result: Dictionary = RecordReplay.read(planted, store)
	print("records: changed one turn 2 buy to freeze: %s (%s)" % [_describe(result), planted])
	return (
		not CoreUtil.to_bool(result.get("ok", true))
		and CoreUtil.to_int(result.get("turn", -1)) == 2
	)


func _describe(result: Dictionary) -> String:
	if not CoreUtil.to_bool(result.get("ok", false)):
		return str(result.get("message", "failed"))
	return (
		"matched %d turns, %d checkpoints; %s"
		% [
			result["turns"],
			result["checkpoints"],
			"complete" if result["complete"] else "unfinished game"
		]
	)
