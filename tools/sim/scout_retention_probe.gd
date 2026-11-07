extends SceneTree
## Current best bots, six-tribe lobbies. Args: games (6), first seed (75600).
## Counts each living seat's old scout identities against the opponent's pre-fight recruit board.

const Retention := preload("res://tools/sim/scout_retention.gd")
var _library: UnitLibrary
var _level: String = ""
var _totals: Dictionary = {}
var _rounds: Dictionary = {}
var _game: Dictionary = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var games: int = 6 if args.is_empty() else args[0].to_int()
	var first: int = 75600 if args.size() < 2 else args[1].to_int()
	_library = UnitLibrary.load_dir()
	var number: int = 0
	for level: String in ["hard"]:
		_level = level
		_totals[level] = _blank()
		for _index: int in games:
			_game = _blank()
			var game_seed: int = first + number
			number += 1
			var config: GameConfig = GameConfig.full_game()
			config.set_value("human_bot", level)
			var bots: Array[String] = []
			for _seat: int in 7:
				bots.append(level)
			config.set_value("bots", bots)
			var started: int = Time.get_ticks_msec()
			var session: GameSession = GameSession.create(game_seed, _library, config)
			session.fight_observer = _note_fight.bind(session)
			var turns: int = 0
			while not session.is_over() and turns < 60:
				session.end_turn()
				turns += 1
			if not session.is_over():
				push_error("Scout probe did not finish seed %d" % game_seed)
				quit(1)
				return
			session.fight_observer = Callable()
			print(
				(
					"scout_game: %s"
					% JSON.stringify(
						{
							"level": level,
							"seed": game_seed,
							"counts": _game,
							"ms": Time.get_ticks_msec() - started
						}
					)
				)
			)
		print("scout_level: %s" % JSON.stringify({"level": level, "counts": _totals[level]}))
	print("scout_rounds: %s" % JSON.stringify(_rounds))
	quit(0)


func _note_fight(
	round_number: int, a: int, b: int, _result: Dictionary, session: GameSession
) -> void:
	if b == Matchmaking.GHOST:
		return
	for pair: Array in [[a, b], [b, a]]:
		var player: PlayerState = session._players[CoreUtil.to_int(pair[0])]
		var opponent: PlayerState = session._players[CoreUtil.to_int(pair[1])]
		if player.scout.is_empty():
			continue
		var seen: Array = player.scout["views"]
		var comparison: Dictionary = Retention.compare(seen, opponent.fought_view, _library)
		var key: String = "%s:%d" % [_level, round_number]
		if not _rounds.has(key):
			_rounds[key] = _blank()
		for bucket: Dictionary in [_game, _totals[_level], _rounds[key]]:
			bucket["boards"] += 1
			bucket["exact"] += 1 if CoreUtil.to_bool(comparison["exact"]) else 0
			for group: String in ["all", "mirers", "top_attack"]:
				var dest: Dictionary = bucket[group]
				var source: Dictionary = comparison[group]
				for field: String in source:
					dest[field] += source[field]


func _blank() -> Dictionary:
	return {
		"boards": 0,
		"exact": 0,
		"all": {"units": 0, "same": 0, "moved": 0, "gone": 0},
		"mirers": {"units": 0, "same": 0, "moved": 0, "gone": 0},
		"top_attack": {"units": 0, "same": 0, "moved": 0, "gone": 0},
	}
