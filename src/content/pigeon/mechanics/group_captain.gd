extends Mechanic
## A living Group Captain lends Attack and Sortie to every friendly reservist.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func _covers(view: AuraContext, source_slot: int, target_slot: int) -> bool:
	return source_slot >= 0 and view.reservist_slots.has(target_slot)


func aura(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Vector2i:
	if _covers(view, source_slot, target_slot):
		return Vector2i(params.num(&"attack"), 0)
	return Vector2i.ZERO


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if _covers(view, source_slot, target_slot):
		out.append(&"pigeon_sortie")
	return out
