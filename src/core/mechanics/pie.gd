extends Mechanic
## The Sixpenny Pie: at most three payments in this unit's life; golden doubles the gold.

const AT_LEAST: int = 2
const PAYMENTS: int = 3
const COUNTER: String = "paid_pie"


func after_release(combat: Combat, unit: CombatUnit, params: Dictionary, count: int) -> void:
	var paid: int = CoreUtil.to_int(unit.counters.get(COUNTER, 0))
	if count < AT_LEAST or paid >= PAYMENTS:
		return
	unit.counters[COUNTER] = paid + 1
	combat.trigger(unit, "pie")
	combat.carry_back(
		unit.side,
		{"op": "pie_payment", "iid": unit.iid, "amount": CoreUtil.to_int(params.get("gold", 1))}
	)
