extends SceneTree
## Paired damage experiment. Raw JSONL retains every round and charged fight component.

const SCHEDULES: Dictionary = {
	"A": [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 9, 10],
	"B": [0, 0, 0, 1, 1, 2, 2, 3, 4, 5, 7, 9, 11, 13],
	"C": [0, 0, 0, 0, 1, 1, 2, 2, 3, 4, 6, 8, 10, 12],
	"D": [1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 6, 6, 8, 8, 10],
	"E": [0, 0, 0, 1, 1, 2, 2, 3, 4, 5, 7, 9, 11, 13],
}
const SUITE: String = "hard_lobby_hard"
var _arm: String = "baseline"
var _session: GameSession
var _fights: Array[Dictionary] = []
var _before: Dictionary = {}
var _config: GameConfig


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 4 or (args[0] != "baseline" and not SCHEDULES.has(args[0])):
		printerr("damage: expected arm first_seed games out.jsonl")
		quit(2)
		return
	_arm = args[0]
	var first: int = args[1].to_int()
	var games: int = args[2].to_int()
	var file: FileAccess = FileAccess.open(args[3], FileAccess.WRITE)
	if file == null:
		printerr("damage: cannot open output")
		quit(2)
		return
	var library: UnitLibrary = UnitLibrary.load_dir()
	for game_seed: int in range(first, first + games):
		_config = GameConfig.full_game()
		# Pin baseline tunables even after the selected schedule becomes the game default.
		_config.set_value("damage_cap_by_turn", [4, 4, 5, 6, 7, 8, 9, 10, 11, 12])
		_config.set_value("damage_cap_off_at_alive", 4)
		_config.set_value("hero_damage_floor", 4)
		_config.set_value("round_toll", true)
		_config.set_value("survivor_damage_divisor", 2)
		_config.set_value("last_stand", true)
		_config.set_value("last_blow", true)
		_config.set_value("damage_mode", "legacy" if _arm == "baseline" else "v05")
		if _arm != "baseline":
			_config.set_value("base_damage_by_turn", SCHEDULES[_arm])
		_config.set_value("starting_health", 48 if _arm == "E" else 40)
		var seats: PackedStringArray = BenchSuites.seats(SUITE, game_seed)
		_config.set_value("human_bot", seats[0])
		_config.set_value("bots", Array(seats.slice(1)))
		_fights.clear()
		_before.clear()
		_session = GameSession.create(game_seed, library, _config, BenchSuites.create_bot)
		_session.fight_observer = _on_fight
		_session.turn_observer = _on_turn
		var turns: int = 0
		while not _session.is_over() and turns < 60:
			var error: String = _session.end_turn()
			if error != "":
				printerr("damage: seed %d: %s" % [game_seed, error])
				quit(1)
				return
			turns += 1
		var complete: bool = _session.is_over() and _session._living().size() <= 1
		var game: Dictionary = _session.get_game_log()
		var players: Array = []
		for value: Variant in game["players"]:
			var player: Dictionary = value
			var rounds: Array = []
			for row_value: Variant in player["rounds"]:
				var row: Dictionary = row_value
				rounds.append(
					{
						"round": row["round"],
						"health": row["health"],
						"armor": row["armor"],
						"result": row["result"]
					}
				)
			players.append(
				{
					"seat": player["player_id"],
					"place": player["placement"],
					"alive": _session._players[CoreUtil.to_int(player["player_id"])].alive,
					"hero": player["hero"],
					"rounds": rounds
				}
			)
		file.store_line(
			JSON.stringify(
				{
					"arm": _arm,
					"seed": game_seed,
					"complete": complete,
					"suite": SUITE,
					"seats": Array(seats),
					"rounds": game["rounds"],
					"starting_health": _config.get_int("starting_health"),
					"base_schedule": [] if _arm == "baseline" else SCHEDULES[_arm],
					"players": players,
					"fights": _fights
				}
			)
		)
		file.flush()
		print("damage: %s seed %d complete=%s rounds=%d" % [_arm, game_seed, complete, turns])
		if not complete:
			printerr("damage: unfinished game")
			quit(1)
			return
	_session = null
	quit(0)


func _on_turn(player: PlayerState, _round_number: int, _usec: int) -> void:
	_before[player.id] = {"health": player.health, "armor": player.armor}


func _on_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	var winner: int = CoreUtil.to_int(result["winner"])
	var damage: int = CoreUtil.to_int(result["damage"])
	var performance: int = CoreUtil.to_int(result.get("damage_performance", 0))
	if _arm == "baseline":
		var tier: int = 0
		if winner >= 0:
			var winning_id: int = id_a if winner == 0 else id_b
			tier = _session._ghost_tier if winning_id < 0 else _session._players[winning_id].tier
		var toll: int = maxi(1, round_number - 7)
		var base: int = maxi(_config.get_int("hero_damage_floor"), tier) if winner >= 0 else 0
		performance = maxi(0, damage - base - toll)
		if CoreUtil.to_bool(result.get("last_blow", false)):
			performance = 0
	var charges: Array = []
	for side: int in 2:
		var seat: int = id_a if side == 0 else id_b
		if seat < 0 or winner == side:
			continue
		var player: PlayerState = _session._players[seat]
		var before: Dictionary = _before[seat]
		var available: int = (
			maxi(0, CoreUtil.to_int(before["health"])) + CoreUtil.to_int(before["armor"])
		)
		var actual: int = mini(damage, available)
		var saved: Array = result.get("last_stand_sides", [])
		if saved.has(side):
			actual = maxi(0, available - 1)
		charges.append(
			{
				"seat": seat,
				"damage": damage,
				"performance": performance,
				"base": damage - performance,
				"effective": actual,
				"health_before": before["health"],
				"armor_before": before["armor"],
				"health_after": player.health,
				"armor_after": player.armor
			}
		)
	_fights.append(
		{
			"round": round_number,
			"players": [id_a, id_b],
			"winner": winner,
			"last_blow": result.get("last_blow", false),
			"last_stand_sides": result.get("last_stand_sides", []),
			"charges": charges
		}
	)
