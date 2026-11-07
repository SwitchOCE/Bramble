extends Mechanic
## The Sixpenny Pie: if 2 or more come out when this dies, `gold` next turn.

const AT_LEAST: int = 2


func after_release(combat: Combat, unit: CombatUnit, params: Dictionary, count: int) -> void:
	if count >= AT_LEAST:
		combat.trigger(unit, "pie")
		combat.carry_back(
			unit.side, {"op": "gold_next_turn", "amount": CoreUtil.to_int(params.get("gold", 1))}
		)
