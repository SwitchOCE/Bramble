extends "res://tools/sim/bench.gd"
## Pinned spread on the actual five-tribe lobby. The original spread can pin a tribe that is
## absent, so its placement would mix strategy weakness with a build that cannot be bought.
## Gameplay stays unchanged; only eligible strategy seating is corrected.


func _play(suite: String, game_seed: int) -> void:
	var config: GameConfig = GameConfig.full_game()
	var lobby_probe := GameSession.new()
	lobby_probe._seed = game_seed
	lobby_probe._library = _library
	lobby_probe._config = config
	var lobby: PackedStringArray = lobby_probe._draw_lobby_tribes()
	var names: Array = []
	for entry: Dictionary in BotKnowledge.shared().open_strategies(Array(lobby)):
		names.append(str(entry["id"]))
	names.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%s|%d" % [suite, game_seed]).hash()
	BenchSuites._shuffle(names, rng)
	var seats: PackedStringArray = []
	for seat: int in BenchSuites.SEATS:
		seats.append("hard:%s" % names[seat % names.size()])
	var order: Array = Array(seats)
	BenchSuites._shuffle(order, rng)
	seats = PackedStringArray(order)
	_current_seats = seats
	config.set_value("human_bot", seats[0])
	config.set_value("bots", Array(seats.slice(1)))
	_fights.clear()
	_acorns.clear()
	_acorn_gold.clear()
	var session: GameSession = GameSession.create(game_seed, _library, config)
	assert(session._lobby_tribes == lobby, "Seating must match the real lobby draw")
	for player: PlayerState in session._players:
		var strategy: Dictionary = BotKnowledge.shared().strategy(session.build_of(player.id))
		assert(BotKnowledge.tribes_available(strategy, Array(lobby)))
	session.fight_observer = _on_fight
	session.turn_observer = _on_turn.bind(suite, game_seed)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		session.end_turn()
		turns += 1
	assert(session.is_over(), "A spread game must finish")
	_write_game(suite, game_seed, session, seats)
	for file: FileAccess in _files.values():
		file.flush()
	print("commit_spread: seed=%d lobby=%s seats=%s" % [game_seed, str(lobby), str(seats)])
