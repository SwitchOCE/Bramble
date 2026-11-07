extends Mechanic


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var quarry: CombatUnit = CombatLanes.by_uid(combat, unit.quarry)
	if quarry != null and quarry.attack > unit.attack:
		combat.trigger(unit, "sable")
		combat.buff(unit, CoreUtil.to_int(params["attack"]), 0, unit)
