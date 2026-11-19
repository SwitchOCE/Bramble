extends Mechanic

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
