extends Mechanic
## The units in front of this have Grow N (Ivy Climber): an aura from a back-row slot onto the
## two front slots it sits between (8.2.1), whatever the units' tribe. In the front row it does
## nothing.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or not view.geometry.in_front_of(source_slot).has(target_slot):
		return []
	return [{"mechanic": "thorn_grow", "amount": params.num(&"amount")}]
