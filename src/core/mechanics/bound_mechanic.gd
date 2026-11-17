class_name BoundMechanic
extends RefCounted
## A mechanic attached to one unit: the shared, stateless script plus that unit's parameters
## (golden already applied). Per-unit state lives on the unit, never on the script.

var id: StringName = &""
var mechanic: Mechanic
var params: MechanicParams
## True when an effect gave it (a gained keyword), not the card's own text.
var granted: bool = false


func _init(
	mechanic_id: StringName, script: Mechanic, bound_params: MechanicParams, is_granted: bool
) -> void:
	id = mechanic_id
	mechanic = script
	params = bound_params
	granted = is_granted
