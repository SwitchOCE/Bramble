extends Mechanic
## When played (7.2.3) or cast: give units +attack/+health permanently. `to` is "target" (a
## chosen friendly unit) or a selector name (Selectors), relative to this unit.


func param_kinds() -> Dictionary:
	return {
		"attack": MechanicParams.Kind.NUMBER,
		"health": MechanicParams.Kind.NUMBER,
		"to": MechanicParams.Kind.TEXT,
	}


func play_target(params: MechanicParams) -> Target:
	return Target.FRIENDLY_UNIT if params.text(&"to") == "target" else Target.NONE


func on_played(ctx: RecruitContext, unit: Unit, target: Unit, params: MechanicParams) -> void:
	var targets: Array[Unit] = []
	if params.text(&"to") == "target":
		if target != null:
			targets.append(target)
	else:
		targets = ctx.select(unit, params.text(&"to"))
	if targets.is_empty() or not ctx.trigger(unit, &"play_buff"):
		return
	for each: Unit in targets:
		ctx.buff(each, params.num(&"attack"), params.num(&"health"), true, unit)
