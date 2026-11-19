extends Mechanic


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or not ctx.trigger(unit, &"pigeon_sergeant_major"):
		return
	for slot: int in ctx.geometry().slot_count:
		ctx.add_renown(slot, params.num(&"amount"), unit)
