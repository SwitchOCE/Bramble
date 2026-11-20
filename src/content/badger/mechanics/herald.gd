extends Mechanic
## Herald of the Charge lends Fury to the units in its target slots, of any tribe.

const Badger := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"target_set": MechanicParams.Kind.TEXT, "fury": MechanicParams.Kind.NUMBER}


func text_params(params: MechanicParams) -> Dictionary:
	return Badger.front_target_words(params)


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if not Badger.front_target_slots(view.geometry, source_slot, params).has(target_slot):
		return []
	return [{"mechanic": String(Badger.FURY), "fury": params.num(&"fury")}]
