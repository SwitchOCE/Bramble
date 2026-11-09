extends SceneTree
## One shard of the bench: full games of one suite at fixed seeds. tools/sim/bench.sh runs shards
## and writes the report. Usage:
##   godot --headless -s res://tools/sim/bench.gd -- suite=spread games=10 first_seed=1 out=<prefix>
## Writes <prefix>.players.csv, .rounds.csv, .cards.csv, .turns.csv (see BenchSuites for suites).

const MAX_TURNS: int = 60

var _options: Dictionary = {
	"suite": "spread",
	"games": "10",
	"first_seed": "1",
	"out": "bench",
	"toll": "default",
	"candidate": "hard",
	"incumbent": "hard",
	"trace": "off",
	"profile": "off",
	"capture": "off",
	"lines": "",
	"plant_growth": "0",
	"plant_mode": "off",
	"plant_pool": "off",
	"config": ""
}
var _library: UnitLibrary
var _files: Dictionary = {}
var _fights: Dictionary = {}
var _acorns: Dictionary = {}
var _acorn_gold: Dictionary = {}
var _current_seats: PackedStringArray = []
var _leg: int = 0
var _observed_players: Dictionary = {}
var _starting_policies: Dictionary = {}
var _capture: Dictionary = {}
var _game_seed: int = 0
var _active_session: GameSession
var _test_card: Dictionary = {}
var _plant_spawned: bool = false
var _overrides: Dictionary = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() != 2 or not _options.has(parts[0]):
			printerr("bench: bad option %s" % arg)
			quit(2)
			return
		_options[parts[0]] = parts[1]
	if str(_options["lines"]) != "":
		BenchSuites.reload_lines(str(_options["lines"]))
	var suite: String = str(_options["suite"])
	if (
		not BenchSuites.is_candidate(str(_options["candidate"]), suite)
		or not BenchSuites.is_candidate(str(_options["incumbent"]), suite)
	):
		printerr("bench: unknown registry name")
		quit(2)
		return
	BotProfile.enabled = _options["profile"] == "on"
	if str(_options["config"]) != "":
		var parsed: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(str(_options["config"]))
		)
		assert(parsed is Dictionary, "config must be a JSON object of GameConfig overrides")
		_overrides = parsed
	_library = UnitLibrary.load_dir()
	var growth: int = str(_options["plant_growth"]).to_int()
	var mode: String = str(_options["plant_mode"])
	if mode == "off" and growth > 0:
		mode = "engine"
	if mode != "off":
		_test_card = PlantedEngine.install(
			_library, growth, mode, str(_options["plant_pool"]) == "on"
		)
	_open_files()
	if not BenchSuites.is_known(suite):
		printerr("bench: no suite %s" % suite)
		quit(2)
		return
	var first: int = str(_options["first_seed"]).to_int()
	var games: int = str(_options["games"]).to_int()
	var started: int = Time.get_ticks_msec()
	for game_seed: int in range(first, first + games):
		if suite == "head_to_head":
			for leg: int in 2:
				_play_leg(suite, game_seed, leg)
		else:
			_play(suite, game_seed)
	print(
		(
			"bench: %s %d games (%d seeds) in %.1f s"
			% [
				suite,
				games * (2 if suite == "head_to_head" else 1),
				games,
				(Time.get_ticks_msec() - started) / 1000.0
			]
		)
	)
	_files.clear()
	quit(0)


func _open_files() -> void:
	var prefix: String = str(_options["out"])
	var headers: Dictionary = {
		"players":
		(
			"suite,seed,seat,bot,level,strategy,focus,place,rounds,hero,offered,tier6_turn,"
			+ "bought_at_t6,final_units,final_attack,final_health,gold_spent,fights,acorns,"
			+ "acorn_gold,leg,side,candidate,incumbent,comparison,final_tribe,"
			+ "plurality_tribe,plurality_share,lobby_tribes,no_tribe_reason"
		),
		"rounds":
		(
			"suite,seed,seat,bot,strategy,round,tier,units,attack,health,bank,spent,paid_refreshes,"
			+ "larder,result,gold_left"
		),
		"cards": "suite,seed,seat,strategy,place,card,tier,golden",
		"turns": "suite,seed,seat,level,round,units,usec,leg",
		"profile":
		"suite,seed,leg,seat,round,eval,lanes,held,setup,fights,other,searches,sim_fights",
	}
	for key: String in headers:
		var file: FileAccess = FileAccess.open("%s.%s.csv" % [prefix, key], FileAccess.WRITE)
		file.store_line(str(headers[key]))
		_files[key] = file

	if _options["trace"] == "on":
		_files["trace"] = FileAccess.open(prefix + ".trace.jsonl", FileAccess.WRITE)
	if _options["trace"] == "on" or _options["capture"] == "on":
		_files["fight_trace"] = FileAccess.open(prefix + ".fights.jsonl", FileAccess.WRITE)


