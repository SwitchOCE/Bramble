extends SceneTree
## Fixed native recipes versus actual median Hard control boards, paired in both orientations.
## -- captures=<control.fights.jsonl> out=<prefix> [pairs=16] [recipes=<json>]

const DEFAULT_RECIPES: String = "res://tools/sim/recipes/potluck-constructed.json"


static func recipe_errors(recipe: Dictionary, library: UnitLibrary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var units: Array = recipe.get("units", [])
	if units.size() != BoardGeometry.SLOTS:
		return ["recipe needs seven explicit slots"]
	var active: int = 0
	var belly: int = 0
	for spec: Dictionary in units:
		var definition: Dictionary = library.get_unit(str(spec.get("def_id", "")))
		if definition.is_empty():
			errors.append("unknown native body")
			continue
		if CoreUtil.to_int(definition["tier"]) > CoreUtil.to_int(recipe["tier"]):
			errors.append("body above recipe tier")
		var native: bool = false
		for entry: Dictionary in definition.get("mechanics", []):
			native = native or str(entry.get("id", "")) == "pass3_ooze"
		if not native or CoreUtil.to_bool(spec.get("golden", false)):
			errors.append("active bodies must be normal native Oozes")
		active += _stats(spec)
		var unit: RecruitUnit = RecruitUnit.make(definition, 1)
		var contents: Array = spec.get("held", [])
		if contents.size() > HeldUnits.belly_size(unit):
			errors.append("recipe Belly exceeds native capacity")
		for held: Dictionary in contents:
			if library.get_unit(str(held.get("def_id", ""))).is_empty() or held.has("held"):
				errors.append("invalid or nested reserve")
			belly += _stats(held)
	if active != CoreUtil.to_int(recipe["expected_active_stats"]):
		errors.append("active stat budget mismatch")
	if belly != CoreUtil.to_int(recipe["expected_belly_stats"]):
		errors.append("Belly stat budget mismatch")
	return errors


static func _stats(spec: Dictionary) -> int:
	var stats: Array = spec.get("stats", [])
	return CoreUtil.to_int(stats[0]) + CoreUtil.to_int(stats[1]) if stats.size() == 2 else -1000000


func _initialize() -> void:
	var options: Dictionary = {"captures": "", "out": "", "pairs": "16", "recipes": DEFAULT_RECIPES}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		assert(parts.size() == 2 and options.has(parts[0]), "unknown constructed option")
		options[parts[0]] = parts[1]
	assert(str(options["captures"]) != "" and str(options["out"]) != "")
	var pairs: int = str(options["pairs"]).to_int()
	assert(pairs > 0)
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(str(options["recipes"]))
	)
	var library: UnitLibrary = UnitLibrary.load_dir()
	var recipes: Array = document["boards"]
	var rounds: Array[int] = []
	for recipe: Dictionary in recipes:
		assert(recipe_errors(recipe, library).is_empty(), str(recipe_errors(recipe, library)))
		rounds.append(CoreUtil.to_int(recipe["round"]))
	var pool: Dictionary = _hard_sides(str(options["captures"]), rounds)
	var output: FileAccess = FileAccess.open(
		str(options["out"]) + ".fights.jsonl", FileAccess.WRITE
	)
	assert(output != null)
	var reports: Array = []
	for recipe: Dictionary in recipes:
		var round_number: int = CoreUtil.to_int(recipe["round"])
		var candidates: Array = pool[round_number]
		var chosen: Dictionary = _median(candidates)
		var opponent: Dictionary = chosen["side"]
		var values: Dictionary = opponent["config"]
		var config: GameConfig = FightCapture.config_for(values)
		assert(
			config.get_string("pass3_preset") == "B", "constructed proof requires current B control"
		)
		var ours: Dictionary = RealDesignedBoards.make_board(recipe, library, config)
		ours["config"] = values.duplicate(true)
		var wins: int = 0
		var draws: int = 0
		for replicate: int in pairs:
			var seed_value: int = 281000 + round_number * 100 + replicate
			for orientation: int in 2:
				var input: Dictionary = FieldCombat.pair_input(
					ours if orientation == 0 else opponent,
					opponent if orientation == 0 else ours,
					seed_value
				)
				var record: Dictionary = _run(input, library)
				var result: Dictionary = record["result"]
				var winner: int = CoreUtil.to_int(result["winner"])
				wins += 1 if winner == orientation else 0
				draws += 1 if winner < 0 else 0
				var snapshots: Array = record["combat_start"]
				var snapshot: Dictionary = snapshots[orientation]
				assert(
					(
						CoreUtil.to_int(snapshot["active_stats"])
						== CoreUtil.to_int(recipe["expected_active_stats"])
					)
				)
				record.merge(
					{
						"recipe": recipe["id"],
						"replicate": replicate,
						"seed": seed_value,
						"constructed_side": orientation,
						"opponent_source": chosen["source"],
						"telemetry": _telemetry(recipe, ours, snapshot)
					}
				)
				output.store_line(JSON.stringify(record, "", true, true))
		reports.append(
			{
				"recipe": recipe["id"],
				"round": round_number,
				"trials": pairs * 2,
				"wins": wins,
				"draws": draws,
				"losses": pairs * 2 - wins - draws,
				"median_opponent": chosen
			}
		)
	output.close()
	var report: FileAccess = FileAccess.open(str(options["out"]) + ".report.json", FileAccess.WRITE)
	assert(report != null)
	report.store_string(
		(
			JSON.stringify(
				{
					"construction": document["construction"],
					"capture_source": options["captures"],
					"capture_sha256": FileAccess.get_sha256(str(options["captures"])),
					"recipe_sha256": FileAccess.get_sha256(str(options["recipes"])),
					"reports": reports
				},
				"\t",
				true,
				true
			)
			+ "\n"
		)
	)
	print("potluck_constructed: %d logged fixed-board fights" % (recipes.size() * pairs * 2))
	quit(0)


