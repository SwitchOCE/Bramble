extends Mechanic
## A failed attempt on a full board consumes no summon; at most two Peatlings actually rise.


func on_enemy_death(combat: Combat, unit: CombatUnit, params: Dictionary, dead: CombatUnit) -> void:
	var used: int = CoreUtil.to_int(unit.limits.get("peat_king", 0))
	if not dead.has_status("mired") or used >= CoreUtil.to_int(params.get("limit", 0)):
		return
	var slot: int = combat.named_slot(unit.side, "nearest_empty", unit.slot)
	if slot < 0:
		combat.emit_event(
			"no_room", {"uid": unit.uid, "def_id": "peatling", "mechanic": "peat_king"}
		)
		return
	unit.limits["peat_king"] = used + 1
	combat.trigger(unit, "peat_king")
	combat.summon_into("peatling", unit.golden, unit.side, slot, unit)
