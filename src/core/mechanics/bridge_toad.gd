extends Mechanic
## Scout correctly and get the toll only when the chosen attacker actually crosses the bridge.


func on_attacked_complete(
	combat: Combat, unit: CombatUnit, params: Dictionary, attacker: CombatUnit
) -> void:
	if unit.limits.has("bridge_toad") or CombatLanes.maker_of(combat, attacker) != unit:
		return
	if (
		CoreUtil.to_int(attacker.counters.get("bell_attack", -1))
		!= CoreUtil.to_int(attacker.counters.get("bell_top_attack", -2))
	):
		return
	unit.limits["bridge_toad"] = 1
	combat.trigger(unit, "bridge_toad")
	combat.carry_back(
		unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params.get("gold", 0))}
	)
