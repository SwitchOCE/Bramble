extends Mechanic
## Its own Mired enemy grows the wall, including a hit that kills it.


func on_attacked_complete(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit
) -> void:
	if CombatLanes.maker_of(combat, attacker) != unit or not unit.can_gain_permanent():
		return
	var stats: int = CoreUtil.to_int(params.get("stats", 1))
	combat.trigger(unit, "bridge_toad")
	PendingGains.queue(combat, unit, stats, stats, unit, "soak")
