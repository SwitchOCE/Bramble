extends SceneTree
## Ring experiment metrics on real full-strength bot games. No rule switches.
## godot --headless -s res://tools/sim/engines_probe.gd -- games=20 first_seed=86100
## Samples full boards at rounds 10 and 15; a unit's Ring contribution uses the real rule helper.

var _session: GameSession
var _rows: Array = []
var _buys: Dictionary = {}


func _initialize() -> void:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=")
		if parts.size() == 2:
			args[parts[0]] = parts[1]
	var first: int = str(args.get("first_seed", "86100")).to_int()
	var games: int = str(args.get("games", "20")).to_int()
	var library := UnitLibrary.load_dir()
	for game: int in games:
		var config := GameConfig.full_game()
		config.set_value("human_bot", BotLevel.HARD)
		_session = GameSession.create(first + game, library, config)
		_rows.clear()
		_buys.clear()
		for player: PlayerState in _session._players:
			player.log_observer = _note.bind(player.id)
		_session.fight_observer = _fight
		print("eng_start: %d" % (first + game))
		var rounds: int = 0
		while not _session.is_over() and rounds < 60:
			_session.end_turn()
			rounds += 1
		var players: Array = []
		for player: PlayerState in _session._players:
			players.append(
				{"id": player.id, "place": player.placement, "picks": _buys.get(player.id, [0, 0])}
			)
		for value: Variant in _rows:
			var row: Dictionary = value
			row["place"] = _session._players[CoreUtil.to_int(row["player"])].placement
		print(
			(
				"eng_game: %s"
				% JSON.stringify(
					{"seed": first + game, "rounds": rounds, "players": players, "rows": _rows}
				)
			)
		)
	quit(0)


func _note(type: String, fields: Dictionary, pid: int) -> void:
	if type != "buy":
		return
	var def: Dictionary = _session.get_rules().library.get_unit(str(fields.get("unit", "")))
	var tribes: Array = def.get("tribes", [])
	var picks: Array = _buys.get(pid, [0, 0])
	picks[0] = CoreUtil.to_int(picks[0]) + 1
	picks[1] = CoreUtil.to_int(picks[1]) + (1 if tribes.has("Fairies") else 0)
	_buys[pid] = picks


func _fight(round_now: int, pid_a: int, pid_b: int, _result: Dictionary) -> void:
	if round_now not in [10, 15]:
		return
	for pid: int in [pid_a, pid_b]:
		if pid < 0:
			continue
		var player: PlayerState = _session._players[pid]
		var board: Array = []
		for slot: int in BoardGeometry.SLOTS:
			var unit: RecruitUnit = player.board[slot]
			if unit == null:
				continue
			var effects: Array = player.slot_effects[slot]
			var rings: Vector2i = BoardUpkeep.ring_stats(unit, effects)
			board.append(
				{
					"id": unit.def_id(),
					"tier": unit.tier(),
					"fairy": unit.has_tribe("Fairies"),
					"stats": unit.attack + unit.health,
					"rings": rings.x + rings.y
				}
			)
		_rows.append({"round": round_now, "player": pid, "board": board})
