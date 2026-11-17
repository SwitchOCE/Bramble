extends Mechanic
## Kettle-drummer: your back-row units (B1 to B3, any tribe, itself included) attack twice, as
## an aura giving the core's windfury. A Spoon Catapult still Ambushes only once; a unit that
## cannot attack still cannot.


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, _source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	if view.geometry.is_back(target_slot) and view.def_at(target_slot) != null:
		return [&"windfury"]
	return []
