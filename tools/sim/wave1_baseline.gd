extends SceneTree
@warning_ignore_start("unsafe_method_access", "unsafe_call_argument", "unsafe_cast")
## -- probe|run PLAN.json OUTPUT.json|jsonl. Godot is always externally locked and bounded.

const LINES: Array[String] = [
	"line_birds_homecoming", "line_birds_tempo", "line_fairies_ring", "line_fairies_court"
]
var _session: GameSession
var _stream: FileAccess
var _seed: int
var _names: PackedStringArray


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3 or args[0] not in ["probe", "run"]:
		printerr("expected probe|run PLAN OUTPUT")
		quit(2)
		return
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	var config: GameConfig = _config(plan)
	var library := UnitLibrary.load_dir()
	if args[0] == "probe":
		var eligible: Array[int] = []
		var excluded: Array[int] = []
		var tribes: Dictionary = {}
		for candidate: Variant in plan["seeds"]:
			var game_seed: int = CoreUtil.to_int(candidate)
			var drawn: PackedStringArray = _tribes(game_seed, library, config)
			tribes[str(game_seed)] = Array(drawn)
			if drawn.has("Birds") and drawn.has("Fairies"):
				eligible.append(game_seed)
			else:
				excluded.append(game_seed)
		var output := FileAccess.open(args[2], FileAccess.WRITE)
		(
			output
			. store_string(
				(
					(
						JSON
						. stringify(
							{
								"eligible_seeds": eligible,
								"excluded_seeds": excluded,
								"tribes": tribes,
								"config": config._values,
								"rates": Pass3Rates.resolved(config),
							},
							"  "
						)
					)
					+ "\n"
				)
			)
		)
		output.close()
		quit(0)
		return
	_stream = FileAccess.open(args[2], FileAccess.WRITE)
	var started: int = Time.get_ticks_msec()
	for candidate: Variant in plan["seeds"]:
		_seed = CoreUtil.to_int(candidate)
		_names = _seats(_seed)
		config = _config(plan)
		config.set_value("human_bot", _names[0])
		config.set_value("bots", Array(_names.slice(1)))
		_session = GameSession.create(_seed, library, config, BenchSuites.create_bot)
		assert(_session._lobby_tribes.size() == 5)
		assert(_session._lobby_tribes.has("Birds") and _session._lobby_tribes.has("Fairies"))
		_session.fight_capture_observer = _capture
		_session.combat_factory = CaptureCombat.instrument
		while not _session.is_over():
			_session.end_turn()
		var players: Array = []
		for row: Dictionary in _session.get_game_log()["players"]:
			players.append(
				{
					"seat": row["player_id"],
					"place": row["placement"],
					"rounds": row["rounds"].size()
				}
			)
		var final_lines: Array[String] = []
		for seat: int in 8:
			final_lines.append(_session.build_of(seat))
		(
			_stream
			. store_line(
				(
					JSON
					. stringify(
						{
							"type": "lobby",
							"seed": _seed,
							"tribes": Array(_session._lobby_tribes),
							"starting_lines": Array(_names),
							"final_lines": final_lines,
							"players": players,
						},
						"",
						true,
						true
					)
				)
			)
		)
		_stream.flush()
	_stream.close()
	_session = null
	print(
		(
			"wave1_baseline: %d lobbies in %.3f s"
			% [plan["seeds"].size(), (Time.get_ticks_msec() - started) / 1000.0]
		)
	)
	quit(0)


static func _config(plan: Dictionary) -> GameConfig:
	var config := GameConfig.full_game()
	for key: String in plan.get("overrides", {}):
		assert(
			config._values.has(key) or Pass3Rates.defaults().has(key), "unknown preset key: " + key
		)
		assert(key not in ["human_bot", "bots", "players", "tribes_per_lobby"])
		config.set_value(key, plan["overrides"][key])
	assert(config.get_int("tribes_per_lobby") == 5)
	return config


static func _tribes(game_seed: int, library: UnitLibrary, config: GameConfig) -> PackedStringArray:
	var probe := GameSession.new()
	probe._seed = game_seed
	probe._config = config
	probe._library = ScaleOverlay.library_for(library, config)
	return probe._draw_lobby_tribes()


static func _seats(game_seed: int) -> PackedStringArray:
	var names: Array = [
		"line_birds_homecoming",
		"line_birds_tempo",
		"line_fairies_ring",
		"line_fairies_court",
		"hard_field:varied",
		"hard_field:varied",
		"hard_field:varied",
		"hard_field:varied"
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = ("wave1_accounting|%d" % game_seed).hash()
	for index: int in range(names.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		var saved: Variant = names[index]
		names[index] = names[other]
		names[other] = saved
	return PackedStringArray(names)


func _capture(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	var number: int = CoreUtil.to_int(input["round"])
	if number < 8 or number > 14:
		return
	var capture: Dictionary = FightCapture.record(input, result, _session._library, combat)
	capture["type"] = "fight"
	capture["seed"] = _seed
	for side: int in 2:
		var seat: int = CoreUtil.to_int(input["player_ids"][side])
		if seat < 0:
			continue
		var starting: String = _names[seat].get_slice(":", 0)
		var current: String = _session.build_of(seat)
		assert(
			(
				starting not in LINES
				or current == starting
				or (
					starting == "line_birds_tempo"
					and number >= 7
					and current == "line_birds_homecoming"
				)
			)
		)
		var snapshot: Dictionary = capture["combat_start"][side]
		snapshot.merge({"starting_line": starting, "current_line": current, "layout": "blind"})
	_stream.store_line(JSON.stringify(capture, "", true, true))
