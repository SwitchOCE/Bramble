extends Mechanic
## Field Marshal: an aura while this is on the board. Each Medal on a friendly Pigeon gives
## `extra`/`extra` more (borrowed), so a Medal is worth +4/+4, or +6/+6 from a golden; the
## Medal's own +2/+2 stays the unit's. And friendly Decorated Pigeons have Stiff Upper Lip.

const Medals := preload("res://src/content/pigeon/lib/medals.gd")


func param_kinds() -> Dictionary:
	return {"extra": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Vector2i:
	if source_slot < 0 or not Medals.is_pigeon(view, target_slot):
		return Vector2i.ZERO
	var gain: int = view.unit_counter(target_slot, Medals.MEDAL) * params.num(&"extra")
	return Vector2i(gain, gain)


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot < 0:
		return out
	if Medals.is_pigeon(view, target_slot) and Medals.decorated(view, target_slot):
		out.append(&"pigeon_stiff_upper_lip")
	return out
