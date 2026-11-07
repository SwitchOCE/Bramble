extends Mechanic
## Each Take pays the Hunters still present, after quarries have mattered in the exchange.


func on_take(
	combat: Combat, unit: CombatUnit, params: Dictionary, _hunter: CombatUnit, _dead: CombatUnit
) -> void:
	var stats: int = CoreUtil.to_int(params["stats"])
	combat.trigger(unit, "laird")
	for hunter: CombatUnit in combat.units_of(unit.side):
		if hunter.has_tribe("Hunters"):
			combat.buff(hunter, stats, stats, unit)
