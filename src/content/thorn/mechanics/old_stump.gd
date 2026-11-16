extends Mechanic
## When this dies, summon a copy of the highest-tier unit in your Compost (Old Stump; a golden:
## the 2 highest). A plain, non-golden copy for this fight, into this unit's slot first. The
## entry stays in the Compost, marked copied for this fight. With nothing left to copy, or no
## room, nothing happens and no entry is marked. In the shop (eaten) it does nothing.

const Compost := preload("res://src/content/thorn/compost_rules.gd")


func param_kinds() -> Dictionary:
	return {"copies": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var side: FightSide = combat.bridge(unit.side)
	if Compost.next_copy(side).is_empty() or not combat.trigger(unit, &"thorn_old_stump"):
		return
	for _i: int in params.num(&"copies"):
		var entry: Dictionary = Compost.next_copy(side)
		if entry.is_empty():
			return
		var made: CombatUnit = combat.summon(
			unit.side, StringName(str(entry["id"])), unit.slot, true, unit
		)
		if made == null:
			return
		Compost.mark_copied(side, entry, unit)
