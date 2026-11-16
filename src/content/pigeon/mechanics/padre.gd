extends Mechanic
## Padre: after a friendly unit dies (9.7.2 step 3), give the slot it died in +amount/+amount
## permanently: on the real slot as well as in the fight (SHARED-RULES 38). `limit` a fight.
## Only while the Padre is alive (the core skips gone listeners).

const USED: StringName = &"pigeon_padre_used"


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER, "limit": MechanicParams.Kind.THRESHOLD}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or dead == null or dead.side != unit.side or dead == unit:
		return
	if unit.state_int(USED) >= params.num(&"limit"):
		return
	if not combat.trigger(unit, &"pigeon_padre"):
		return
	unit.set_state(USED, unit.state_int(USED) + 1)
	var amount: int = params.num(&"amount")
	combat.bridge(unit.side).slot_buff(dead.slot, amount, amount, true, unit)
