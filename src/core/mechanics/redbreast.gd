extends Mechanic
## Mr Redbreast: has these stats for each Nest you have.


func recruit_aura(player: PlayerState, _unit: RecruitUnit, params: Dictionary) -> Vector2i:
	return _per_nest(params) * player.nest_count()


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	return _per_nest(params) * CombatHeld.nest_count(combat, unit.side)


static func _per_nest(params: Dictionary) -> Vector2i:
	return Vector2i(CoreUtil.to_int(params.get("attack", 1)), CoreUtil.to_int(params.get("health", 1)))
