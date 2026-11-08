extends Mechanic
## Each homecoming deepens the loss, up to three homecomings. Each Whistlers fires.

const BIRDS: String = "Birds"


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var side_rules: Dictionary = combat.side_rules[unit.side]
	var homecomings: int = CoreUtil.to_int(side_rules.get("homecomings", 0))
	var amount: int = mini(3, homecomings) * CoreUtil.to_int(params.get("stats", 1))
	if amount <= 0:
		return
	combat.trigger(unit, "whistlers")
	for ally: CombatUnit in combat.units_of(unit.side):
		if not ally.has_tribe(BIRDS):
			continue
		var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(ally.slot))
		if enemy != null:
			combat.buff(enemy, -amount, -amount, unit)
