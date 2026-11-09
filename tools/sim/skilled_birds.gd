extends SceneTree
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_cast")
## Separate from wave1_baseline. -- probe|run PLAN.json OUTPUT.json|jsonl

const Brain := preload("res://tools/sim/skilled_birds_brain.gd")
var _session: GameSession
var _stream: FileAccess
var _seed: int
var _names: PackedStringArray
var _arm: String = "control"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3 or args[0] not in ["probe", "run"]:
		printerr("expected probe|run PLAN OUTPUT")
		quit(2)
		return
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	var config := GameConfig.full_game()
	assert(config.get_int("tribes_per_lobby") == 5)
	assert(config.get_bool("card_size_caps") and config.get_bool("card_rate_limits"))
	assert(Pass3Rates.number(config, "birds_homecoming_multiplier") == 2.0)
	assert(Pass3Rates.number(config, "birds_golden_homecoming_multiplier") == 2.0)
	var library := UnitLibrary.load_dir()
	_stream = FileAccess.open(args[2], FileAccess.WRITE)
	if args[0] == "probe":
		_probe(plan, library, config)
		_stream.close()
		quit(0)
		return
	_arm = str(plan["arm"])
	assert(_arm in ["control", "aggressive"])
	var started: int = Time.get_ticks_msec()
	for candidate: Variant in plan["seeds"]:
		_seed = CoreUtil.to_int(candidate)
		_names = _seats(_seed)
		config = GameConfig.full_game()
		config.set_value("human_bot", _names[0])
		config.set_value("bots", Array(_names.slice(1)))
		_session = GameSession.create(_seed, library, config, _create_bot)
		assert(_session._lobby_tribes.size() == 5)
		assert(_session._lobby_tribes.has("Birds") and _session._lobby_tribes.has("Fairies"))
		_session.fight_capture_observer = _capture
		_session.fight_observer = _outcome
		_session.turn_observer = _turn
		_session.combat_factory = CaptureCombat.instrument
		while not _session.is_over():
			var problem: String = _session.end_turn()
			assert(problem == "", problem)
		var final_lines: Array[String] = []
		for seat: int in 8:
			final_lines.append(_session.build_of(seat))
		_write(
			{
				"type": "lobby",
				"tribes": Array(_session._lobby_tribes),
				"starting_lines": Array(_names),
				"final_lines": final_lines,
				"summary": _session.get_game_log(),
				"config": config._values,
				"rates": Pass3Rates.resolved(config),
			}
		)
		_stream.flush()
	_stream.close()
	_session = null
	print(
		(
			"skilled_birds %s: %d lobbies in %.3f s"
			% [_arm, plan["seeds"].size(), (Time.get_ticks_msec() - started) / 1000.0]
		)
	)
	quit(0)


func _probe(plan: Dictionary, library: UnitLibrary, config: GameConfig) -> void:
	var eligible: Array[int] = []
	var excluded: Array[int] = []
	var tribes: Dictionary = {}
	for candidate: Variant in plan["seeds"]:
		var game_seed: int = CoreUtil.to_int(candidate)
		var probe := GameSession.new()
		probe._seed = game_seed
		probe._config = config
		probe._library = ScaleOverlay.library_for(library, config)
		var drawn: PackedStringArray = probe._draw_lobby_tribes()
		tribes[str(game_seed)] = Array(drawn)
		if drawn.has("Birds") and drawn.has("Fairies"):
			eligible.append(game_seed)
		else:
			excluded.append(game_seed)
	(
		_stream
		. store_line(
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
					"",
					true,
					true
				)
			)
		)
	)


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


func _create_bot(bot_name: String) -> Bot:
	var alias: String = bot_name.get_slice(":", 0).get_slice("@", 0)
	if alias not in ["line_birds_homecoming", "line_birds_tempo"]:
		return BenchSuites.create_bot(bot_name)
	var brain: Brain = BotBrain.from_name("hard@blind", Brain) as Brain
	brain.configure_line(alias)
	brain.aggressive_flight = _arm == "aggressive"
	return brain


func _turn(player: PlayerState, number: int, _microseconds: int) -> void:
	var brain: Brain = _session._bots[player.id] as Brain
	if brain == null or number > 16:
		return
	var inventory: Array = []
	for unit: RecruitUnit in player.all_units():
		(
			inventory
			. append(
				{
					"iid": unit.iid,
					"def_id": unit.def_id(),
					"attack": unit.attack,
					"health": unit.health,
					"golden": unit.golden,
					"played_round": unit.played_round,
					"home_round": unit.counters.get("pass3_home_round", -1),
				}
			)
		)
	_write(
		{
			"type": "flight_turn",
			"seat": player.id,
			"round": number,
			"starting_line": _names[player.id],
			"current_line": _session.build_of(player.id),
			"health": player.health,
			"hero": player.hero.get("id", ""),
			"homecomings": player.homecomings_this_turn,
			"decisions": (brain as Brain).flight_log,
			"inventory": inventory,
		}
	)


func _capture(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	var number: int = CoreUtil.to_int(input["round"])
	if number > 16:
		return
	var capture: Dictionary = FightCapture.record(input, result, _session._library, combat)
	capture["type"] = "fight"
	for side: int in 2:
		var seat: int = CoreUtil.to_int(input["player_ids"][side])
		if seat < 0:
			continue
		var snapshot: Dictionary = capture["combat_start"][side]
		snapshot["starting_line"] = _names[seat].get_slice(":", 0)
		snapshot["current_line"] = _session.build_of(seat)
		var player: PlayerState = _session._players[seat]
		snapshot["health_before_fight"] = player.health
		snapshot["hero"] = player.hero.get("id", "")
		snapshot["units"].append_array(FightCapture.reserves(player, _session._library))
	_write(capture)


func _outcome(number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	if number > 16:
		return
	var health: Array[int] = []
	for id: int in [id_a, id_b]:
		health.append(_session._players[id].health if id >= 0 else 0)
	_write(
		{
			"type": "outcome",
			"round": number,
			"player_ids": [id_a, id_b],
			"winner": result["winner"],
			"damage": result["damage"],
			"health_after_fight": health,
			"last_stand_sides": result.get("last_stand_sides", []),
		}
	)


func _write(record: Dictionary) -> void:
	record["seed"] = _seed
	record["arm"] = _arm
	_stream.store_line(JSON.stringify(record, "", true, true))
