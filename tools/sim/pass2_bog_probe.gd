extends "res://tools/sim/pass2_boards.gd"
## Reproducible logged diagnosis and same-seed wait ablation of the published R9 boards.

const FightLog := preload("res://tools/play/play_fight_log.gd")


func _initialize() -> void:
	_library = UnitLibrary.load_dir()
	_config = GameConfig.full_game()
	_rules = RecruitRules.create(_library, _config, UnitPool.create(_library, _config))
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	for value: Variant in input["boards"]:
		var fixture: Dictionary = value
		_fixtures.append(fixture)
		_snapshots.append(_snapshot(fixture))
	if not _errors.is_empty():
		printerr(_errors)
		quit(2)
		return
	var bog: int = _index("bog_high")
	var hedge: int = _index("hedgerow_high")
	for fight_seed: int in range(92100, 92103):
		var fight: Dictionary = _logged(bog, hedge, fight_seed, true)
		_write("build/pass2-bog-%d.json" % fight_seed, JSON.stringify(fight, "  "))
		var names: Dictionary = {}
		var lines: Array[String] = ["# bog_high vs hedgerow_high, seed %d" % fight_seed, ""]
		var events_here: Array[Dictionary] = fight["events"]
		for index: int in events_here.size():
			lines.append("%d. %s" % [index, FightLog.event_line(events_here[index], names, 0)])
		_write("build/pass2-bog-%d.md" % fight_seed, "\n".join(lines) + "\n")
	var rows: Array[Dictionary] = []
	for bog_id: String in ["bog_high", "bog_low"]:
		var a: int = _index(bog_id)
		for b: int in _fixtures.size():
			if a == b:
				continue
			var row: Dictionary = {"board": bog_id, "opponent": _fixtures[b]["id"]}
			for enabled: bool in [true, false]:
				var wins: int = 0
				var ties: int = 0
				for fight_seed: int in range(92100, 92200):
					for leg: int in 2:
						var fight: Dictionary = _logged(
							a if leg == 0 else b, b if leg == 0 else a, fight_seed, enabled
						)
						var winner: int = CoreUtil.to_int(fight["winner"])
						wins += 1 if winner == leg else 0
						ties += 1 if winner < 0 else 0
				row["wait_on" if enabled else "wait_off"] = {
					"wins": wins, "ties": ties, "fights": 200
				}
			rows.append(row)
			print("bog_probe: ", row)
	_write("build/pass2-bog-ablation.json", JSON.stringify(rows, "  "))
	quit(0)


func _index(id: String) -> int:
	for index: int in _fixtures.size():
		if str(_fixtures[index]["id"]) == id:
			return index
	return -1


func _logged(a: int, b: int, fight_seed: int, wait_enabled: bool) -> Dictionary:
	var rng_here := RandomNumberGenerator.new()
	rng_here.seed = fight_seed
	var combat := Combat.create(_library, _config, rng_here)
	combat.mire_wait_enabled = wait_enabled
	combat.round_number = 9
	var first_slots: Array = _snapshots[a]["slots"]
	var second_slots: Array = _snapshots[b]["slots"]
	var first_rules: Dictionary = _snapshots[a]["rules"]
	var second_rules: Dictionary = _snapshots[b]["rules"]
	var first_board: Array = _snapshots[a]["board"]
	var second_board: Array = _snapshots[b]["board"]
	combat.slot_effects = [first_slots.duplicate(true), second_slots.duplicate(true)]
	combat.side_rules = [first_rules.duplicate(true), second_rules.duplicate(true)]
	var tiers: Array[int] = [_snapshots[a]["tier"], _snapshots[b]["tier"]]
	return combat.run([first_board.duplicate(true), second_board.duplicate(true)], tiers, [0, 1], 0)
