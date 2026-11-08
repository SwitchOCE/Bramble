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
	"profile": "off"
}
var _library: UnitLibrary
var _files: Dictionary = {}
var _fights: Dictionary = {}
var _acorns: Dictionary = {}
var _acorn_gold: Dictionary = {}
var _current_seats: PackedStringArray = []
var _leg: int = 0
var _observed_players: Dictionary = {}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() != 2 or not _options.has(parts[0]):
			printerr("bench: bad option %s" % arg)
			quit(2)
			return
		_options[parts[0]] = parts[1]
	if (
		not BenchSuites.REGISTRY.has(_options["candidate"])
		or not BenchSuites.REGISTRY.has(_options["incumbent"])
	):
		printerr("bench: unknown registry name")
		quit(2)
		return
	BotProfile.enabled = _options["profile"] == "on"
	_library = UnitLibrary.load_dir()
	_open_files()
	var suite: String = str(_options["suite"])
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
			+ "acorn_gold,leg,side,candidate,incumbent,comparison,final_tribe"
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
		_files["fight_trace"] = FileAccess.open(prefix + ".fights.jsonl", FileAccess.WRITE)


func _play(suite: String, game_seed: int) -> void:
	_play_leg(suite, game_seed, 0)


func _play_leg(suite: String, game_seed: int, leg: int) -> void:
	_leg = leg
	var seats: PackedStringArray = BenchSuites.seats(
		suite, game_seed, str(_options["candidate"]), str(_options["incumbent"]), leg
	)
	_current_seats = seats
	_observed_players.clear()
	var config: GameConfig = GameConfig.full_game()
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
	session.fight_observer = _on_fight
	session.turn_observer = _on_turn.bind(suite, game_seed)
	var turns: int = 0
	while not session.is_over() and turns < MAX_TURNS:
		session.end_turn()
		turns += 1
	_write_game(suite, game_seed, session, seats)


func _on_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	if _options["trace"] == "on":
		var outcome: Dictionary = result.duplicate()
		outcome.erase("events")
		var trace: FileAccess = _files["fight_trace"]
		trace.store_line(
			JSON.stringify({"round": round_number, "players": [id_a, id_b], "outcome": outcome})
		)
	_fights[id_a] = CoreUtil.to_int(_fights.get(id_a, 0)) + 1
	_fights[id_b] = CoreUtil.to_int(_fights.get(id_b, 0)) + 1
	var carried: Array[Dictionary] = result["carry"]
	for change: Dictionary in carried:
		if str(change.get("op", "")) != "add_card":
			continue
		var gold: int = BotEval.item_gold(_library.get_card(str(change["card"])))
		if gold <= 0:
			continue
		var side_id: int = id_a if CoreUtil.to_int(change["side"]) == 0 else id_b
		var count: int = CoreUtil.to_int(change["count"])
		_acorns[side_id] = CoreUtil.to_int(_acorns.get(side_id, 0)) + count
		_acorn_gold[side_id] = CoreUtil.to_int(_acorn_gold.get(side_id, 0)) + gold * count


func _on_turn(
	player: PlayerState, round_number: int, usec: int, suite: String, game_seed: int
) -> void:
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
	var file: FileAccess = _files["players"]
	(
		file
		. store_line(
			(
				"%s,%d,%d,%s,%s,%s,%d,%d,%d,%s,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%s,%s,%s,%s"
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
					BenchTribes.final_tribe(final_player.fought_specs, _library),
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
