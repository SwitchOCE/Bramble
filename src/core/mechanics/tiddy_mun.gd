extends Mechanic
## Mired attackers grow the friendly unit they hit, even on a lethal exchange.


func after_attacked(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit, defender: CombatUnit
) -> void:
	var used: int = CoreUtil.to_int(unit.limits.get("tiddy_mun", 0))
	if (
		defender.side != unit.side
		or attacker.side == unit.side
		or not attacker.has_status("mired")
		or used >= CoreUtil.to_int(params.get("limit", 0))
	):
		return
	unit.limits["tiddy_mun"] = used + 1
	var stats: int = CoreUtil.to_int(params.get("stats", 0))
	combat.trigger(unit, "tiddy_mun")
	combat.buff(defender, stats, stats, unit, true)