func _play(suite: String, game_seed: int) -> void:
	_play_leg(suite, game_seed, 0)


func _play_leg(suite: String, game_seed: int, leg: int) -> void:
	_leg = leg
	_game_seed = game_seed
	var seats: PackedStringArray = BenchSuites.seats(
		suite, game_seed, str(_options["candidate"]), str(_options["incumbent"]), leg
	)
	_current_seats = seats
	_observed_players.clear()
	_starting_policies.clear()
	var config: GameConfig = GameConfig.full_game()
	for key: String in _overrides:
		assert(config._values.has(key), "unknown GameConfig override: %s" % key)
		assert(key not in ["human_bot", "bots", "players"], "bench owns its eight-seat roster")
		config.set_value(key, _overrides[key])
	if str(_options["toll"]) == "off":
		config.set_value("round_toll", false)
	config.set_value("human_bot", seats[0])
	config.set_value("bots", Array(seats.slice(1)))
	_fights.clear()
	_acorns.clear()
	_acorn_gold.clear()
	var session: GameSession = GameSession.create(
		game_seed, _library, config, BenchSuites.create_bot
	)
	_active_session = session
	for id: int in BenchSuites.SEATS:
		_starting_policies[id] = session.build_of(id)
	_plant_spawned = false
	session.fight_observer = _on_fight
	if _files.has("fight_trace"):
		session.fight_capture_observer = _on_capture
		session.combat_factory = CaptureCombat.instrument
	session.turn_observer = _on_turn.bind(suite, game_seed)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		session.end_turn()
		turns += 1
	_write_game(suite, game_seed, session, seats)
	_active_session = null


