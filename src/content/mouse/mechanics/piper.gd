extends Mechanic
## Harvest Piper: when played, give your other Mice +attack Attack permanently (golden: double).


func param_kinds() -> Dictionary:
	return {"attack": MechanicParams.Kind.NUMBER}


func on_played(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"mouse_piper"):
		return
	for other: Unit in ctx.player.board_units():
		if other != unit and other.def.has_tribe("Mouse"):
			ctx.buff(other, params.num(&"attack"), 0, true, unit)
