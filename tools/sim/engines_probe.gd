extends SceneTree
## Full-strength bot data for the adopted lean engines arm, not evidence of human balance.
## godot --headless -s res://tools/sim/engines_probe.gd -- games=200 first_seed=50000
## Health rank at the first <=4-alive round follows the design's competition-rank convention:
## ties take the highest matching rank; a comeback means the winner's rank was at least third.

var _last_stands: int = 0
var _early_stands: int = 0
var _last_blows: int = 0
var _session: GameSession


func _initialize() -> void:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=")
		if parts.size() == 2:
			args[parts[0]] = parts[1]
	var first: int = str(args.get("first_seed", "50000")).to_int()
	var games: int = str(args.get("games", "200")).to_int()
	var library := UnitLibrary.load_dir()
	for game: int in games:
		var config := GameConfig.full_game()
		config.set_value("human_bot", BotLevel.HARD)
		_session = GameSession.create(first + game, library, config)
		_session.fight_observer = _fight
		_last_stands = 0
		_early_stands = 0
		_last_blows = 0
		print("eng_start: %d" % (first + game))
		var rounds: int = 0
		var first_four_round: int = 0
		var last_four_rounds: int = 0
		var health_at_four: Dictionary = {}
		while not _session.is_over() and rounds < 60:
			var alive: Array[PlayerState] = _session._living()
			if alive.size() <= 4:
				last_four_rounds += 1
				if first_four_round == 0:
					first_four_round = _session._round
					for player: PlayerState in alive:
						health_at_four[player.id] = player.health
			_session.end_turn()
			rounds += 1
		var winner: int = -1
		for player: PlayerState in _session._players:
			if player.placement == 1:
				winner = player.id
		if not _session.is_over() or winner < 0 or _early_stands > 0:
			printerr(
				"engines_probe: incomplete game or early Last Stand at seed %d" % (first + game)
			)
			quit(1)
			return
		var rank: int = 0
		if health_at_four.has(winner):
			var healths: Array = health_at_four.values()
			healths.sort()
			healths.reverse()
			rank = healths.find(health_at_four[winner]) + 1
		print(
			(
				"eng_game: %s"
				% JSON.stringify(
					{
						"evidence": "bot data",
						"arm": "lean",
						"seed": first + game,
						"rounds": rounds,
						"first_four_round": first_four_round,
						"last_four_rounds": last_four_rounds,
						"health_at_four": health_at_four,
						"winner": winner,
						"winner_rank_at_four": rank,
						"comeback_eligible": rank > 0,
						"comeback": rank >= 3,
						"last_stands": _last_stands,
						"early_last_stands": _early_stands,
						"last_blows": _last_blows
					}
				)
			)
		)
	quit(0)


func _fight(_round_now: int, _pid_a: int, _pid_b: int, result: Dictionary) -> void:
	var saves: Array = result.get("last_stand_sides", [])
	_last_stands += saves.size()
	if _session._living().size() > 4:
		_early_stands += saves.size()
	if CoreUtil.to_bool(result.get("last_blow", false)):
		_last_blows += 1
