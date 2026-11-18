extends SceneTree
## Reference records for TribeBot: records.gd's game loop with the balance pass's lobby, seat
## `id` playing TribeBot of `TRIBES[(id + seed) % 5]` with stream `Rng.derive(seed, "bot:%d")`.
## `league selfcheck --bots tribe --records <directory>` compares the Rust port with them.
## godot --headless -s res://tools/league/gd/tribe_records.gd -- games=200 first_seed=1
##   directory=/absolute/folder

const TribeBot := preload("res://tools/league/gd/tribe_bot.gd")
const TRIBES: Array[String] = ["Badger", "Mouse", "Pigeon", "Locust", "Briar"]


func _initialize() -> void:
	var options: Dictionary = {"games": "50", "first_seed": "1", "directory": "res://build/records"}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		if not options.has(key) or not arg.contains("="):
			printerr("tribe_records: unknown argument %s" % arg)
			quit(2)
			return
		options[key] = arg.substr(key.length() + 1)
	GameRecord.directory = str(options["directory"])
	var games: int = str(options["games"]).to_int()
	var first: int = str(options["first_seed"]).to_int()
	var content: GameContent = GameContent.load_default()
	for index: int in games:
		var game_seed: int = first + index
		var game: GameSession = content.new_session(game_seed)
		game.keep_fight_events = false
		var bots: Array[Bot] = []
		for seat: int in game.players.size():
			var tribe: String = TRIBES[(seat + game_seed) % TRIBES.size()]
			bots.append(TribeBot.new(Rng.derive(game_seed, "bot:%d" % seat), tribe))
		while not game.over:
			game.start_round()
			for player: PlayerState in game.alive_players():
				bots[player.id].take_turn(game, player.id)
			game.finish_round()
			game.events.clear()
			game.fights.clear()
		for bot: Bot in bots:
			if bot.refused != 0:
				printerr("tribe_records: seed %d bot refused %s" % [game_seed, bot.last_refusal])
				quit(1)
				return
		print(
			(
				"tribe_records: seed %d, %d turns, %s"
				% [game_seed, game.round_number, game.record.path]
			)
		)
	quit(0)
