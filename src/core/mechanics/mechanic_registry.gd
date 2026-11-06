class_name MechanicRegistry
extends RefCounted
## The mechanic ids that have a script in the core (SPEC section 4), and how their parameters
## behave on a golden unit (4.4: "number" doubles; everything else keeps its value). A unit
## whose mechanics are not all built plays as its plain stats, and
## UnitLibrary.unbuilt_units() lists it.

const DIR: String = "res://src/core/mechanics/"
## Built mechanic id -> {parameter: kind}.
const BUILT: Dictionary = {
	"nightshade_mark": {"count": "number"},
	"nightshade_on_hit": {},
	"bristle": {"n": "number"},
	"death_summon": {"unit": "unit", "count": "threshold"},
	"hunker": {},
	"survive_buff_behind": {"attack": "number"},
	"shell": {"n": "threshold"},
	"mire": {},
	"bystander": {"attack": "number", "health": "number"},
	"grant_first_bite_in_front": {},
	"quick_while_undamaged": {},
	"peck": {"strikes": "threshold"},
	"on_attack_buff_tribe": {"tribe": "tribe", "attack": "number"},
	"swarm": {},
	"both_ends": {"attack": "number", "health": "number", "prick": "number"},
	"bide_slumber": {"attack": "number", "health": "number"},
	"whistle": {},
	"mark": {"damage": "number"},
	"fast":
	{
		"action": "string",
		"turns": "threshold",
		"feast_attack": "number",
		"feast_health": "number",
	},
	"stance": {"back_attack": "number", "back_health": "number"},
	"stance_back_ping": {"damage": "number"},
	"buff_in_front": {"attack": "number"},
	"rival": {},
	"bolt": {"unit": "unit"},
	"solitary": {},
	"solitary_kill_buff": {"attack": "number", "health": "number"},
	"both_ends_rally": {"attack": "number"},
	"mark_focus": {},
	"rotate": {"forward_attack": "number"},
	"rotate_both": {"attack": "number", "health": "number"},
}

static var _instances: Dictionary = {}


static func is_built(mechanic_id: String) -> bool:
	return BUILT.has(mechanic_id)


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


## A mechanic entry's parameters for a unit, with "number" parameters doubled if golden.
static func params_for(entry: Dictionary, golden: bool) -> Dictionary:
	var params: Dictionary = entry.duplicate()
	params.erase("id")
	var kinds: Dictionary = BUILT.get(str(entry.get("id", "")), {})
	if golden:
		for key: Variant in kinds:
			if str(kinds[key]) == "number" and params.has(key):
				params[key] = CoreUtil.to_int(params[key]) * 2
	return params
