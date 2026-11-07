extends Mechanic
## Credit the actual killing hit, including a simultaneous trade; mud alone doesn't pay this frog.


func on_enemy_death(combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit) -> void:
	if dead.has_status("mired") and dead.killed_by == unit.uid:
		combat.trigger(unit, "snap_kill")
		combat.carry_back(
			unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params.get("gold", 0))}
		)
