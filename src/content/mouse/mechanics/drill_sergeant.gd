extends Mechanic
## Proposal: a golden Drill-sergeant grants Pile on 2.
## It reaches all its neighbours (8.2.3), as the pitch costed it ("up to 4 free hits a fight").


func param_kinds() -> Dictionary:
	return {"grant": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	var target: UnitDef = view.def_at(target_slot)
	if target == null or not target.has_tribe("Mouse") or source_slot < 0:
		return []
	if not view.geometry.neighbours(source_slot).has(target_slot):
		return []
	return [{"mechanic": "mouse_pile_on", "pile_on": params.num(&"grant")}]
