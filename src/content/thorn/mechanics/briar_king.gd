extends Mechanic
## Your other front-row Briars have Grow N (Briar King): an aura on Briars in F1 to F4, not this
## unit, adding to any Grow they have.

const Compost := preload("res://src/content/thorn/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or target_slot == source_slot or not view.geometry.is_front(target_slot):
		return []
	var target: UnitDef = view.def_at(target_slot)
	if target == null or not target.has_tribe(Compost.BRIAR):
		return []
	return [{"mechanic": "thorn_grow", "amount": params.num(&"amount")}]
