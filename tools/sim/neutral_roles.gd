extends SceneTree
## -- [out=build/neutrals/neutral-roles] [recipes=res://tools/sim/recipes/neutral-roles.json]

const DEFAULT_RECIPES: String = "res://tools/sim/recipes/neutral-roles.json"
const FIGHTS := preload("res://tools/sim/potluck_constructed.gd")
const RECRUIT := preload("res://tools/sim/neutral_recruit_roles.gd")


static func recipe_errors(document: Dictionary, library: UnitLibrary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seeds: Array = document.get("seeds", [])
	if seeds.size() != 32:
		errors.append("exactly 32 paired seeds required")
	var roles: Array = document.get("roles", [])
	if roles.size() != 3:
		errors.append("three combat roles required")
	for role: Dictionary in roles:
		var card: String = str(role["card"])
		if not card in ["shieldbug", "ballooning_spider", "whirligig_beetle"]:
			errors.append("unrecognised role card")
		var own: Dictionary = role["ours"]
		var units: Array = own["units"]
		var source: int = CoreUtil.to_int(role["source_slot"])
		if units.size() != BoardGeometry.SLOTS or units[source] == null:
			errors.append("invalid source placement")
			continue
		var spec: Dictionary = units[source]
		if str(spec["def_id"]) != card:
			errors.append("source card mismatch")
		for name: String in ["ours", "theirs"]:
			var recipe: Dictionary = role[name]
			var board: Array = recipe["units"]
			if board.size() != BoardGeometry.SLOTS:
				errors.append("seven explicit slots required")
			for value: Variant in board:
				if value == null:
					continue
				var unit: Dictionary = value
				if library.get_unit(str(unit["def_id"])).is_empty():
					errors.append("unknown native card")
	return errors


## Remove the real mechanic, not an invented ability; leave every body and other card intact.
static func without_text(library: UnitLibrary, card_id: String) -> UnitLibrary:
	var out := UnitLibrary.new()
	for original: Dictionary in library.all_units():
		var card: Dictionary = original.duplicate(true)
		if str(card["id"]) == card_id:
			var entries: Array = []
			for entry: Dictionary in card["mechanics"]:
				if not (
					str(entry.get("id", "")) == "pass3_neutral"
					and str(entry.get("ability", "")) == card_id
				):
					entries.append(entry)
			card["mechanics"] = entries
			card.erase(MechanicRegistry.COMPILED_KEY)
		assert(out.register_unit(card) == "")
	for card: Dictionary in library.all_cards():
		out.register_card(card)
	for hero: Dictionary in library.all_heroes():
		out.register_hero(hero)
	return out


static func own_recipe(role: Dictionary, golden: bool) -> Dictionary:
	var original: Dictionary = role["ours"]
	var recipe: Dictionary = original.duplicate(true)
	var units: Array = recipe["units"]
	var source: Dictionary = units[CoreUtil.to_int(role["source_slot"])]
	source["golden"] = golden
	if golden and source.has("golden_stats"):
		source["stats"] = source["golden_stats"]
	return recipe


func _initialize() -> void:
	var options: Dictionary = {"out": "build/neutrals/neutral-roles", "recipes": DEFAULT_RECIPES}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		assert(parts.size() == 2 and options.has(parts[0]), "unknown neutral role option")
		options[parts[0]] = parts[1]
	var output_path: String = str(options["out"])
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(str(options["recipes"]))
	)
	var library: UnitLibrary = UnitLibrary.load_dir()
	assert(recipe_errors(document, library).is_empty(), str(recipe_errors(document, library)))
	var config: GameConfig = GameConfig.full_game()
	var raw: FileAccess = FileAccess.open(output_path + ".fights.jsonl", FileAccess.WRITE)
	assert(raw != null)
	var reports: Array = []
	var roles: Array = document["roles"]
	var seeds: Array = document["seeds"]
	for role: Dictionary in roles:
		var card: String = str(role["card"])
		var off: UnitLibrary = without_text(library, card)
		for golden: bool in [false, true]:
			var ours: Dictionary = RealDesignedBoards.make_board(
				own_recipe(role, golden), library, config
			)
			var opponent_recipe: Dictionary = role["theirs"]
			var theirs: Dictionary = RealDesignedBoards.make_board(opponent_recipe, library, config)
			var samples: Array = []
			var wins: Array[int] = [0, 0]
			var draws: Array[int] = [0, 0]
			for index: int in seeds.size():
				var side: int = index % 2
				var seed_value: int = CoreUtil.to_int(seeds[index])
				var input: Dictionary = FieldCombat.pair_input(
					ours if side == 0 else theirs, theirs if side == 0 else ours, seed_value
				)
				var pair: Dictionary = {"seed": seed_value, "our_side": side}
				for arm: int in 2:
					var record: Dictionary = FIGHTS._run(input, library if arm == 0 else off)
					var metrics: Dictionary = role_metrics(record, role, side)
					var result: Dictionary = record["result"]
					var winner: int = CoreUtil.to_int(result["winner"])
					wins[arm] += 1 if winner == side else 0
					draws[arm] += 1 if winner < 0 else 0
					var arm_name: String = "text_on" if arm == 0 else "text_off"
					pair[arm_name] = {"outcome": winner, "metrics": metrics}
					record.merge(
						{
							"role": role["id"],
							"golden": golden,
							"seed": seed_value,
							"our_side": side,
							"arm": arm_name,
							"role_metrics": metrics,
							"library_intervention":
							(
								{}
								if arm == 0
								else {
									"card": card,
									"remove_mechanic": "pass3_neutral",
									"ability": card
								}
							),
							"telemetry": {"gold": 0, "shop_tier": 6, "bellies": [], "larder": 0}
						}
					)
					raw.store_line(JSON.stringify(record, "", true, true))
				samples.append(pair)
			reports.append(
				{
					"role": role["id"],
					"card": card,
					"golden": golden,
					"paired_seeds": seeds.size(),
					"text_on_wins": wins[0],
					"text_off_wins": wins[1],
					"text_on_draws": draws[0],
					"text_off_draws": draws[1],
					"text_on_metrics": _aggregate(samples, "text_on"),
					"text_off_metrics": _aggregate(samples, "text_off"),
					"samples": samples,
					"assumptions": role.get("extra_assumptions", [])
				}
			)
	raw.close()
	var report: Dictionary = {
		"construction": document["construction"],
		"orientation_rule": document["orientation_rule"],
		"recipe_sha256": FileAccess.get_sha256(str(options["recipes"])),
		"raw_fights": output_path + ".fights.jsonl",
		"combat_roles": reports,
		"recruit_roles": RECRUIT.run(library, config),
		"resolved_rates": Pass3Rates.resolved(config)
	}
	var summary: FileAccess = FileAccess.open(output_path + ".report.json", FileAccess.WRITE)
	assert(summary != null)
	summary.store_string(JSON.stringify(report, "\t", true, true) + "\n")
	print("neutral_roles: %d logged fights, six normal/golden paired role reports" % (6 * 32 * 2))
	quit(0)


