extends Mechanic
## Dormouse Cook: at the end of your turn, if all seven slots hold Mice (the Cook included), each
## of them gains +attack Attack permanently.


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null:
		return
	for held: Unit in ctx.player.board:
		if held == null or not held.def.has_tribe("Mouse"):
			return
	if not ctx.trigger(unit, &"mouse_cook"):
		return
	for held: Unit in ctx.player.board:
		ctx.buff(held, params.num(&"attack"), 0, true, unit)
