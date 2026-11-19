extends SceneTree
## Times whole games the way tools/checks/records.gd plays them (FlowBot on even seats,
## RandomBot on odd, streams Rng.derive(seed, "bot:%d" % seat), records written), without the
## replay check, for the Rust speed-up figure. -- games=<n> first_seed=<n> directory=<folder>


func _initialize() -> void:
	var opts: Dictionary = {"games": "10", "first_seed": "1", "directory": "res://build/league/time"}
	for arg: String in OS.get_cmdline_user_args():
		opts[arg.get_slice("=", 0)] = arg.substr(arg.get_slice("=", 0).length() + 1)
	GameRecord.directory = str(opts["directory"])
	var content: GameContent = GameContent.load_default()
	var games: int = str(opts["games"]).to_int()
	var first: int = str(opts["first_seed"]).to_int()
	var total_us: int = 0
	var rounds: int = 0
	for index: int in games:
		var game_seed: int = first + index
		var started: int = Time.get_ticks_usec()
		var game: GameSession = content.new_session(game_seed)
		game.keep_fight_events = false
		var bots: Array[Bot] = []
		for seat: int in game.players.size():
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
		total_us += Time.get_ticks_usec() - started
		rounds += game.round_number
	print(
		(
			"time_games games=%d rounds=%d us_per_game=%.0f"
			% [games, rounds, float(total_us) / maxi(1, games)]
		)
	)
	quit(0)
