extends Mechanic


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or unit.slot < 0:
		return
	var row: Array[int] = ctx.geometry().row_of(unit.slot)
	for slot: int in row:
		var here: Unit = ctx.player.board[slot]
		if here == null or not here.def.has_tribe("Pigeon"):
			return
	if not ctx.trigger(unit, &"pigeon_colour_sergeant"):
		return
	for slot: int in row:
		ctx.add_renown(slot, params.num(&"amount"), unit)
