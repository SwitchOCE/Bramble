extends Mechanic
## An aura that sees the fight: +amount Attack to itself while outnumbered.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Vector2i:
	if source_slot == target_slot and view.outnumbered_by > 0:
		return Vector2i(params.num(&"amount"), 0)
	return Vector2i.ZERO
