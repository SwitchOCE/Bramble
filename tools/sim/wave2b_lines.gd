extends "res://tools/sim/bench.gd"
## Native five-tribe lobbies, one engine and one tempo line plus six varied Hard opponents.
## Same bench CSVs/captures, plus pre-start and per-offer records in .line-metrics.jsonl.
## Example: -- suite=lines tribe=Oozes games=2 first_seed=280001 out=build/ooze-pilot capture=on
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

var _next_candidate: int = 0
var _line_metrics: FileAccess
var _seen_offers: Dictionary = {}
var _offered: Dictionary = {}
var _rows: Array[Dictionary] = []


func _initialize() -> void:
	_options["tribe"] = "Oozes"
	super._initialize()


func _play(suite: String, requested_seed: int) -> void:
	var started: int = Time.get_ticks_msec()
	var tribe: String = str(_options["tribe"])
	var config: GameConfig = GameConfig.full_game()
	for key: String in _overrides:
		assert(config._values.has(key), "unknown config key: " + key)
		config.set_value(key, _overrides[key])
	assert(config.get_string("pass3_preset") == "B", "this measurement is preset B")
	var game_seed: int = maxi(requested_seed, _next_candidate)
	var probe := GameSession.new()
	probe._library = _library
	probe._config = config
	var lobby: PackedStringArray = []
	while true:
		probe._seed = game_seed
		lobby = probe._draw_lobby_tribes()
		if lobby.has(tribe):
			break
		game_seed += 1
	_next_candidate = game_seed + 1
	var line_names: Array[String] = []
	for id: String in LinePolicies.profiles():
		if str(LinePolicies.profiles()[id]["tribe"]) == tribe:
			line_names.append(id)
	assert(line_names.size() == 2, "measurement needs exactly two lines for " + tribe)
	line_names.sort()
	var names: Array = [line_names[0], line_names[1]]
	for _seat: int in 6:
		names.append("hard:varied")
	var seating_rng := RandomNumberGenerator.new()
	seating_rng.seed = ("wave2b|%s|%d" % [tribe, game_seed]).hash()
	BenchSuites._shuffle(names, seating_rng)
	var seats: PackedStringArray = PackedStringArray(names)
	_current_seats = seats
	_game_seed = game_seed
	config.set_value("human_bot", seats[0])
	config.set_value("bots", Array(seats.slice(1)))
	_fights.clear()
	_acorns.clear()
	_acorn_gold.clear()
	_observed_players.clear()
	_starting_policies.clear()
	_seen_offers.clear()
	_offered.clear()
	_rows.clear()
	var session: GameSession = GameSession.create(
		game_seed, _library, config, BenchSuites.create_bot
	)
	_active_session = session
	assert(session._lobby_tribes == lobby and lobby.size() == 5)
	for player: PlayerState in session._players:
		_starting_policies[player.id] = session.build_of(player.id)
		_offered[player.id] = {}
		_observe_shop(player)
	session._rules.shop_observer = _observe_shop
	session.fight_observer = _on_fight
	session.fight_capture_observer = _capture_line
	session.combat_factory = CaptureCombat.instrument
	session.turn_observer = _on_turn.bind(suite, game_seed)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		session.end_turn()
		turns += 1
	assert(session.is_over(), "a line measurement must finish the game")
	_write_game(suite, game_seed, session, seats)
	if _line_metrics == null:
		_line_metrics = FileAccess.open(
			str(_options["out"]) + ".line-metrics.jsonl", FileAccess.WRITE
		)
	var shopping: Array[Dictionary] = []
	for player: PlayerState in session._players:
		(
			shopping
			. append(
				{
					"seat": player.id,
					"assigned_line": seats[player.id],
					"build": session.build_of(player.id),
					"offers_by_tribe": _offered[player.id],
					"buys_by_tribe": player.bought_by_tribe.duplicate(true),
				}
			)
		)
	var seconds: float = (Time.get_ticks_msec() - started) / 1000.0
	(
		_line_metrics
		. store_line(
			(
				JSON
				. stringify(
					{
						"seed": game_seed,
						"tribe": tribe,
						"lobby_tribes": Array(lobby),
						"seconds": seconds,
						"rates": Pass3Rates.resolved(config),
						"pre_start": _rows,
						"shopping": shopping,
						"rounds": turns,
						"counting":
						(
							"active pre-start Attack+Health excludes Bellies; "
							+ "including_bellies is separate for paper accounting"
						),
					},
					"",
					true,
					true
				)
			)
		)
	)
	_line_metrics.flush()
	for file: FileAccess in _files.values():
		file.flush()
	print(
		(
			"wave2b_lines: seed=%d tribe=%s seconds=%.3f projected_32_minutes=%.2f"
			% [game_seed, tribe, seconds, seconds * 32.0 / 60.0]
		)
	)
	_active_session = null


func _observe_shop(player: PlayerState) -> void:
	if not _offered.has(player.id):
		_offered[player.id] = {}
	var offered: Dictionary = _offered[player.id]
	for unit: RecruitUnit in player.shop:
		var key: String = "%d:%d" % [player.id, unit.iid]
		if _seen_offers.has(key):
			continue
		_seen_offers[key] = true
		var tribes: Array = unit.tribes()
		if tribes.is_empty():
			offered["neutral"] = CoreUtil.to_int(offered.get("neutral", 0)) + 1
		for tribe: String in tribes:
			offered[tribe] = CoreUtil.to_int(offered.get(tribe, 0)) + 1


func _capture_line(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	super._on_capture(input, result, combat)
	for side: int in 2:
		var seat: int = CoreUtil.to_int(input["player_ids"][side])
		if seat < 0:
			continue
		var snapshot: Dictionary = _capture["combat_start"][side]
		var total_inside: int = 0
		var cards: Array = []
		for unit: Dictionary in snapshot["units"]:
			if str(unit.get("location", "")) == "belly":
				total_inside += CoreUtil.to_int(unit["attack"]) + CoreUtil.to_int(unit["health"])
			elif CoreUtil.to_bool(unit.get("active", false)):
				cards.append(str(unit["def_id"]))
		var active: int = CoreUtil.to_int(snapshot["active_stats"])
		(
			_rows
			. append(
				{
					"round": input["round"],
					"seat": seat,
					"assigned_line": _current_seats[seat],
					"active_stats": active,
					"belly_stats": total_inside,
					"including_bellies": active + total_inside,
					"cards": cards,
					"largest_share": snapshot["largest_share"],
					"alive_before": _active_session._living().size(),
				}
			)
		)
