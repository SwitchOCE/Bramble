class_name CompiledMechanic
extends RefCounted
## One entry of a unit's mechanics list, resolved once: its script and its parameters as a normal
## and as a golden unit. Parameters are shared between units, so scripts must not change them.

var id: String = ""
var mechanic: Mechanic
var params: Dictionary = {}
var golden_params: Dictionary = {}


func params_for(golden: bool) -> Dictionary:
	return golden_params if golden else params
