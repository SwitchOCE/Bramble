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
var _pending_peat: Dictionary = {}
var _banned_cards: Dictionary = {}
var _ban_invalid: bool = false


## Tools-only observation: native calls, events, rewards and RNG remain unchanged.
class PeatCombat:
	extends CaptureCombat
	var peat_sources: Dictionary = {}
	var other_king_raises: Array[int] = [0, 0]
	var other_cutter_gold: Array[int] = [0, 0]
	var _cutter_source: CombatUnit
	var _bog_native: Script

	func _setup(boards: Array) -> void:
		super._setup(boards)
		for side: int in 2:
			for unit: CombatUnit in units_of(side):
				_remember(unit, true)

	func enter_board(unit: CombatUnit, source: CombatUnit, fields: Dictionary = {}) -> void:
		_remember(unit)
		super.enter_board(unit, source, fields)
		_remember(unit)

	func _remember(unit: CombatUnit, starting: bool = false) -> void:
		if unit.def_id() not in ["peat_king", "peat_cutter"]:
			return
		var ability: String = "king" if unit.def_id() == "peat_king" else "cutter"
		var owner: int = CoreUtil.to_int(starting_sides.get(unit.uid, unit.side))
		if not peat_sources.has(unit.uid):
			peat_sources[unit.uid] = {
				"uid": unit.uid,
				"iid": unit.iid,
				"def_id": unit.def_id(),
				"owner_side": owner,
				"golden": unit.golden,
				"starting_board": starting,
				"eligible": false,
				"factor": 0,
				"copied": CoreUtil.to_bool(unit.get("copied_this_fight")),
				"raises": 0,
				"raises_for_opponent": 0,
				"gold": 0,
			}
		var row: Dictionary = peat_sources[unit.uid]
		row["copied"] = row["copied"] or CoreUtil.to_bool(unit.get("copied_this_fight"))
		if _bog_native == null:
			_bog_native = load("res://src/core/combat/pass3_bog_combat.gd")
		assert(_bog_native != null, "native Bog body requires its source build")
		if _bog_native.call("has", unit, ability):
			row["eligible"] = true
			row["factor"] = maxi(
				CoreUtil.to_int(row["factor"]),
				CoreUtil.to_int(_bog_native.call("ability", unit, ability).get("factor", 1))
			)

	func trigger(unit: CombatUnit, mechanic_id: String) -> void:
		_remember(unit)
		if mechanic_id == "pass3_bog:king":
			if unit.def_id() == "peat_king":
				var row: Dictionary = peat_sources[unit.uid]
				row["raises"] += 1
				row["raises_for_opponent"] += int(unit.side != CoreUtil.to_int(row["owner_side"]))
			else:
				other_king_raises[unit.side] += 1
		elif mechanic_id == "pass3_bog:cutter":
			assert(_cutter_source == null)
			_cutter_source = unit
		super.trigger(unit, mechanic_id)

	func carry_back(side: int, change: Dictionary) -> void:
		if _cutter_source != null:
			# Native _gold calls trigger immediately before this exact carry operation.
			assert(str(change.get("op", "")) == "gold_next_turn")
			var amount: int = CoreUtil.to_int(change["amount"])
			if _cutter_source.def_id() == "peat_cutter":
				var row: Dictionary = peat_sources[_cutter_source.uid]
				assert(CoreUtil.to_int(row["owner_side"]) == side)
				row["gold"] += amount
			else:
				other_cutter_gold[side] += amount
			_cutter_source = null
		super.carry_back(side, change)

	func peat_summary() -> Array:
		assert(_cutter_source == null)
		var out: Array = []
		for side: int in 2:
			var row: Dictionary = {
				"king_instances": [],
				"cutter_instances": [],
				"other_king_raises": other_king_raises[side],
				"other_cutter_gold": other_cutter_gold[side]
			}
			for entry: Dictionary in peat_sources.values():
				if CoreUtil.to_int(entry["owner_side"]) == side:
					var key: String = (
						"king_instances" if entry["def_id"] == "peat_king" else "cutter_instances"
					)
					row[key].append(entry.duplicate(true))
			out.append(row)
		return out


