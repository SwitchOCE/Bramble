extends Mechanic
## Once a fight: the third kiss restores the frog prince and persists to the recruit board.


func on_enemy_death(
	combat: Combat, unit: CombatUnit, _params: Dictionary, dead: CombatUnit
) -> void:
	if not dead.has_status("mired") or unit.limits.has("kiss"):
		return
	unit.limits["kiss"] = 1
	var count: int = CoreUtil.to_int(unit.counters.get("kisses", 0)) + 1
	unit.counters["kisses"] = count
	combat.trigger(unit, "kiss")
	combat.emit_event("kiss", {"target": unit.uid, "count": count})
	combat.carry_back(unit.side, {"op": "kiss", "iid": unit.iid, "count": count})
	if count >= 3:
		BogFolk.restore_prince(combat, unit)