static func _aggregate(samples: Array, arm: String) -> Dictionary:
	var totals: Dictionary = {
		"carry_has_start_shield": 0,
		"carry_shield_blocks": 0,
		"first_carry_targets_enemy_carry": 0,
		"enemy_relocations": 0,
		"whirligig_health_loss_total": 0,
		"enemy_carry_after_start_states": []
	}
	var states: Array = totals["enemy_carry_after_start_states"]
	for pair: Dictionary in samples:
		var result: Dictionary = pair[arm]
		var metrics: Dictionary = result["metrics"]
		totals["carry_has_start_shield"] += 1 if metrics["carry_start_shield"] else 0
		totals["carry_shield_blocks"] += CoreUtil.to_int(metrics["carry_shield_blocks"])
		totals["first_carry_targets_enemy_carry"] += (
			1 if metrics["first_carry_targets_enemy_carry"] else 0
		)
		var moves: Array = metrics["enemy_relocations"]
		totals["enemy_relocations"] += moves.size()
		for loss: Dictionary in metrics["whirligig_health_loss"]:
			totals["whirligig_health_loss_total"] += CoreUtil.to_int(loss["amount"])
		var state: Dictionary = {
			"slot": metrics["enemy_carry_after_start_slot"],
			"health": metrics["enemy_carry_after_start_health"]
		}
		if not states.has(state):
			states.append(state)
	return totals


