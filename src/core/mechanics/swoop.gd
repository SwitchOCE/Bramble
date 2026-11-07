extends Mechanic
## Swoop: attacks the enemy back row while there's anyone in it, from either row.


func attack_target(combat: Combat, unit: CombatUnit, _params: Dictionary) -> CombatUnit:
	var candidates: Array[CombatUnit] = []
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if BoardGeometry.is_back(enemy.slot):
			candidates.append(enemy)
	if candidates.is_empty():
		return null
	combat.trigger(unit, "swoop")
	return candidates[combat.rng.randi_range(0, candidates.size() - 1)]
