extends Mechanic
## Stance (library entry 43): the unit file's stats are its front side; in the back row it has
## `back_attack`/`back_health` instead. An aura, so it switches at once if it changes row.


func aura(_combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	if not BoardGeometry.is_back(unit.slot):
		return Vector2i.ZERO
	var factor: int = 2 if unit.golden else 1
	var front_attack: int = unit.def["attack"]
	var front_health: int = unit.def["health"]
	return Vector2i(
		CoreUtil.to_int(params.get("back_attack", 0)) - front_attack * factor,
		CoreUtil.to_int(params.get("back_health", 0)) - front_health * factor
	)
