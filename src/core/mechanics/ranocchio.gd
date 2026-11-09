extends Mechanic
## One completed attack against a Mired target grows the tenor permanently.


func after_attacked(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit, defender: CombatUnit
) -> void:
	var used: int = CoreUtil.to_int(unit.limits.get("ranocchio", 0))
	if (
		attacker != unit
		or not defender.has_status("mired")
		or used >= CoreUtil.to_int(params.get("limit", 1))
	):
		return
	unit.limits["ranocchio"] = used + 1
	var stats: int = CoreUtil.to_int(params.get("stats", 1))
	combat.trigger(unit, "ranocchio")
	combat.buff(unit, stats, stats, unit, true)
