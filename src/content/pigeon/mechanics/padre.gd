extends Mechanic
## Padre: after a friendly unit dies (9.7.2 step 3), give the slot it died in +amount/+amount
## permanently: on the real slot as well as in the fight (SHARED-RULES 38). `limit` a fight, a
## fight count that carries across a return (SHARED-RULES 21), shown as uses left. Only while
## the Padre is alive (the core skips gone listeners).

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
	combat.bridge(unit.side).slot_buff(dead.slot, amount, amount, true, unit)
	combat.show_uses(unit, USED, limit - unit.fight_count(USED), unit)
