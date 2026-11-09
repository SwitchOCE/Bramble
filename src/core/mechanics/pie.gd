extends Mechanic
## A death pays once if at least one held unit actually found room.


func after_release(combat: Combat, unit: CombatUnit, params: Dictionary, count: int) -> void:
	if count <= 0:
		return
	combat.trigger(unit, "pie")
	combat.carry_back(
		unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params.get("gold", 1))}
	)
