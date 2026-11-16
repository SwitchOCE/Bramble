extends Mechanic
## Your front-row Briars have +N Thorns for every 3 units in your Compost (Holly Knight). An
## aura, recalculated whenever the Compost or the board changes; it adds to printed Thorns and
## counts this unit too when it stands in front. Two Holly Knights add up.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or not view.geometry.is_front(target_slot):
		return []
	var target: UnitDef = view.def_at(target_slot)
	if target == null or not target.has_tribe(Compost.BRIAR):
		return []
	@warning_ignore("integer_division")
	var thorns: int = params.num(&"amount") * (view.heap_size(Compost.HEAP) / 3)
	if thorns <= 0:
		return []
	return [{"mechanic": "thorn_thorns", "amount": thorns}]
