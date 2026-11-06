extends Mechanic
## Ballooning Spider: in your back row, this attacks the enemy back row while it has units. It has
## to be attacking from the back; in the front row it follows the usual rule.


func attack_target(combat: Combat, unit: CombatUnit, _params: Dictionary) -> CombatUnit:
	if not BoardGeometry.is_back(unit.slot):
		return null
	var candidates: Array[CombatUnit] = []
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if BoardGeometry.is_back(enemy.slot):
			candidates.append(enemy)
	if candidates.is_empty():
		return null
	combat.trigger(unit, "back_strike")
	return candidates[combat.rng.randi_range(0, candidates.size() - 1)]
