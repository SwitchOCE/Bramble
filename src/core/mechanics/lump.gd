extends Mechanic
## The Great Lump borrows half the away Bird's current stats; golden borrows all.


func recruit_aura(player: PlayerState, unit: RecruitUnit, params: Dictionary) -> Vector2i:
	var entry: Dictionary = player.nest_at(player.board.find(unit))
	if entry.is_empty():
		return Vector2i.ZERO
	var bird: RecruitUnit = entry["unit"]
	return HeldUnits.lump_bonus(bird, CoreUtil.to_int(params.get("factor", 1)))


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	var nest: Dictionary = CombatHeld.nest_at(combat, unit.side, unit.slot)
	if nest.is_empty():
		return Vector2i.ZERO
	var factor: int = CoreUtil.to_int(params.get("factor", 1))
	return Vector2i(
		ceili(CoreUtil.to_int(nest["attack"]) * factor / 2.0),
		ceili(CoreUtil.to_int(nest["health"]) * factor / 2.0)
	)
