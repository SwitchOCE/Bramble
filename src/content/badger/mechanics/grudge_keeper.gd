extends Mechanic
## Grudge-keeper: your Knights have Grudge N. Paid by badger_grudge_pay (the biggest keeper, once
## for each Knight); this aura shows it on the Knights with no Grudge of their own, from the first
## keeper in reading order.

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")
const KEEPER: StringName = &"badger_grudge_keeper"


func param_kinds() -> Dictionary:
	return {"grudge": MechanicParams.Kind.NUMBER}


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0:
		return []
	for slot: int in source_slot:
		if _has(view.def_at(slot), KEEPER):
			return []
	var target: UnitDef = view.def_at(target_slot)
	if not BadgerRules.is_knight(target) or _has(target, BadgerRules.GRUDGE):
		return []
	return [{"mechanic": String(BadgerRules.GRUDGE), "grudge": params.num(&"grudge")}]


static func _has(def: UnitDef, mechanic_id: StringName) -> bool:
	if def == null:
		return false
	for spec: MechanicSpec in def.mechanics:
		if spec.id == mechanic_id:
			return true
	return false
