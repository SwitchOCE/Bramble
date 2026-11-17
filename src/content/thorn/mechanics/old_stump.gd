extends Mechanic
## When this dies, summon a copy of the highest-tier unit in your Compost (Old Stump; a golden:
## the 2 highest). A plain, non-golden copy for this fight, into this unit's slot first. The
## entry stays in the Compost, marked used for this fight (FightSide.heap_use_highest), so each
## entry comes out once a fight. With nothing left to copy, or no room, nothing happens and no
## entry is marked. In the shop (eaten) it does nothing.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"copies": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var side: FightSide = combat.bridge(unit.side)
	if side.heap_unused(Compost.HEAP) <= 0 or not Compost.has_room(combat, unit.side):
		return
	if not combat.trigger(unit, &"thorn_old_stump"):
		return
	for _i: int in params.num(&"copies"):
		if side.heap_unused(Compost.HEAP) <= 0 or not Compost.has_room(combat, unit.side):
			return
		var entry: Dictionary = side.heap_use_highest(Compost.HEAP, unit)
		combat.summon(unit.side, StringName(str(entry["id"])), unit.slot, true, unit)
