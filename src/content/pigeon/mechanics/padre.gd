extends Mechanic
## Padre, Charge `limit`: after a friendly unit dies (9.7.2 step 3), give the slot it died in
## `amount` Renown. It goes on the real slot and counts from the next fight, not this one
## (FightSide.add_renown). Charge refills each fight and is a fight count that carries across a
## return, shown as uses left. Only while the Padre is alive (the core skips gone listeners).
## A golden doubles the Renown, not the Charge.

const USED: StringName = &"pigeon_padre_uses"


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER, "limit": MechanicParams.Kind.THRESHOLD}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or dead == null or dead.side != unit.side or dead == unit:
		return
	var limit: int = params.num(&"limit")
	if unit.fight_count(USED) >= limit or not combat.trigger(unit, &"pigeon_padre"):
		return
	unit.add_fight_count(USED)
	var amount: int = params.num(&"amount")
	combat.bridge(unit.side).add_renown(dead.slot, amount, unit)
	combat.show_uses(unit, USED, limit - unit.fight_count(USED), unit)
