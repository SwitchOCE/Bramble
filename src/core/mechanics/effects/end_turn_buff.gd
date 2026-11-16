extends Mechanic
## End of Turn (3.4.1 step 1): give a random other friendly unit +attack/+health permanently.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER, "health": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	var target: Unit = ctx.random_of(ctx.select(unit, "others"))
	if target == null or not ctx.trigger(unit, &"end_turn_buff"):
		return
	ctx.buff(target, params.num(&"attack"), params.num(&"health"), true, unit)
