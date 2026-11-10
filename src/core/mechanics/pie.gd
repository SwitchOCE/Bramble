extends Mechanic
## A death pays once if at least one held unit actually found room.


func after_release(combat: Combat, unit: CombatUnit, params: Dictionary, count: int) -> void:
	if count <= 0:
		return
	combat.trigger(unit, "pie")
	var gold: int = CoreUtil.to_int(params.get("gold", 1))
	if CoreUtil.to_bool(params.get("pass3", false)):
		gold = count * CoreUtil.to_int(params.get("per_unit", 1))
	combat.carry_back(unit.side, {"op": "gold_next_turn", "amount": gold})
