extends Mechanic
## Your other Briars have Root 1 (The Old Hedge): an aura granting thorn_root with cost 1 to
## every other Briar on the board. Root's grants combine by the lowest cost, so two Hedges still
## give Root 1, and a Briar with its own Root pays the lower of the two. A Briar that dies after
## the Hedge has died has no Root from it.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or target_slot == source_slot:
		return []
	var target: UnitDef = view.def_at(target_slot)
	if target == null or not target.has_tribe(Compost.BRIAR):
		return []
	return [{"mechanic": "thorn_root", "cost": 1}]