static func _hard_sides(path: String, rounds: Array[int]) -> Dictionary:
	var pool: Dictionary = {}
	var seen: Dictionary = {}
	for round_number: int in rounds:
		pool[round_number] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert(file != null)
	while not file.eof_reached():
		var line: String = file.get_line()
		if line.strip_edges() == "":
			continue
		var record: Dictionary = JSON.parse_string(line)
		var input: Dictionary = record["input"]
		var round_number: int = CoreUtil.to_int(input["round"])
		if not rounds.has(round_number):
			continue
		var snapshots: Array = record["combat_start"]
		var values: Dictionary = input["config"]
		var boards: Array = input["boards"]
		var slots: Array = input["slots"]
		var heroes: Array = input["hero_effects"]
		var rules: Array = input["fight_rules"]
		for side: int in 2:
			var seat: int = CoreUtil.to_int(input["player_ids"][side])
			var snapshot: Dictionary = snapshots[side]
			if seat < 0 or not str(snapshot.get("assigned_line", "")).begins_with("hard"):
				continue
			var key: String = "%s:%d:%d" % [str(record["seed"]), seat, round_number]
			if seen.has(key):
				continue
			seen[key] = true
			var board: Array = boards[side]
			var side_slots: Array = slots[side]
			var side_heroes: Array = heroes[side]
			var side_rules: Dictionary = rules[side]
			var candidate: Dictionary = {
				"source": key,
				"size": CoreUtil.to_int(snapshot["active_stats"]),
				"side":
				{
					"id": key,
					"round": round_number,
					"layout": "blind",
					"config": values.duplicate(true),
					"board": board.duplicate(true),
					"slots": side_slots.duplicate(true),
					"hero_effects": side_heroes.duplicate(true),
					"fight_rules": side_rules.duplicate(true),
					"tier": input["tiers"][side]
				}
			}
			var candidates: Array = pool[round_number]
			candidates.append(candidate)
	return pool


static func _median(candidates: Array) -> Dictionary:
	assert(not candidates.is_empty(), "no captured Hard opponents at requested round")
	candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return (
				a["size"] < b["size"]
				if a["size"] != b["size"]
				else str(a["source"]) < str(b["source"])
			)
	)
	var middle: int = floori((candidates.size() - 1) * 0.5)
	var selected: Dictionary = candidates[middle]
	var chosen: Dictionary = selected.duplicate(true)
	chosen["population"] = candidates.size()
	chosen["selection"] = (
		"lower central actual board by combat-start active stats; "
		+ "ties use source id; no outcome selection"
	)
	return chosen


static func _run(input: Dictionary, library: UnitLibrary) -> Dictionary:
	var values: Dictionary = input["config"]
	var config: GameConfig = FightCapture.config_for(values)
	var rng := RandomNumberGenerator.new()
	rng.seed = str(input["rng_seed"]).to_int()
	rng.state = str(input["rng_state"]).to_int()
	var configured: UnitLibrary = FightCapture.library_for(values, library)
	var combat: Combat = CaptureCombat.instrument(configured, config, rng)
	combat.effect_rng.seed = str(input["effect_rng_seed"]).to_int()
	combat.effect_rng.state = str(input["effect_rng_state"]).to_int()
	var slots: Array = input["slots"]
	var heroes: Array = input["hero_effects"]
	var rules: Array = input["fight_rules"]
	var boards: Array = input["boards"]
	combat.slot_effects = slots.duplicate(true)
	combat.hero_effects = heroes.duplicate(true)
	combat.side_rules = rules.duplicate(true)
	combat.round_number = CoreUtil.to_int(input["round"])
	var tiers: Array[int] = [CoreUtil.to_int(input["tiers"][0]), CoreUtil.to_int(input["tiers"][1])]
	var result: Dictionary = combat.run(boards.duplicate(true), tiers, [0, 1], 0)
	var record: Dictionary = FightCapture.record(input, result, configured, combat)
	record["events"] = result["events"]
	return record


static func _telemetry(recipe: Dictionary, ours: Dictionary, snapshot: Dictionary) -> Dictionary:
	var bellies: Dictionary = {}
	var board: Array = ours["board"]
	for slot: int in board.size():
		var spec: Dictionary = board[slot]
		var held: Array = spec.get("held", [])
		if not held.is_empty():
			bellies[str(slot)] = held.duplicate(true)
	return {
		"round": recipe["round"],
		"gold": recipe["gold"],
		"shop_tier": recipe["tier"],
		"belly_contents_by_slot": bellies,
		"active_stats": snapshot["active_stats"],
		"belly_stats": recipe["expected_belly_stats"],
		"including_bellies":
		CoreUtil.to_int(snapshot["active_stats"]) + CoreUtil.to_int(recipe["expected_belly_stats"])
	}
