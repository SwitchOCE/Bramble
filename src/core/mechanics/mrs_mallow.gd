extends Mechanic


func on_end_of_turn(ctx: RecruitContext) -> void:
	var smallest: RecruitUnit = null
	for slot: int in BoardGeometry.ZIGZAG:
		var unit: RecruitUnit = ctx.player.board[slot]
		if unit == null or unit.has_mechanic_id("shy"):
			continue
		if smallest == null or unit.attack + unit.health < smallest.attack + smallest.health:
			smallest = unit
	if smallest != null:
		ctx.announce("mrs_mallow")
		var stats: int = CoreUtil.to_int(ctx.params["stats"])
		ctx.buff(smallest, stats, stats, "permanent")
