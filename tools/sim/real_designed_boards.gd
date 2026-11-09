class_name RealDesignedBoards
extends RefCounted
## Turn explicit authored recruit states into the real game's fight-side schema.
## Current card definitions, configured overlays, Rings, Nests and Bellies stay authoritative.


static func make_board(recipe: Dictionary, library: UnitLibrary, config: GameConfig) -> Dictionary:
	library = FightCapture.library_for(config._values, library)
	var rules := RecruitRules.create(library, config, UnitPool.create(library, config))
	var player := PlayerState.new()
	rules.setup_player(player)
	player.round_number = CoreUtil.to_int(recipe["round"])
	player.tier = CoreUtil.to_int(recipe["tier"])
	assert(player.round_number > 0 and player.tier >= 1 and player.tier <= UnitLibrary.TIERS)
	var units: Array = recipe["units"]
	assert(units.size() == BoardGeometry.SLOTS)
	for slot: int in units.size():
		if units[slot] != null:
			var spec: Dictionary = units[slot]
			player.board[slot] = _unit(spec, rules, player.tier)
	for spec: Dictionary in recipe.get("away", []):
		var unit: RecruitUnit = _unit(spec, rules, player.tier)
		assert(unit.has_tribe("Birds") and unit.flight_turns() > 0)
		var nest: int = CoreUtil.to_int(spec.get("nest", -1))
		assert(nest == -1 or BoardGeometry.is_valid(nest))
		assert(nest < 0 or player.nest_at(nest).is_empty())
		(
			player
			. away
			. append(
				{
					"unit": unit,
					"nest": nest,
					"due": player.round_number + 2,
					"flew": player.round_number,
					"missed_fight": true,
				}
			)
		)
	var bonus: int = CoreUtil.to_int(recipe.get("tribe_bonus", 0))
	if bonus > 0:
		player.tribe_bonuses["Birds"] = bonus
		TribeBonus.sync(player)
	if recipe.has("rings"):
		var rings: Array = recipe["rings"]
		assert(rings.size() == BoardGeometry.SLOTS)
		player.ring_size = CoreUtil.to_float(recipe["ring_size"])
		assert(player.ring_size > 0.0)
		for slot: int in rings.size():
			assert(CoreUtil.to_int(rings[slot]) >= 0)
			Pass3Fairies.add_ring(player, slot, {"count": rings[slot]})
	rules.board_changed(player)
	var board: Array = player.combat_board()
	var total: int = 0
	for spec: Variant in board:
		if spec != null:
			var body: Dictionary = spec
			total += CoreUtil.to_int(body["attack"]) + CoreUtil.to_int(body["health"])
	return {
		"id": recipe["id"],
		"line": recipe["line"],
		"round": player.round_number,
		"tier": player.tier,
		"layout": "blind",
		"board": board,
		"slots": player.combat_slots(),
		"fight_rules": rules.fight_rules(player),
		"hero_effects": [],
		"config": config._values.duplicate(true),
		"reserves": FightCapture.reserves(player, rules.library),
		"design":
		{
			"kind": "real_cards",
			"source": recipe["source"],
			"source_line": recipe.get("source_line", "constructed_payoff"),
			"assumptions": recipe["assumptions"],
			"raw_body_stats": total,
			"stat_definition":
			"raw combat specs exclude slot Rings and combat auras; current fight applies each once",
			"layout_rule":
			"fixed authored slots, identical against every opponent; no scouting or search",
		},
	}


static func _unit(spec: Dictionary, rules: RecruitRules, tier: int) -> RecruitUnit:
	var id: String = str(spec["def_id"])
	var definition: Dictionary = rules.library.get_unit(id)
	assert(not definition.is_empty(), "unknown real card: %s" % id)
	assert(CoreUtil.to_int(definition["tier"]) <= tier, "card is above the constructed tier")
	var unit := RecruitUnit.make(
		definition, rules.new_iid(), CoreUtil.to_bool(spec.get("golden", false))
	)
	if spec.has("stats"):
		var stats: Array = spec["stats"]
		assert(
			stats.size() == 2 and CoreUtil.to_int(stats[0]) >= 0 and CoreUtil.to_int(stats[1]) > 0
		)
		unit.perm_attack = CoreUtil.to_int(stats[0]) - unit.base_attack_now()
		unit.perm_health = CoreUtil.to_int(stats[1]) - unit.base_health_now()
	for held: Dictionary in spec.get("held", []):
		assert(not held.has("held"), "ordinary Bellies cannot nest")
		unit.held.append(_unit(held, rules, tier))
	assert(unit.held.size() <= HeldUnits.belly_size(unit), "constructed Belly is over capacity")
	return unit


static func document(recipes: Dictionary, library: UnitLibrary) -> Dictionary:
	assert(recipes.get("kind", "") == "real_card_recipes")
	var config: GameConfig = GameConfig.full_game()
	var boards: Array = []
	var lines: Dictionary = {}
	for recipe: Dictionary in recipes["boards"]:
		var board: Dictionary = make_board(recipe, library, config)
		boards.append(board)
		var key: String = str(board["round"])
		if not lines.has(key):
			lines[key] = {}
		lines[key][board["line"]] = 1.0
	for key: String in lines:
		var weights: Dictionary = lines[key]
		for line: String in weights:
			weights[line] = 1.0 / weights.size()
	return {
		"version": 1,
		"boards": boards,
		"line_weights": lines,
		"construction": recipes["construction"],
		"line_files_sha256": recipes.get("line_files_sha256", {}),
		"library_rule": "current full_game overlaid library; real PlayerState combat boundary",
	}
