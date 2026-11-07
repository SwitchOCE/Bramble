extends Mechanic


func on_take(
	combat: Combat, unit: CombatUnit, params: Dictionary, _hunter: CombatUnit, _dead: CombatUnit
) -> void:
	var stats: int = CoreUtil.to_int(params["stats"])
	combat.trigger(unit, "glutton")
	combat.buff(unit, stats, stats, unit)
