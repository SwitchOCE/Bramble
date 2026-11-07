extends SceneTree
## Small reproducible balance probe: label, games, first seed. Raw JSON lives in build/round3.
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument")

var _library: UnitLibrary
var _damage: Dictionary = {}
var _largest: Dictionary = {}
var _places: Dictionary = {"tempo": [], "economy": [], "climb": []}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var label: String = args[0] if args.size() > 0 else "probe"
	var games: int = args[1].to_int() if args.size() > 1 else 12
	var first: int = args[2].to_int() if args.size() > 2 else 41
	_library = UnitLibrary.load_dir()
	var started: int = Time.get_ticks_msec()
	var shops: Array = _shops()
	for game_seed: int in range(first, first + games):
		var config: GameConfig = GameConfig.full_game()
		config.set_value("human_bot", "hard")
		config.set_value("bots", ["hard", "hard", "hard", "hard", "hard", "hard", "hard"])
		var session: GameSession = GameSession.create(game_seed, _library, config)
		for seat: int in 8:
			var brain: BotBrain = session._bots[seat]
			brain._opening_plan = BotBrain.OPENINGS[(seat + game_seed) % 3]
		session.fight_observer = _fight
		while not session.is_over() and session._round < 60:
			session.end_turn()
		for value: Variant in session.get_game_log()["players"]:
			var player: Dictionary = value
			var seat: int = CoreUtil.to_int(player["player_id"])
			var plan: String = BotBrain.OPENINGS[(seat + game_seed) % 3]
			var places: Array = _places[plan]
			places.append(player["placement"])
			for entry: Variant in player["rounds"]:
				var row: Dictionary = entry
				var best: Dictionary = {"attack": 0, "health": 0, "name": ""}
				for unit: Variant in row["board"]:
					if (
						unit != null
						and unit["attack"] + unit["health"] > best["attack"] + best["health"]
					):
						best = unit
				var round_id: String = str(row["round"])
				var units: Array = _largest.get(round_id, [])
				units.append(
					{"attack": best["attack"], "health": best["health"], "name": best["name"]}
				)
				_largest[round_id] = units
		print("round3: %s seed %d complete" % [label, game_seed])
	var data: Dictionary = {
		"label": label,
		"games": games,
		"first_seed": first,
		"seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"shops": shops,
		"damage": _damage,
		"largest": _largest,
		"places": _places
	}
	var file: FileAccess = FileAccess.open("build/round3/%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("round3: %s done in %.1fs" % [label, data["seconds"]])
	quit()


func _fight(round_number: int, _a: int, _b: int, result: Dictionary) -> void:
	var rows: Array = _damage.get(str(round_number), [])
	rows.append(result["damage"])
	_damage[str(round_number)] = rows


func _shops() -> Array:
	var config: GameConfig = GameConfig.full_game()
	var pool: UnitPool = UnitPool.create(_library, config)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var rows: Array = []
	for tier: int in range(1, 7):
		var counts: Array = [0, 0, 0, 0, 0, 0]
		var empty_top: int = 0
		for _shop: int in 10000:
			var drawn: PackedStringArray = []
			var top: bool = false
			for _slot: int in config.get_int_at("shop_units_by_tier", tier - 1):
				var id: String = pool.draw_by_odds(GameConfig.SLICE_SHOP_ODDS[tier - 1], tier, rng)
				if id == "":
					continue
				drawn.append(id)
				var card_tier: int = pool.tier_of(id)
				counts[card_tier - 1] += 1
				top = top or card_tier == tier
			for id: String in drawn:
				pool.give_back(id, 1)
			empty_top += 0 if top else 1
		rows.append({"tier": tier, "counts": counts, "no_top": empty_top, "shops": 10000})
	return rows