static func _peat_combat(
	library: UnitLibrary, config: GameConfig, rng: RandomNumberGenerator
) -> Combat:
	var combat := PeatCombat.new()
	combat.library = library
	combat.config = config
	combat.rng = rng
	combat.effect_rng = RandomNumberGenerator.new()
	combat.effect_rng.seed = rng.seed ^ 0x5EED
	return combat


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3 or args[0] not in ["probe", "run"]:
		printerr("expected probe|run PLAN OUTPUT")
		quit(2)
		return
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	var ban_errors: PackedStringArray = LinePolicies.validate_banned_cards(
		plan.get("banned_cards", {})
	)
	if not ban_errors.is_empty():
		printerr("; ".join(ban_errors))
		quit(2)
		return
	_banned_cards = plan.get("banned_cards", {}).duplicate(true)
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
		for seat: int in 8:
			var starting: String = _names[seat].get_slice(":", 0)
			if not _banned_cards.get(starting, []).is_empty():
				var brain: LineBrain = _session._bots[seat]
				brain.configure_banned_cards(_banned_cards[starting], _session._players[seat])
		_audit_bans()
		assert(_session._lobby_tribes.size() == 5)
		assert(_session._lobby_tribes.has("Birds") and _session._lobby_tribes.has("Fairies"))
		var assigned_builds: Array[String] = []
		var assigned_tribes: Array = []
		for seat: int in 8:
			var build: String = _session.build_of(seat)
			assigned_builds.append(build)
			assigned_tribes.append(BotKnowledge.shared().strategy(build).get("needs_tribes", []))
		_session.fight_capture_observer = _capture
		_session.combat_factory = _peat_combat
		_session.fight_observer = _after_fight
		while not _session.is_over() and not _ban_invalid:
			_session.end_turn()
			_audit_bans()
		if _ban_invalid:
			_stream.close()
			_session = null
			printerr("banned-card policy violation; entire run is invalid")
			quit(2)
			return
		var players: Array = []
		for row: Dictionary in _session.get_game_log()["players"]:
			var seat: int = CoreUtil.to_int(row["player_id"])
			var label: Dictionary = BenchTribes.classify(
				_session._players[seat].fought_specs, _session._library
			)
			players.append(
				{
					"seat": row["player_id"],
					"place": row["placement"],
					"rounds": row["rounds"].size(),
					"assigned_build": assigned_builds[seat],
					"assigned_tribes": assigned_tribes[seat],
					"final_tribe": label["final_tribe"],
					"plurality_tribe": label["plurality_tribe"],
					"plurality_share": label["plurality_share"],
					"no_tribe_reason": label["no_tribe_reason"]
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
							"banned_cards": _banned_cards,
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


func _audit_bans() -> void:
	for seat: int in 8:
		var starting: String = _names[seat].get_slice(":", 0)
		if _banned_cards.get(starting, []).is_empty():
			continue
		var brain: LineBrain = _session._bots[seat]
		var audit: Dictionary = brain.ban_audit(_session._players[seat])
		if audit["failure"] != "":
			_ban_invalid = true
			_stream.store_line(
				JSON.stringify(
					{"type": "ban_violation", "seed": _seed, "seat": seat, "audit": audit}
				)
			)


func _capture(input: Dictionary, result: Dictionary, combat: Combat) -> void:
	_audit_bans()
	var number: int = CoreUtil.to_int(input["round"])
	assert(_pending_peat.is_empty())
	var observed: PeatCombat = combat
	var sides: Array = observed.peat_summary()
	for side: int in 2:
		var row: Dictionary = sides[side]
		var seat: int = CoreUtil.to_int(input["player_ids"][side])
		row["seat"] = seat
		row["planned_all_gold"] = 0
		row["gold_next_turn_before"] = null
		if seat >= 0:
			row["gold_next_turn_before"] = _session._players[seat].gold_next_turn
		if seat >= 0:
			row["line"] = _names[seat].get_slice(":", 0)
			if not _banned_cards.get(row["line"], []).is_empty():
				var brain: LineBrain = _session._bots[seat]
				row["ban_audit"] = brain.ban_audit(_session._players[seat])
	for change: Dictionary in result["carry"]:
		if str(change.get("op", "")) == "gold_next_turn":
			sides[CoreUtil.to_int(change["side"])]["planned_all_gold"] += CoreUtil.to_int(
				change["amount"]
			)
	_pending_peat = {
		"type": "peat_diagnostic",
		"version": 1,
		"seed": _seed,
		"round": number,
		"player_ids": input["player_ids"].duplicate(),
		"sides": sides
	}
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
		if not _banned_cards.get(starting, []).is_empty():
			var brain: LineBrain = _session._bots[seat]
			snapshot["ban_audit"] = brain.ban_audit(_session._players[seat])
	_stream.store_line(JSON.stringify(capture, "", true, true))


func _after_fight(number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	assert(CoreUtil.to_int(_pending_peat["round"]) == number)
	assert(_pending_peat["player_ids"] == [id_a, id_b])
	var spoils: Array[int] = [0, 0]
	for event: Dictionary in result["events"]:
		if str(event.get("type", "")) == "early_spoils":
			spoils[CoreUtil.to_int(event["side"])] += CoreUtil.to_int(event["amount"])
	for side: int in 2:
		var row: Dictionary = _pending_peat["sides"][side]
		var seat: int = CoreUtil.to_int(row["seat"])
		if seat < 0:
			continue
		row["early_spoils_gold"] = spoils[side]
		row["gold_next_turn_after"] = _session._players[seat].gold_next_turn
		row["credited_all_gold"] = (
			CoreUtil.to_int(row["gold_next_turn_after"])
			- CoreUtil.to_int(row["gold_next_turn_before"])
			- spoils[side]
		)
		assert(row["credited_all_gold"] == row["planned_all_gold"], "carry gold did not reconcile")
		row["credited_cutter_gold"] = 0
		for entry: Dictionary in row["cutter_instances"]:
			row["credited_cutter_gold"] += CoreUtil.to_int(entry["gold"])
	_stream.store_line(JSON.stringify(_pending_peat, "", true, true))
	_pending_peat = {}
