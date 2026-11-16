extends Mechanic
## Dame of the Old Sett: while she is on the board, every friendly unit whose type line says
## Knight, herself included, has +N Fury and Overrun. Two Dames add up. Her Fury is borrowed:
## Sword-heir doesn't take it.

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"fury": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or not BadgerRules.is_knight(view.def_at(target_slot)):
		return []
	return [{"mechanic": String(BadgerRules.FURY), "fury": params.num(&"fury")}]


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot >= 0 and BadgerRules.is_knight(view.def_at(target_slot)):
		out.append(&"badger_overrun")
	return out
