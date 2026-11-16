extends Mechanic
## Aura: the units next to this have +1 Thorns (a mechanic with a parameter).


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or not view.geometry.adjacent(source_slot).has(target_slot):
		return []
	return [{"mechanic": "test_thorns", "amount": 1}]
