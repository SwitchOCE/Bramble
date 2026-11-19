extends Mechanic
## Proposal: a golden Drill-sergeant grants Pile on 2.


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
	if not view.geometry.adjacent(source_slot).has(target_slot):
		return []
	return [{"mechanic": "mouse_pile_on", "pile_on": params.num(&"grant")}]
