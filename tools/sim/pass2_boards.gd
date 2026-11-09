extends SceneTree
## Fixed R9 boards through the real recruiting snapshot and fight engine. Every pair is played
## at identical seeds with sides swapped; earned carry is deliberately discarded between fights.
## Usage: godot --headless -s res://tools/sim/pass2_boards.gd -- repetitions=100 seed=92100
## Optional: out=build/pass2-boards input=res://path/to/boards.json sensitivity=1

const INPUT: String = "res://docs/ideation/evidence/pass2-boards.json"
var _library: UnitLibrary
var _config: GameConfig
var _rules: RecruitRules
var _errors: Array[String] = []
var _desired: Dictionary = {}
var _snapshots: Array[Dictionary] = []
var _fixtures: Array[Dictionary] = []


func _initialize() -> void:
	var options: Dictionary = {"repetitions": "100", "seed": "92100", "out": "build/pass2-boards"}
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() == 2:
			options[parts[0]] = parts[1]
	var repetitions: int = maxi(1, str(options["repetitions"]).to_int())
	var first_seed: int = str(options["seed"]).to_int()
	var input_path: String = str(options.get("input", INPUT))
	_library = UnitLibrary.load_dir()
	_config = GameConfig.full_game()
	_rules = RecruitRules.create(_library, _config, UnitPool.create(_library, _config))
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(input_path))
	for value: Variant in input["boards"]:
		var fixture: Dictionary = value
		_fixtures.append(fixture)
		_snapshots.append(_snapshot(fixture))
	if not _errors.is_empty():
		for problem: String in _errors:
			printerr("pass2_boards: " + problem)
		quit(2)
		return
	var results: Array = _empty_results(_fixtures.size())
	var fights: int = 0
	var stopped: int = 0
	var attack_limits: int = 0
	var terminations: Dictionary = {}
	for first: int in _fixtures.size():
		for second: int in range(first + 1, _fixtures.size()):
			for repeat: int in repetitions:
				var seed_now: int = first_seed + repeat
				for leg: int in 2:
					var a: int = first if leg == 0 else second
					var b: int = second if leg == 0 else first
					var fight: Dictionary = _fight(a, b, seed_now)
					var winner: int = CoreUtil.to_int(fight["winner"])
					var reason: String = str(fight["reason"])
					terminations[reason] = CoreUtil.to_int(terminations.get(reason, 0)) + 1
					attack_limits += 1 if reason == Combat.REASON_ATTACK_LIMIT else 0
					_add(results, a, b, winner)
					stopped += 1 if str(fight["reason"]) == Combat.REASON_TRIGGER_LIMIT else 0
					fights += 1
		print("pass2_boards: completed " + str(first + 1) + "/" + str(_fixtures.size()))
	var summary: Dictionary = {
		"input": input_path,
		"first_seed": first_seed,
		"repetitions": repetitions,
		"games_per_pair": repetitions * 2,
		"fights": fights,
		"trigger_limit_fights": stopped,
		"attack_limit_fights": attack_limits,
		"termination_reasons": terminations,
		"boards": _fixtures,
		"snapshots": _snapshots,
		"results": results,
	}
	if str(options.get("sensitivity", "0")) == "1":
		summary["sensitivity"] = _sensitivity(repetitions, first_seed, results)
	var sensitivity: Dictionary = summary.get("sensitivity", {})
	var out: String = str(options["out"])
	_write(out + ".results.json", JSON.stringify(summary, "  "))
	_write(
		out + ".results.md",
		(
			_report(results, fights, repetitions, first_seed, stopped, attack_limits)
			+ _sensitivity_report(sensitivity)
		)
	)
	print(
		(
			"pass2_boards: fights=%d trigger_limits=%d attack_limits=%d out=%s.results.*"
			% [fights, stopped, attack_limits, out]
		)
	)
	var sensitivity_reasons: Dictionary = sensitivity.get("termination_reasons", {})
	var sensitivity_stopped: int = CoreUtil.to_int(
		sensitivity_reasons.get(Combat.REASON_TRIGGER_LIMIT, 0)
	)
	quit(0 if stopped + sensitivity_stopped == 0 else 1)