static func role_metrics(record: Dictionary, role: Dictionary, side: int) -> Dictionary:
	var starts: Array = record["combat_start"]
	var ours: Dictionary = starts[side]
	var theirs: Dictionary = starts[1 - side]
	var carry: Dictionary = _at(ours, CoreUtil.to_int(role["carry_slot"]))
	var enemy: Dictionary = _at(theirs, CoreUtil.to_int(role["enemy_carry_slot"]))
	var carry_uid: int = CoreUtil.to_int(carry["uid"])
	var enemy_uid: int = CoreUtil.to_int(enemy["uid"])
	var after: Array = record["after_start_effects"]
	var own_after: Dictionary = after[side]
	var enemy_after: Dictionary = after[1 - side]
	var carry_after: Dictionary = _uid(own_after, carry_uid)
	var enemy_state: Dictionary = _uid(enemy_after, enemy_uid)
	var shield: bool = false
	for status: Dictionary in carry_after.get("statuses", []):
		shield = shield or str(status["status"]) == "shield"
	var first: Dictionary = {}
	var relocations: Array = []
	var losses: Array = []
	var shield_blocks: int = 0
	var parasite_marks: int = 0
	for event: Dictionary in record["events"]:
		var kind: String = str(event["type"])
		if (
			kind == "attack"
			and CoreUtil.to_int(event["attacker"]) == carry_uid
			and first.is_empty()
		):
			first = event.duplicate(true)
		if kind == "relocate" and CoreUtil.to_int(event["side"]) == 1 - side:
			relocations.append(event.duplicate(true))
		if kind == "health_loss" and str(event.get("cause", "")) == "Whirligig":
			losses.append(event.duplicate(true))
		if kind == "damage" and CoreUtil.to_int(event["target"]) == carry_uid:
			var modifiers: Array = event["modifiers"]
			shield_blocks += 1 if modifiers.has("shield") else 0
		if kind == "status" and CoreUtil.to_int(event["target"]) == carry_uid:
			parasite_marks += 1 if event["status"] == "parasite" and event["on"] else 0
	return {
		"carry_uid": carry_uid,
		"enemy_carry_uid": enemy_uid,
		"carry_start_shield": shield,
		"first_carry_attack": first,
		"first_carry_targets_enemy_carry": CoreUtil.to_int(first.get("defender", -1)) == enemy_uid,
		"enemy_carry_start_slot": role["enemy_carry_slot"],
		"enemy_carry_after_start_slot": enemy_state.get("slot", -1),
		"enemy_carry_start_health": enemy["health"],
		"enemy_carry_after_start_health": enemy_state.get("health", -1),
		"enemy_relocations": relocations,
		"whirligig_health_loss": losses,
		"carry_shield_blocks": shield_blocks,
		"carry_parasite_marks": parasite_marks
	}


static func _at(snapshot: Dictionary, slot: int) -> Dictionary:
	for unit: Dictionary in snapshot["units"]:
		if CoreUtil.to_int(unit.get("slot", -1)) == slot and unit.get("active", false):
			return unit
	return {}


static func _uid(snapshot: Dictionary, uid: int) -> Dictionary:
	for unit: Dictionary in snapshot["units"]:
		if CoreUtil.to_int(unit["uid"]) == uid:
			return unit
	return {}
