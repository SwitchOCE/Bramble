extends SceneTree
## Fixed native R8 Supper versus an actual median Hard field board; no recruit continuation.
## -- captures=<new-Hedgerow-control.fights.jsonl> out=<prefix> [pairs=16] [recipes=<json>]

const FIXED := preload("res://tools/sim/potluck_constructed.gd")
const DEFAULT_RECIPES: String = "res://tools/sim/recipes/supper-constructed.json"


static func make_state(recipe: Dictionary, library: UnitLibrary, config: GameConfig) -> Dictionary:
	var configured: UnitLibrary = FightCapture.library_for(config._values, library)
	var rules: RecruitRules = RecruitRules.create(
		configured, config, UnitPool.create(configured, config)
	)
	var player := PlayerState.new()
	rules.setup_player(player)
	player.round_number = CoreUtil.to_int(recipe["round"])
	player.tier = CoreUtil.to_int(recipe["tier"])
	player.gold = CoreUtil.to_int(recipe["gold"])
	# Stock exists before the settled bodies. Giving it again after Beadle would replay gains.
	for card: String in recipe["items"]:
		rules.give_card(player, card)
	var units: Array = recipe["units"]
	assert(units.size() == BoardGeometry.SLOTS)
	for slot: int in units.size():
		if units[slot] == null:
			continue
		var spec: Dictionary = units[slot]
		var definition: Dictionary = rules.library.get_unit(str(spec["def_id"]))
		assert(CoreUtil.to_int(definition["tier"]) <= player.tier)
		var unit: RecruitUnit = RecruitUnit.make(definition, rules.new_iid())
		assert(Pass3Hedgerow.has(unit, unit.def_id()), "constructed bodies must use native text")
		var stats: Array = spec["stats"]
		unit.perm_attack = CoreUtil.to_int(stats[0]) - unit.base_attack_now()
		unit.perm_health = CoreUtil.to_int(stats[1]) - unit.base_health_now()
		unit.home_slot = slot
		unit.turns_in_slot = CoreUtil.to_int(spec["turns_in_slot"])
		player.board[slot] = unit
	rules.board_changed(player)
	var active: int = 0
	for unit: RecruitUnit in player.board:
		if unit != null:
			active += unit.attack + unit.health
	assert(active == CoreUtil.to_int(recipe["expected_active_stats"]), "active budget mismatch")
	assert(player.larder() == CoreUtil.to_int(recipe["expected_larder_gold"]), "fuel mismatch")
	assert(player.gold == CoreUtil.to_int(recipe["gold"]))
	assert(player.pending_passes.is_empty(), "stock creation must not replay historical Passes")
	var side: Dictionary = {
		"id": recipe["id"],
		"round": player.round_number,
		"tier": player.tier,
		"layout": "blind",
		"board": player.combat_board(),
		"slots": player.combat_slots(),
		"fight_rules": rules.fight_rules(player),
		"hero_effects": [],
		"config": config._values.duplicate(true)
	}
	return {"rules": rules, "player": player, "side": side, "telemetry": telemetry(player)}


static func telemetry(player: PlayerState) -> Dictionary:
	var items: Array = []
	for item: HandItem in player.items:
		items.append({"def_id": item.def_id(), "gold_value": item.gold_value(), "iid": item.iid})
	var clocks: Array = []
	var active: int = 0
	for slot: int in player.board.size():
		var unit: RecruitUnit = player.board[slot]
		if unit == null:
			continue
		active += unit.attack + unit.health
		clocks.append(
			{
				"def_id": unit.def_id(),
				"slot": slot,
				"home_slot": unit.home_slot,
				"turns_in_slot": unit.turns_in_slot
			}
		)
	return {
		"round": player.round_number,
		"gold": player.gold,
		"shop_tier": player.tier,
		"larder_gold": player.larder(),
		"larder_items": items,
		"active_stats": active,
		"belly_stats": 0,
		"belly_contents_by_slot": {},
		"clocks": clocks
	}


func _initialize() -> void:
	var options: Dictionary = {"captures": "", "out": "", "pairs": "16", "recipes": DEFAULT_RECIPES}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		assert(parts.size() == 2 and options.has(parts[0]), "unknown Supper option")
		options[parts[0]] = parts[1]
	assert(str(options["captures"]) != "" and str(options["out"]) != "")
	var pairs: int = str(options["pairs"]).to_int()
	assert(pairs > 0)
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(str(options["recipes"]))
	)
	var recipes: Array = document["boards"]
	var pool: Dictionary = FIXED._hard_sides(str(options["captures"]), [8])
	var candidates: Array = pool[8]
	var chosen: Dictionary = FIXED._median(candidates)
	var opponent: Dictionary = chosen["side"]
	var values: Dictionary = opponent["config"]
	var config: GameConfig = FightCapture.config_for(values)
	assert(config.get_string("pass3_preset") == "B")
	var library: UnitLibrary = UnitLibrary.load_dir()
	var output: FileAccess = FileAccess.open(
		str(options["out"]) + ".fights.jsonl", FileAccess.WRITE
	)
	assert(output != null)
	var reports: Array = []
	for recipe: Dictionary in recipes:
		var state: Dictionary = make_state(recipe, library, config)
		var ours: Dictionary = state["side"]
		ours["config"] = values.duplicate(true)
		var wins: int = 0
		var draws: int = 0
		for replicate: int in pairs:
			var seed_value: int = 282800 + replicate
			for orientation: int in 2:
				var input: Dictionary = FieldCombat.pair_input(
					ours if orientation == 0 else opponent,
					opponent if orientation == 0 else ours,
					seed_value
				)
				var record: Dictionary = FIXED._run(input, library)
				var result: Dictionary = record["result"]
				var winner: int = CoreUtil.to_int(result["winner"])
				wins += 1 if winner == orientation else 0
				draws += 1 if winner < 0 else 0
				var starts: Array = record["combat_start"]
				var start: Dictionary = starts[orientation]
				assert(
					(
						CoreUtil.to_int(start["active_stats"])
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
						"telemetry": state["telemetry"]
					}
				)
				output.store_line(JSON.stringify(record, "", true, true))
		reports.append(
			{
				"recipe": recipe["id"],
				"trials": pairs * 2,
				"wins": wins,
				"draws": draws,
				"losses": pairs * 2 - wins - draws,
				"telemetry": state["telemetry"]
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
					"source": document["source"],
					"paper_reference": document["paper_reference"],
					"assumptions": document["assumptions"],
					"capture_source": options["captures"],
					"capture_sha256": FileAccess.get_sha256(str(options["captures"])),
					"recipe_sha256": FileAccess.get_sha256(str(options["recipes"])),
					"median_opponent": chosen,
					"reports": reports
				},
				"\t",
				true,
				true
			)
			+ "\n"
		)
	)
	print("supper_constructed: %d fixed native fights" % (recipes.size() * pairs * 2))
	quit(0)
