extends Mechanic
## Grow the maker that held the bog, including a wall from another tribe given Mire by the Chorus.


func on_enemy_death(combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit) -> void:
	var used: int = CoreUtil.to_int(unit.limits.get("tiddy_mun", 0))
	if not dead.has_status("mired") or used >= CoreUtil.to_int(params.get("limit", 0)):
		return
	unit.limits["tiddy_mun"] = used + 1
	var maker: CombatUnit = CombatLanes.maker_of(combat, dead)
	if maker == null or not maker.on_board or maker.side != unit.side:
		maker = unit
	var stats: int = CoreUtil.to_int(params.get("stats", 0))
	combat.trigger(unit, "tiddy_mun")
	combat.buff(maker, stats, stats, unit, true)
