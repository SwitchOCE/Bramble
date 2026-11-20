extends Mechanic
## Horde-runner. The first Locust sold each turn raises the Tide while this is on the board.

const Locust := preload("res://src/content/locust/lib/locust.gd")
const MECHANIC: StringName = &"locust_tide_on_sell"


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_any_sold(ctx: RecruitContext, unit: Unit, sold: Unit, params: MechanicParams) -> void:
	if unit == null or not sold.def.has_tribe(Locust.TRIBE):
		return
	if unit.turn_counter(MECHANIC) > 0 or not ctx.trigger(unit, MECHANIC):
		return
	ctx.add_turn_counter(unit, MECHANIC, 1, unit)
	ctx.add_counter(Locust.TIDE, params.num(&"amount"), unit)