func _snapshot(fixture: Dictionary) -> Dictionary:
	_desired.clear()
	var player := PlayerState.new()
	player.round_number = 9
	player.tier = CoreUtil.to_int(fixture["tier"])
	var bonuses: Dictionary = fixture.get("tribe_bonuses", {})
	player.tribe_bonuses = bonuses.duplicate(true)
	for label: String in fixture["slots"]:
		var spec: Variant = fixture["slots"][label]
		if spec != null:
			var unit_spec: Dictionary = spec
			player.board[BoardGeometry.LABELS.find(label)] = _unit(unit_spec)
	for value: Variant in fixture.get("away", []):
		var entry: Dictionary = value
		var bird_spec: Dictionary = entry["unit"]
		(
			player
			. away
			. append(
				{
					"unit": _unit(bird_spec),
					"nest": BoardGeometry.LABELS.find(str(entry["nest"])),
					"left": CoreUtil.to_int(entry["left"]),
					"due": CoreUtil.to_int(entry["due"]),
				}
			)
		)
	for label: String in fixture.get("rings", {}):
		var stats: Array = fixture["rings"][label]
		BoardUpkeep.add_ring(
			player,
			BoardGeometry.LABELS.find(label),
			{"attack": CoreUtil.to_int(stats[0]), "health": CoreUtil.to_int(stats[1])}
		)
	for label: Variant in fixture.get("bands", []):
		var slot: int = BoardGeometry.LABELS.find(str(label))
		if player.board[slot] != null:
			player.bands[slot] = player.board[slot].iid
	for card: Variant in fixture.get("items", []):
		player.items.append(HandItem.make(_library.get_card(str(card)), _rules.new_iid()))
	_rules.board_changed(player)
	# The fixture lists effective recruit stats. Strip live layers from its permanent allocation;
	# combat_spec omits those live layers and the engine recalculates them exactly once.
	for unit: RecruitUnit in player.all_units():
		var want: Dictionary = _desired[unit.iid]
		unit.add_permanent(
			CoreUtil.to_int(want["attack"]) - unit.attack,
			CoreUtil.to_int(want["health"]) - unit.health
		)
	_rules.board_changed(player)
	var displayed: Array = []
	var total: int = 0
	for slot: int in BoardGeometry.SLOTS:
		var unit: RecruitUnit = player.board[slot]
		if unit != null:
			displayed.append(
				{
					"slot": str(BoardGeometry.LABELS[slot]),
					"unit": unit.def_id(),
					"attack": unit.attack,
					"health": unit.health
				}
			)
			total += _total(unit)
			continue
		var nest: Dictionary = player.nest_at(slot)
		if not nest.is_empty():
			var bird: RecruitUnit = nest["unit"]
			var egg: Dictionary = HeldUnits.egg_forecast(player, bird, slot)
			displayed.append(
				{
					"slot": str(BoardGeometry.LABELS[slot]),
					"unit": "nest_egg",
					"attack": egg["attack"],
					"health": egg["health"]
				}
			)
			total += CoreUtil.to_int(egg["attack"]) + CoreUtil.to_int(egg["health"])
	for unit: RecruitUnit in player.all_units():
		var want: Dictionary = _desired[unit.iid]
		if (
			unit.attack != CoreUtil.to_int(want["attack"])
			or unit.health != CoreUtil.to_int(want["health"])
		):
			_errors.append(str(fixture["id"]) + ": effective stats differ for " + unit.def_id())
	return {
		"board": player.combat_board(),
		"slots": player.combat_slots(),
		"rules": _rules.fight_rules(player),
		"tier": player.tier,
		"displayed": displayed,
		"stat_total": total
	}


func _unit(spec: Dictionary) -> RecruitUnit:
	var def: Dictionary = _library.get_unit(str(spec["def_id"]))
	if def.is_empty():
		_errors.append("Unknown unit: " + str(spec["def_id"]))
		return null
	var unit := RecruitUnit.make(def, _rules.new_iid(), CoreUtil.to_bool(spec.get("golden", false)))
	unit.origin = (
		RecruitUnit.ORIGIN_BOUGHT
		if CoreUtil.to_bool(def.get("pool", false))
		else RecruitUnit.ORIGIN_CREATED
	)
	unit.add_permanent(
		CoreUtil.to_int(spec["attack"]) - unit.attack, CoreUtil.to_int(spec["health"]) - unit.health
	)
	_desired[unit.iid] = spec
	for inner: Variant in spec.get("held", []):
		var inner_spec: Dictionary = inner
		unit.held.append(_unit(inner_spec))
	if unit.held.size() > unit.mechanic_number("belly", "size"):
		_errors.append("Belly capacity exceeded: " + unit.def_id())
	return unit


