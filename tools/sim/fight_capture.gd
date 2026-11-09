class_name FightCapture
extends RefCounted
## Versioned combat boundary records. No recruit-state reconstruction or guessed hero rules.


static func replay(input: Dictionary, library: UnitLibrary) -> Dictionary:
	assert(CoreUtil.to_int(input["version"]) == 1, "unsupported fight capture")
	var config := GameConfig.new()
	for key: String in input["config"]:
		config.set_value(key, input["config"][key])
	var rng := RandomNumberGenerator.new()
	rng.seed = str(input["rng_seed"]).to_int()
	rng.state = str(input["rng_state"]).to_int()
	var combat := Combat.create(library, config, rng)
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
	var tiers: Array[int] = []
	var ids: Array[int] = []
	for tier: Variant in input["tiers"]:
		tiers.append(CoreUtil.to_int(tier))
	for id: Variant in input["player_ids"]:
		ids.append(CoreUtil.to_int(id))
	return combat.run(boards.duplicate(true), tiers, ids, CoreUtil.to_int(input["damage_cap"]))


## Compare serialized forms: JSON numbers read back as floats, but integral values are exact.
static func canonical(value: Variant) -> String:
	return JSON.stringify(_json_numbers(value), "", true, true)


static func _json_numbers(value: Variant) -> Variant:
	if value is float:
		var number: float = value
		if number == floor(number):
			return int(number)
		return number
	if value is Array:
		var items: Array = value
		return items.map(_json_numbers)
	if value is Dictionary:
		var original: Dictionary = value
		var out: Dictionary = {}
		for key: Variant in original:
			out[key] = _json_numbers(original[key])
		return out
	return value


static func record(
	input: Dictionary, result: Dictionary, library: UnitLibrary, combat: Combat
) -> Dictionary:
	var start: Dictionary = {}
	var end: Dictionary = {}
	for event: Dictionary in result["events"]:
		if event["type"] == "combat_start":
			start = event
		elif event["type"] == "combat_end":
			end = event
	var snapshots: Array = []
	for side: int in 2:
		var units: Array = []
		var active_stats: int = 0
		var largest: int = 0
		var views: Array = start["boards"][side]
		var board: Array = input["boards"][side]
		var rules: Dictionary = input["fight_rules"][side]
		for slot: int in views.size():
			if views[slot] == null:
				continue
			var view: Dictionary = views[slot]
			var unit: Dictionary = view.duplicate(true)
			unit["location"] = "egg" if unit["def_id"] == HeldUnits.EGG else "board"
			unit["slot"] = slot
			unit["active"] = true
			units.append(unit)
			var stats: int = CoreUtil.to_int(unit["attack"]) + CoreUtil.to_int(unit["health"])
			active_stats += stats
			largest = maxi(largest, stats)
			var spec: Dictionary = board[slot]
			_held(units, spec, slot, library)
		for nest: Dictionary in rules.get("nests", []):
			var spec: Dictionary = nest["spec"]
			var bird: Dictionary = _reserve(spec, "away", library)
			bird["slot"] = nest["slot"]
			units.append(bird)
		(
			snapshots
			. append(
				{
					"units": units,
					"active_stats": active_stats,
					"largest_share": float(largest) / active_stats if active_stats > 0 else 0.0,
				}
			)
		)
	var outcome: Dictionary = result.duplicate(true)
	outcome.erase("events")
	var survivors: Array = end.get("survivors", [])
	var survivor_units: Array = [[], []]
	for side: int in 2:
		var remaining: Array = survivor_units[side]
		for unit: CombatUnit in combat.units_of(side):
			(
				remaining
				. append(
					{
						"uid": unit.uid,
						"def_id": unit.def_id(),
						"tier": unit.tier(),
						"attack": unit.attack,
						"health": unit.health,
						"own_starting_body": combat.starting_sides.get(unit.uid, -1) == side,
					}
				)
			)
	return {
		"input": input.duplicate(true),
		"combat_start": snapshots,
		"result": outcome,
		"events_sha256": canonical(result["events"]).sha256_text(),
		"survivors": survivors.duplicate(true),
		"survivor_units": survivor_units,
	}


static func matches(recorded: Dictionary, result: Dictionary) -> bool:
	var outcome: Dictionary = result.duplicate(true)
	outcome.erase("events")
	return (
		canonical(outcome) == canonical(recorded["result"])
		and canonical(result["events"]).sha256_text() == str(recorded["events_sha256"])
	)


static func reserves(player: PlayerState, library: UnitLibrary) -> Array:
	var out: Array = []
	for location: String in ["hand", "doorstep", "poached_pending"]:
		var units: Array = player.get(location)
		for unit: RecruitUnit in units:
			out.append(_reserve(unit.combat_spec(), location, library))
	# Include birds without a Nest too; these are absent from fight_rules.nests.
	for entry: Dictionary in player.away:
		if CoreUtil.to_int(entry["nest"]) < 0:
			var bird: RecruitUnit = entry["unit"]
			out.append(_reserve(bird.combat_spec(), "away", library))
	return out


static func _held(out: Array, spec: Dictionary, slot: int, library: UnitLibrary) -> void:
	for held: Dictionary in spec.get("held", []):
		var unit: Dictionary = _reserve(held, "belly", library)
		unit["holder_slot"] = slot
		out.append(unit)
		_held(out, held, slot, library)


static func _reserve(spec: Dictionary, location: String, library: UnitLibrary) -> Dictionary:
	var unit := CombatUnit.make(library.get_unit(str(spec["def_id"])), spec, 0, 0)
	var out: Dictionary = unit.view()
	out["location"] = location
	out["active"] = false
	# Reserve bodies have no board aura or Ring. Their actual entry stats depend on release.
	out["aura_scope"] = "off_board"
	return out
