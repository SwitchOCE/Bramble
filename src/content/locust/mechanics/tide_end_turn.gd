extends Mechanic
## Prophet of the Dust. At the end of your turn (3.4.1), Tide +`amount`.

const Locust := preload("res://src/content/locust/locust.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit != null and ctx.trigger(unit, &"locust_tide_end_turn"):
		ctx.add_counter(Locust.TIDE, params.num(&"amount"), unit)