func _fight(a: int, b: int, fight_seed: int, boosted: int = -1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = fight_seed
	var combat := Combat.create(_library, _config, rng)
	combat.log_events = false
	combat.round_number = 9
	var first_slots: Array = _snapshots[a]["slots"]
	var second_slots: Array = _snapshots[b]["slots"]
	var first_rules: Dictionary = _snapshots[a]["rules"]
	var second_rules: Dictionary = _snapshots[b]["rules"]
	var first_source: Array = _snapshots[a]["board"]
	var second_source: Array = _snapshots[b]["board"]
	var first_board: Array = first_source.duplicate(true)
	var second_board: Array = second_source.duplicate(true)
	if a == boosted:
		_boost_board(first_board)
	if b == boosted:
		_boost_board(second_board)
	combat.slot_effects = [first_slots.duplicate(true), second_slots.duplicate(true)]
	combat.side_rules = [first_rules.duplicate(true), second_rules.duplicate(true)]
	var tiers: Array[int] = [_snapshots[a]["tier"], _snapshots[b]["tier"]]
	var ids: Array[int] = [0, 1]
	return combat.run([first_board, second_board], tiers, ids, 0)


## A perturbation of the fight, separate from the economically justified recruit fixture.
## Combat fields bypass permanent-growth caps and Shy's recruiting immunity. Egg auras
## still use the unchanged away Bird; the Egg itself gets exactly one extra combat +1/+1.
static func _boost_board(board: Array) -> void:
	for value: Variant in board:
		if value == null:
			continue
		var spec: Dictionary = value
		spec["combat_attack"] = CoreUtil.to_int(spec.get("combat_attack", 0)) + 1
		spec["combat_health"] = CoreUtil.to_int(spec.get("combat_health", 0)) + 1
		var held: Array = spec.get("held", [])
		_boost_board(held)


func _sensitivity(repetitions: int, first_seed: int, baseline: Array) -> Dictionary:
	var rows: Array = []
	var reasons: Dictionary = {}
	var fights: int = 0
	for a: int in _fixtures.size():
		var results: Array = _empty_results(_fixtures.size())
		var before: Dictionary = {"wins": 0, "ties": 0, "losses": 0}
		var after: Dictionary = {"wins": 0, "ties": 0, "losses": 0}
		var opponents: int = 0
		for b: int in _fixtures.size():
			if a == b or _fixtures[a]["roll"] != _fixtures[b]["roll"]:
				continue
			opponents += 1
			for key: String in before:
				before[key] += CoreUtil.to_int(baseline[a][b][key])
			for repeat: int in repetitions:
				for leg: int in 2:
					var first: int = a if leg == 0 else b
					var second: int = b if leg == 0 else a
					var fight: Dictionary = _fight(first, second, first_seed + repeat, a)
					_add(results, first, second, CoreUtil.to_int(fight["winner"]))
					var reason: String = str(fight["reason"])
					reasons[reason] = CoreUtil.to_int(reasons.get(reason, 0)) + 1
					fights += 1
			for key: String in after:
				after[key] += CoreUtil.to_int(results[a][b][key])
		var games: int = repetitions * 2 * opponents
		(
			rows
			. append(
				{
					"id": _fixtures[a]["id"],
					"games": games,
					"baseline": before,
					"plus_one": after,
					"baseline_win_percent": 100.0 * CoreUtil.to_int(before["wins"]) / games,
					"plus_one_win_percent": 100.0 * CoreUtil.to_int(after["wins"]) / games,
					"delta_percentage_points":
					(
						100.0
						* (CoreUtil.to_int(after["wins"]) - CoreUtil.to_int(before["wins"]))
						/ games
					),
					"pair_results": results[a],
				}
			)
		)
		print("pass2_boards: sensitivity " + str(a + 1) + "/" + str(_fixtures.size()))
	return {
		"method":
		(
			"One board at a time receives combat-only +1/+1 on every starting fighter, "
			+ "recursively including held bodies and Eggs. Away Bird source stats stay fixed; no "
			+ "direct gift is applied to later summons. Five same-roll baseline opponents, "
			+ "identical seed pairs "
			+ "and swapped sides; carry discarded. No recruiting buff or economic spend is claimed."
		),
		"fights": fights,
		"termination_reasons": reasons,
		"rows": rows,
	}


static func _sensitivity_report(sensitivity: Dictionary) -> String:
	if sensitivity.is_empty():
		return ""
	var lines: Array[String] = [
		"",
		"**+1/+1 sensitivity (same roll)**",
		"",
		str(sensitivity["method"]),
		"",
		"| Board | Base win % | +1/+1 win % | Change (pp) |",
		"|---|---:|---:|---:|"
	]
	for row: Dictionary in sensitivity["rows"]:
		lines.append(
			(
				"| %s | %.1f | %.1f | %+.1f |"
				% [
					row["id"],
					row["baseline_win_percent"],
					row["plus_one_win_percent"],
					row["delta_percentage_points"]
				]
			)
		)
	lines.append("")
	lines.append(
		(
			"Sensitivity fights: %d. Terminations: %s."
			% [sensitivity["fights"], JSON.stringify(sensitivity["termination_reasons"])]
		)
	)
	return "\n".join(lines) + "\n"


static func _total(unit: RecruitUnit) -> int:
	var total: int = unit.attack + unit.health
	for inner: RecruitUnit in unit.held:
		total += _total(inner)
	return total


static func _empty_results(size: int) -> Array:
	var out: Array = []
	for _first: int in size:
		var row: Array = []
		for _second: int in size:
			row.append({"wins": 0, "ties": 0, "losses": 0})
		out.append(row)
	return out


static func _add(results: Array, a: int, b: int, winner: int) -> void:
	var mine: Dictionary = results[a][b]
	var theirs: Dictionary = results[b][a]
	if winner < 0:
		mine["ties"] += 1
		theirs["ties"] += 1
	elif winner == 0:
		mine["wins"] += 1
		theirs["losses"] += 1
	else:
		mine["losses"] += 1
		theirs["wins"] += 1


func _report(
	results: Array, fights: int, repetitions: int, first_seed: int, stopped: int, attack_limits: int
) -> String:
	var lines: Array[String] = [
		"# Pass 2 board round robin",
		"",
		(
			(
				"%d fresh fights; %d per pair, seed pairs %d–%d, each played with sides swapped. "
				+ "Trigger-limit fights: %d; attack-limit fights: %d. Cells are strict win %% "
				+ "(ties excluded from wins but included in the denominator)."
			)
			% [
				fights,
				repetitions * 2,
				first_seed,
				first_seed + repetitions - 1,
				stopped,
				attack_limits
			]
		),
		""
	]
	for roll: String in ["high", "low", "all"]:
		var indices: Array[int] = []
		var header: String = "| Board"
		var separator: String = "|---"
		for index: int in _fixtures.size():
			if roll == "all" or str(_fixtures[index]["roll"]) == roll:
				indices.append(index)
				header += " | " + str(_fixtures[index]["id"])
				separator += " |---:"
		lines.append(
			"**" + roll.capitalize() + " roll**" if roll != "all" else "**All twelve boards**"
		)
		lines.append("")
		lines.append(header + " | Win % | Tie % | Score % |")
		lines.append(separator + " |---:|---:|---:|")
		for a: int in indices:
			var row: String = "| " + str(_fixtures[a]["id"])
			var wins: int = 0
			var ties: int = 0
			var games: int = 0
			for b: int in indices:
				var cell: Dictionary = results[a][b]
				var n: int = (
					CoreUtil.to_int(cell["wins"])
					+ CoreUtil.to_int(cell["ties"])
					+ CoreUtil.to_int(cell["losses"])
				)
				row += " | —" if a == b else " | %.1f" % (100.0 * CoreUtil.to_int(cell["wins"]) / n)
				wins += CoreUtil.to_int(cell["wins"])
				ties += CoreUtil.to_int(cell["ties"])
				games += n
			row += (
				" | %.1f | %.1f | %.1f |"
				% [100.0 * wins / games, 100.0 * ties / games, 100.0 * (wins + ties * 0.5) / games]
			)
			lines.append(row)
		lines.append("")
	(
		lines
		. append(
			(
				"Score counts a draw as half a win. JSON retains wins, ties and losses for every ordered "
				+ "pairing. These are fixed-board fight rates; they do not estimate a tribe's lobby win rate."
			)
		)
	)
	return "\n".join(lines) + "\n"


static func _write(path: String, body: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write " + path)
		return
	file.store_string(body)