func _on_capture(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	_capture = FightCapture.record(input, result, _active_session._library, combat)
	_capture.merge({"seed": _game_seed, "leg": _leg, "suite": _options["suite"]})
	_capture["alive_before"] = _active_session._living().size()
	_capture["test_cards"] = [] if _test_card.is_empty() else [_test_card]
	for side: int in 2:
		var id: int = CoreUtil.to_int(input["player_ids"][side])
		var snapshot: Dictionary = _capture["combat_start"][side]
		if id >= 0:
			if not _starting_policies.has(id):
				_starting_policies[id] = _active_session.build_of(id)
			var player: PlayerState = _observed_players[id]
			var units: Array = snapshot["units"]
			units.append_array(FightCapture.reserves(player, _active_session._library))
			snapshot["recruit_units"] = FightCapture.recruit_inventory(player)
			(
				snapshot
				. merge(
					{
						"gold_spent_turn": player.gold_spent_turn,
						"gold_spent_game": player.gold_spent_game,
						"health": player.health,
						"armor": player.armor,
						"last_stand_used": player.last_stand_used,
						"line": _active_session.build_of(id),
						"assigned_line": _current_seats[id].get_slice(":", 0),
						"starting_line": _starting_policies[id],
						"current_line": _active_session.build_of(id),
						"policy":
						(
							"hard"
							if _current_seats[id].begins_with("hard_field")
							else _active_session.build_of(id)
						),
					}
				)
			)
			if str(_options["suite"]) in ["lines", "wave1_accounting"]:
				snapshot["layout"] = "blind"
			if not _test_card.is_empty() and id == 0 and _options["plant_pool"] != "on":
				snapshot["policy"] = (
					"plant_null"
					if _test_card["id"] == "bench_null"
					else (
						"plant_reference"
						if _test_card["id"] == "bench_reference"
						else "plant_engine"
					)
				)


func _on_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	if _files.has("fight_trace"):
		var outcome: Dictionary = result.duplicate()
		outcome.erase("events")
		_capture.merge({"round": round_number, "players": [id_a, id_b], "outcome": outcome})
		var health: Array = []
		var armor: Array = []
		for seat: int in [id_a, id_b]:
			var player: PlayerState = _observed_players.get(seat)
			if player != null:
				health.append(player.health)
				armor.append(player.armor)
			else:
				health.append(null)
				armor.append(null)
		_capture["health_after"] = health
		_capture["armor_after"] = armor
		var trace: FileAccess = _files["fight_trace"]
		trace.store_line(JSON.stringify(_capture, "", true, true))
	_fights[id_a] = CoreUtil.to_int(_fights.get(id_a, 0)) + 1
	_fights[id_b] = CoreUtil.to_int(_fights.get(id_b, 0)) + 1
	var carried: Array[Dictionary] = result["carry"]
	for change: Dictionary in carried:
		if str(change.get("op", "")) != "add_card":
			continue
		var gold: int = BotEval.item_gold(_active_session._library.get_card(str(change["card"])))
		if gold <= 0:
			continue
		var side_id: int = id_a if CoreUtil.to_int(change["side"]) == 0 else id_b
		var count: int = CoreUtil.to_int(change["count"])
		_acorns[side_id] = CoreUtil.to_int(_acorns.get(side_id, 0)) + count
		_acorn_gold[side_id] = CoreUtil.to_int(_acorn_gold.get(side_id, 0)) + gold * count


func _on_turn(
	player: PlayerState, round_number: int, usec: int, suite: String, game_seed: int
) -> void:
	if player.id == 0 and round_number == 1 and not _plant_spawned:
		# Match null/reference bodies after identical recruitment, before End of Turn and combat.
		PlantedEngine.spawn(_active_session, _test_card)
		_plant_spawned = true
	_observed_players[player.id] = player
	if _options["trace"] == "on":
		var trace: FileAccess = _files["trace"]
		trace.store_line(
			JSON.stringify(
				{
					"seed": game_seed,
					"leg": _leg,
					"seat": player.id,
					"round": round_number,
					"board": player.board_specs(),
					"slots": player.combat_slots(),
					"gold": player.gold,
					"tier": player.tier,
					"rng": str(player.bot_rng.state)
				}
			)
		)
	if BotProfile.enabled:
		var profile: FileAccess = _files["profile"]
		var fields: Array = [suite, game_seed, _leg, player.id, round_number]
		for key: String in ["eval", "lanes", "held", "setup", "fights"]:
			fields.append(BotProfile.totals.get(key, 0))
		fields.append(usec - BotProfile.measured())
		fields.append(BotProfile.counts.get("setup", 0))
		fields.append(BotProfile.counts.get("fights", 0))
		profile.store_csv_line(
			PackedStringArray(fields.map(func(v: Variant) -> String: return str(v)))
		)
		BotProfile.totals.clear()
		BotProfile.counts.clear()
	var file: FileAccess = _files["turns"]
	(
		file
		. store_line(
			(
				"%s,%d,%d,%s,%d,%d,%d,%d"
				% [
					suite,
					game_seed,
					player.id,
					_level_of(_current_seats[player.id]),
					round_number,
					player.board_count(),
					usec,
					_leg,
				]
			)
		)
	)


func _write_game(
	suite: String, game_seed: int, session: GameSession, seats: PackedStringArray
) -> void:
	var game_log: Dictionary = session.get_game_log()
	var rows: Array = game_log["players"]
	var focus_seat: int = BenchSuites.focus_seat(suite, game_seed)
	for value: Variant in rows:
		var row: Dictionary = value
		var seat: int = row["player_id"]
		_write_player(suite, game_seed, row, seat, seats[seat], seat == focus_seat, session)


func _write_player(
	suite: String,
	game_seed: int,
	row: Dictionary,
	seat: int,
	bot: String,
	focus: bool,
	session: GameSession
) -> void:
	var strategy: String = session.build_of(seat)
	var final_player: PlayerState = _observed_players[seat]
	var rounds: Array = row["rounds"]
	var tier6: int = 0
	var bought_at: int = 0
	var last: Dictionary = {}
	for value: Variant in rounds:
		var round_row: Dictionary = value
		last = round_row
		if tier6 == 0 and CoreUtil.to_int(round_row["tier"]) >= UnitLibrary.TIERS:
			tier6 = round_row["round"]
			bought_at = round_row["units_bought"]
		_write_round(suite, game_seed, seat, bot, strategy, round_row)
	var final_stats: Array[int] = _board_stats(last.get("board", []))
	var place: int = CoreUtil.to_int(row["placement"])
	if place == 0:
		place = session.get_standings().size()
	var offered: String = "+".join(session.hero_offer_of(seat))
	var lobby_tribes: Array = session.get_state()["lobby_tribes"]
	var label: Dictionary = BenchTribes.classify(final_player.fought_specs, _library)
	var file: FileAccess = _files["players"]
	(
		file
		. store_line(
			(
				"%s,%d,%d,%s,%s,%s,%d,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%s,%s,%s,%s,%s,%.6f,%s,%s"
				% [
					suite,
					game_seed,
					seat,
					bot.replace(",", ";"),
					_level_of(bot),
					strategy,
					1 if focus else 0,
					place,
					rounds.size(),
					row["hero"],
					offered,
					tier6,
					bought_at,
					final_stats[0],
					final_stats[1],
					final_stats[2],
					row["gold_spent"],
					_fights.get(seat, 0),
					_acorns.get(seat, 0),
					_acorn_gold.get(seat, 0),
					_leg,
					(
						(
							"candidate"
							if BenchSuites.candidate_seats(game_seed, _leg).has(seat)
							else "incumbent"
						)
						if suite == "head_to_head"
						else ""
					),
					_options["candidate"] if suite == "head_to_head" else "",
					_options["incumbent"] if suite == "head_to_head" else "",
					(
						BenchSuites.comparison_kind(
							str(_options["candidate"]), str(_options["incumbent"])
						)
						if suite == "head_to_head"
						else ""
					),
					label["final_tribe"],
					label["plurality_tribe"],
					label["plurality_share"],
					"+".join(PackedStringArray(lobby_tribes)),
					label["no_tribe_reason"],
				]
			)
		)
	)
	_write_cards(suite, game_seed, seat, strategy, place, last.get("board", []))


func _write_round(
	suite: String, game_seed: int, seat: int, bot: String, strategy: String, row: Dictionary
) -> void:
	var stats: Array[int] = _board_stats(row["board"])
	var larder: int = 0
	var items: Array = row["items"]
	for item: Variant in items:
		larder += BotEval.item_gold(_library.get_card(str(item)))
	var file: FileAccess = _files["rounds"]
	(
		file
		. store_line(
			(
				"%s,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%d"
				% [
					suite,
					game_seed,
					seat,
					bot,
					strategy,
					row["round"],
					row["tier"],
					stats[0],
					stats[1],
					stats[2],
					row["gold_at_start"],
					row["gold_spent"],
					row["paid_refreshes"],
					larder,
					row["result"],
					row["gold_left"],
				]
			)
		)
	)


func _write_cards(
	suite: String, game_seed: int, seat: int, strategy: String, place: int, board_value: Variant
) -> void:
	var board: Array = board_value
	var file: FileAccess = _files["cards"]
	for entry: Variant in board:
		if entry == null:
			continue
		var unit: Dictionary = entry
		var unit_def: Dictionary = _library.get_unit(str(unit["def_id"]))
		(
			file
			. store_line(
				(
					"%s,%d,%d,%s,%d,%s,%d,%d"
					% [
						suite,
						game_seed,
						seat,
						strategy,
						place,
						unit["def_id"],
						unit_def.get("tier", 0),
						1 if unit["golden"] else 0,
					]
				)
			)
		)


## [units, attack, health].
static func _board_stats(board_value: Variant) -> Array[int]:
	var board: Array = board_value
	var out: Array[int] = [0, 0, 0]
	for entry: Variant in board:
		if entry != null:
			var unit: Dictionary = entry
			out[0] += 1
			out[1] += CoreUtil.to_int(unit["attack"])
			out[2] += CoreUtil.to_int(unit["health"])
	return out


static func _level_of(bot: String) -> String:
	if bot.contains("=") and BenchSuites.is_big_search(bot):
		return "search200"
	return bot.get_slice("@", 0).get_slice(":", 0)
