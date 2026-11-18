extends SceneTree
## Record oracle: -- games=N seed=start out=/absolute/directory [folders=shared,badger]
## Empty folders (the default) loads stand-ins; names resolve under res://src/content/.
## Each record has a companion .legal.jsonl with the ordered legal actions before every
## turn-1 bot decision. record_index is the zero-based index of the next record operation.


func _initialize() -> void:
	var options: Dictionary = {"games": "1", "seed": "1", "out": "/home/alex/league/records/standin/", "folders": ""}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		if not arg.contains("=") or not options.has(key):
			printerr("standin_records: unknown argument %s" % arg)
			quit(2)
			return
		options[key] = arg.substr(key.length() + 1)
	var games: int = str(options["games"]).to_int()
	var first: int = str(options["seed"]).to_int()
	if games <= 0:
		printerr("standin_records: games must be positive")
		quit(2)
		return
	GameRecord.directory = str(options["out"])
	var paths: PackedStringArray = []
	for folder: String in str(options["folders"]).split(",", false):
		if folder.contains("/") or folder.contains("\\") or folder == "." or folder == "..":
			printerr("standin_records: folders must be src/content folder names")
			quit(2)
			return
		paths.append("res://src/content/" + folder)
	var content: GameContent = GameContent.load_folders(paths)
	if not content.errors.is_empty():
		printerr("standin_records: content failed: %s" % content.errors)
		quit(1)
		return
	var checkpoints: int = 0
	var decisions: int = 0
	for index: int in games:
		var game_seed: int = first + index
		var game: GameSession = content.new_session(game_seed)
		game.keep_fight_events = false
		var bots: Array[Bot] = []
		for seat: int in game.players.size():
			var stream: Rng = Rng.derive(game_seed, "bot:%d" % seat)
			if seat % 2 == 0:
				bots.append(FlowBot.new(stream))
			else:
				bots.append(RandomBot.new(stream))
		var legal_file: FileAccess
		while not game.over:
			game.start_round()
			if game.round_number == 1:
				legal_file = FileAccess.open(game.record.path.get_basename() + ".legal.jsonl", FileAccess.WRITE)
				if legal_file == null:
					printerr("standin_records: cannot write legal actions")
					quit(1)
					return
			for player: PlayerState in game.alive_players():
				if game.round_number == 1:
					decisions += _take_first_turn(bots[player.id], game, player, legal_file)
				else:
					bots[player.id].take_turn(game, player.id)
			game.finish_round()
			game.events.clear()
			game.fights.clear()
		if legal_file != null:
			legal_file.close()
		var result: Dictionary = RecordReplay.read(game.record.path)
		if not CoreUtil.to_bool(result.get("ok", false)):
			printerr("standin_records: seed %d %s (%s)" % [game_seed, result, game.record.path])
			quit(1)
			return
		for bot: Bot in bots:
			if bot.refused != 0:
				printerr("standin_records: seed %d bot refused %s" % [game_seed, bot.last_refusal])
				quit(1)
				return
		checkpoints += CoreUtil.to_int(result["checkpoints"])
		print("standin_records: seed %d matched %d turns (%s)" % [game_seed, game.round_number, game.record.path])
	print("standin_records: PASS %d games, %d checkpoints, %d turn-1 decisions" % [games, checkpoints, decisions])
	quit(0)


## Bot.take_turn line for line, with an observational dump before choose (no RNG draws).
func _take_first_turn(bot: Bot, game: GameSession, player: PlayerState, file: FileAccess) -> int:
	var decisions: int = 0
	for step: int in Bot.MAX_ACTIONS:
		if player.turn_ended or not player.alive:
			return decisions
		var record_index: int = FileAccess.get_file_as_string(game.record.path).split("\n", false).size()
		file.store_line(JSON.stringify({
			"seed": str(game.seed_value), "record": game.record.path,
			"turn": game.round_number, "phase": "recruit", "player": player.id,
			"action_index": step, "record_index": record_index,
			"legal": LegalActions.of(game, player)
		}))
		file.flush()
		decisions += 1
		var action: Dictionary = bot.choose(game, player)
		var error: String = game.act(player.id, action)
		if error != "":
			bot.refused += 1
			bot.last_refusal = "%s -> %s" % [action, error]
			break
	game.end_turn(player.id)
	return decisions
