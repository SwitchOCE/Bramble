extends Mechanic
## Creates regular Cousins in hand on recruit.


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func on_recruited(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
	if ctx.trigger(unit, &"mouse_aunt"):
		for _i: int in params.num(&"count"):
			ctx.give_card(&"cousin", unit)
