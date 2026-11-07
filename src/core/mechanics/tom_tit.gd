extends Mechanic
## Tom Tit: after this kills a unit, `gold` next turn, once a fight.


func on_damage_dealt(combat: Combat, unit: CombatUnit, params: Dictionary, hit: Hit) -> void:
	if hit.target.health > 0 or hit.amount <= 0 or unit.counters.has("tom_tit"):
		return
	unit.counters["tom_tit"] = 1
	combat.trigger(unit, "tom_tit")
	combat.carry_back(
		unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params.get("gold", 1))}
	)
