extends Mechanic


func on_take(
	combat: Combat, unit: CombatUnit, params: Dictionary, hunter: CombatUnit, _dead: CombatUnit
) -> void:
	if unit != hunter or (params["back_only"] and not BoardGeometry.is_back(unit.slot)):
		return
	combat.trigger(unit, "take_gold")
	combat.carry_back(
		unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params["gold"])}
	)
