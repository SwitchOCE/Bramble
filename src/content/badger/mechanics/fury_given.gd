extends Mechanic
## Standing, hidden: a unit with Fury given for good (Master-at-Arms' counter) has that much
## Fury, any tribe, in the shop and in fights. A plain copy has no counter, so no Fury.

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[Dictionary]:
	if source_slot >= 0:
		return []
	var kept: int = view.unit_counter(target_slot, BadgerRules.FURY_KEPT)
	if kept <= 0:
		return []
	return [{"mechanic": String(BadgerRules.FURY), "fury": kept}]
