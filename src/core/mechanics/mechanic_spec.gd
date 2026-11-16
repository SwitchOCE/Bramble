class_name MechanicSpec
extends RefCounted
## A card's use of a mechanic: its id and its parsed parameters.

var id: StringName = &""
var params: MechanicParams


func _init(mechanic_id: StringName = &"", parsed: MechanicParams = null) -> void:
	id = mechanic_id
	params = parsed if parsed != null else MechanicParams.new()
