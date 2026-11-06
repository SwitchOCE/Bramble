class_name MechanicRegistry
extends RefCounted
## The mechanic ids that have a script in the core (the "mechanics" section of
## content/schema/effects.json), and how their parameters behave on a golden unit (7.3.5: "number"
## doubles; everything else keeps its value). A unit whose mechanics are not all built plays as
## its plain stats, and UnitLibrary.unbuilt_units() lists it.

const DIR: String = "res://src/core/mechanics/"
## A def's cache of its resolved mechanics.
const COMPILED_KEY: String = "_compiled"

static var _instances: Dictionary = {}


static func is_built(mechanic_id: String) -> bool:
	return EffectSchema.section("mechanics").has(mechanic_id)


## The shared script instance for a built mechanic, or null.
static func get_mechanic(mechanic_id: String) -> Mechanic:
	if not is_built(mechanic_id):
		return null
	if not _instances.has(mechanic_id):
		var script: GDScript = load(DIR + mechanic_id + ".gd") as GDScript
		var instance: Object = script.new()
		_instances[mechanic_id] = instance
	var mechanic: Object = _instances[mechanic_id]
	return mechanic as Mechanic


## A mechanic entry's parameters for a unit, with "number" parameters doubled if golden. A data
## effect ("effect") doubles the number parameters of each of its steps.
static func params_for(entry: Dictionary, golden: bool) -> Dictionary:
	var params: Dictionary = entry.duplicate()
	var mechanic_id: String = str(params.get("id", ""))
	params.erase("id")
	if not golden:
		return params
	if mechanic_id == "effect":
		return _doubled_effect(params)
	var kinds: Dictionary = EffectSchema.mechanic_params(mechanic_id)
	for key: Variant in kinds:
		if str(kinds[key]) == EffectSchema.NUMBER and params.has(key):
			params[key] = CoreUtil.to_int(params[key]) * 2
	return params


## The steps of a data effect: "do" may be one step or a list.
static func steps_of(params: Dictionary) -> Array:
	var value: Variant = params.get("do", [])
	if typeof(value) == TYPE_DICTIONARY:
		return [value]
	var steps: Array = value
	return steps


## A unit def's mechanics, resolved once and cached on the def. Unbuilt ids are left out.
static func compiled(unit_def: Dictionary) -> Array:
	var cached: Variant = unit_def.get(COMPILED_KEY)
	if cached != null:
		var known: Array = cached
		return known
	var out: Array = []
	var entries: Array = unit_def["mechanics"]
	for value: Variant in entries:
		var entry: Dictionary = value
		var one: CompiledMechanic = compile_entry(entry)
		if one != null:
			out.append(one)
	unit_def[COMPILED_KEY] = out
	return out


## One mechanic entry resolved; null if its id isn't built.
static func compile_entry(entry: Dictionary) -> CompiledMechanic:
	var id: String = str(entry.get("id", ""))
	var mechanic: Mechanic = get_mechanic(id)
	if mechanic == null:
		return null
	var one := CompiledMechanic.new()
	one.id = id
	one.mechanic = mechanic
	one.params = params_for(entry, false)
	one.golden_params = params_for(entry, true)
	return one


static func _doubled_effect(params: Dictionary) -> Dictionary:
	var out: Dictionary = params.duplicate(true)
	var doubled: Array = []
	for value: Variant in steps_of(params):
		var step: Dictionary = value
		doubled.append(EffectSchema.doubled_step(step))
	out["do"] = doubled
	return out
