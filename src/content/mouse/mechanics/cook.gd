extends Mechanic
## Dormouse Cook: at end of turn, give your other Mice +attack Attack permanently (golden: double).


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"mouse_cook"):
		return
	for other: Unit in ctx.player.board_units():
		if other != unit and other.def.has_tribe("Mouse"):
			ctx.buff(other, params.num(&"attack"), 0, true, unit)
