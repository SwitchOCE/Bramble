extends Mechanic
## Once a fight: the third kiss restores the frog prince and persists to the recruit board.


func on_enemy_death(combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit) -> void:
	if (
		not dead.has_status("mired")
		or CoreUtil.to_int(unit.limits.get("kiss", 0)) >= CoreUtil.to_int(params.get("limit", 1))
	):
		return
	unit.limits["kiss"] = CoreUtil.to_int(unit.limits.get("kiss", 0)) + 1
	var count: int = CoreUtil.to_int(unit.counters.get("kisses", 0)) + 1
	unit.counters["kisses"] = count
	combat.trigger(unit, "kiss")
	combat.emit_event("kiss", {"target": unit.uid, "count": count})
	combat.carry_back(unit.side, {"op": "kiss", "iid": unit.iid, "count": count})
	if count >= 3:
		BogFolk.restore_prince(combat, unit)
