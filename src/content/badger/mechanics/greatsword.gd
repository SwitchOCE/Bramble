extends Mechanic
## Greatsword Bearer: the chosen front units, any tribe, have Overrun (an aura).

const Badger := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"target_set": MechanicParams.Kind.TEXT}


func text_params(params: MechanicParams) -> Dictionary:
	return Badger.front_target_words(params)


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[StringName]:
	if Badger.front_target_slots(view.geometry, source_slot, params).has(target_slot):
		return [&"badger_overrun"]
	return []
