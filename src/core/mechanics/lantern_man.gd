extends Mechanic
## This is a live aura: losing a Mired enemy removes its share of Attack immediately.


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	var count: int = 0
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if enemy.has_status("mired"):
			count += 1
	return Vector2i(count * CoreUtil.to_int(params.get("attack", 3)), 0)
