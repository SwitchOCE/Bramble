extends Mechanic
## The Great Lump: on a Nest, this also has the card stats of the bird away (golden: twice).


func recruit_aura(player: PlayerState, unit: RecruitUnit, params: Dictionary) -> Vector2i:
	var entry: Dictionary = player.nest_at(player.board.find(unit))
	if entry.is_empty():
		return Vector2i.ZERO
	var bird: RecruitUnit = entry["unit"]
	return (
		Vector2i(bird.base_attack_now(), bird.base_health_now())
		* CoreUtil.to_int(params.get("factor", 1))
	)


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	var nest: Dictionary = CombatHeld.nest_at(combat, unit.side, unit.slot)
	if nest.is_empty():
		return Vector2i.ZERO
	return (
		Vector2i(CoreUtil.to_int(nest["attack"]), CoreUtil.to_int(nest["health"]))
		* CoreUtil.to_int(params.get("factor", 1))
	)
