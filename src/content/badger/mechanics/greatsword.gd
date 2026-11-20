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
	var out: Array[StringName] = []
	if source_slot < 0:
		return out
	var targets: Array[int] = (
		view.geometry.front
		if Badger.front_target_set(params) == Badger.FRONT_ROW
		else view.geometry.in_front_of(source_slot)
	)
	if targets.has(target_slot):
		out.append(&"badger_overrun")
	return out
