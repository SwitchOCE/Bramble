extends Mechanic
## Your other Briars have Root 1 (The Old Hedge): an aura giving thorn_hedge_root to every other
## Briar on the board. A Briar that dies after the Hedge has died has no Root from it.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func has_aura() -> bool:
	return true


func aura_keywords(
	view: AuraContext, source_slot: int, target_slot: int, _params: MechanicParams
) -> Array[StringName]:
	var out: Array[StringName] = []
	if source_slot < 0 or target_slot == source_slot:
		return out
	var target: UnitDef = view.def_at(target_slot)
	if target != null and target.has_tribe(Compost.BRIAR):
		out.append(&"thorn_hedge_root")
	return out
