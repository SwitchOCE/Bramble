extends Mechanic
## Your other Briars have Root 1 (The Old Hedge): an aura granting thorn_root with cost 1 to
## every other Briar on the board. Root's grants combine by lowest cost and highest cap.
## A Briar with its own Root pays the lowest cost it can still use. A Briar that dies after
## the Hedge has died has no Root from it.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")
const Root := preload("res://src/content/thorn/mechanics/root.gd")


func param_kinds() -> Dictionary:
	return {"charges": MechanicParams.Kind.NUMBER}


func text_params(params: MechanicParams) -> Dictionary:
	return Root.root_words(params.num(&"charges"))


func has_aura() -> bool:
	return true


func aura_grants(
	view: AuraContext, source_slot: int, target_slot: int, params: MechanicParams
) -> Array[Dictionary]:
	if source_slot < 0 or target_slot == source_slot:
		return []
	var target: UnitDef = view.def_at(target_slot)
	if target == null or not target.has_tribe(Compost.BRIAR):
		return []
	var grant: Dictionary = {"mechanic": "thorn_root", "cost": 1}
	var charges: int = params.num(&"charges")
	if charges != 1:
		grant["charges"] = charges
	return [grant]
