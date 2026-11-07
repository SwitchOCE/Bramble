extends Mechanic
## Bird and Egg positions determine which enemies lose stats. Each Whistlers fires.
## The full-flock cap curve proved the old count-sized loss excessive; production gives 1/1.

const BIRDS: String = "Birds"


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var amount: int = CoreUtil.to_int(params.get("stats", 1))
	if amount <= 0:
		return
	combat.trigger(unit, "whistlers")
	for ally: CombatUnit in combat.units_of(unit.side):
		if not ally.has_tribe(BIRDS) and ally.def_id() != HeldUnits.EGG:
			continue
		var enemy: CombatUnit = combat.unit_at(1 - unit.side, BoardGeometry.across(ally.slot))
		if enemy != null:
			combat.buff(enemy, -amount, -amount, unit)
