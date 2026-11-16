extends Mechanic
## Greatsword Bearer: the units in front of this, any tribe, have Overrun (an aura).


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot >= 0 and view.geometry.in_front_of(source_slot).has(target_slot):
		out.append(&"badger_overrun")
	return out
