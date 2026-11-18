extends SceneTree
## Local record verification: -- record=<file> OR games=50 first_seed=1 [plant=1].
## The planted action replaces a successful buy with a freeze on turn 2; detection is required.


func _initialize() -> void:
	var options: Dictionary = {
		"games": "50",
		"first_seed": "1",
		"plant": "0",
		"record": "",
		"directory": "res://build/records"
	}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		if not options.has(key) or not arg.contains("="):
			printerr("records: unknown argument %s" % arg)
			quit(2)
			return
		options[key] = arg.substr(key.length() + 1)
	if str(options["record"]) != "":
		var result: Dictionary = RecordReplay.read(str(options["record"]))
		print("records: %s" % _describe(result))
		quit(0 if CoreUtil.to_bool(result.get("ok", false)) else 1)
		return
	GameRecord.directory = str(options["directory"])
	var games: int = str(options["games"]).to_int()
	var first: int = str(options["first_seed"]).to_int()
	if games <= 0:
		printerr("records: games must be positive")
		quit(2)
		return
	var content: GameContent = GameContent.load_default()
	var rounds: int = 0
	var checkpoints: int = 0
	var sizes: Array[int] = []
	var last_path: String = ""
	for index: int in games:
		var game_seed: int = first + index
		var game: GameSession = content.new_session(game_seed)
		game.keep_fight_events = false
		var bots: Array[Bot] = []
		for seat: int in game.players.size():
			# Exercise both purposeful play and random legal actions, with every shipped tribe.
			var stream: Rng = Rng.derive(game_seed, "bot:%d" % seat)
			if seat % 2 == 0:
				bots.append(FlowBot.new(stream))
			else:
				bots.append(RandomBot.new(stream))
		while not game.over:
			game.start_round()
			for player: PlayerState in game.alive_players():
				bots[player.id].take_turn(game, player.id)
			game.finish_round()
			game.events.clear()
			game.fights.clear()
		last_path = game.record.path
		var result: Dictionary = RecordReplay.read(last_path)
		if not CoreUtil.to_bool(result.get("ok", false)):
			printerr("records: seed %d %s (%s)" % [game_seed, _describe(result), last_path])
			quit(1)
			return
		for bot: Bot in bots:
			if bot.refused != 0:
				printerr("records: seed %d bot refused %s" % [game_seed, bot.last_refusal])
				quit(1)
				return
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
			"records: PASS %d games, %d seeds (%d..%d), %d turns, %d checkpoints; median %d bytes"
			% [
				games,
				games,
				first,
				first + games - 1,
				rounds,
				checkpoints,
				sizes[floori(sizes.size() / 2.0)]
			]
		)
	)
	if str(options["plant"]) == "1" and not _plant(last_path):
		quit(1)
		return
	quit(0)


func _plant(path: String) -> bool:
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
	var result: Dictionary = RecordReplay.read(planted)
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
