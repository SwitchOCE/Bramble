extends Mechanic
## The Honorary Treasurer: `per` Attack and Health for each 2 gold your held Acorns are worth, in
## both phases. The hand doesn't change in a fight, so her stats there don't either.

const GOLD_STEP: int = 2


func recruit_aura(player: PlayerState, _unit: RecruitUnit, params: Dictionary) -> Vector2i:
	return _bonus(player.larder(), params)


func aura(combat: Combat, unit: CombatUnit, params: Dictionary) -> Vector2i:
	return _bonus(combat.larder_of(unit.side), params)


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	if _bonus(combat.larder_of(unit.side), params) != Vector2i.ZERO:
		combat.trigger(unit, "larder_stats")


func _bonus(larder: int, params: Dictionary) -> Vector2i:
	@warning_ignore("integer_division")
	var steps: int = larder / GOLD_STEP
	var per: int = CoreUtil.to_int(params.get("per", 0))
	return Vector2i(steps * per, steps * per)
