extends Mechanic
## Flight length is set in HeldUnits.send_south; growth remains on the Bird after it returns.


func on_end_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	var announced: bool = false
	for slot: int in BoardGeometry.adjacent(ctx.source_slot):
		var entry: Dictionary = ctx.player.nest_at(slot)
		if entry.is_empty():
			continue
		var bird: RecruitUnit = entry["unit"]
		if not bird.has_tribe(HeldUnits.BIRDS):
			continue
		if not announced:
			ctx.announce("cuckoo")
			announced = true
		ctx.buff(
			bird,
			CoreUtil.to_int(ctx.params.get("attack", 2)),
			CoreUtil.to_int(ctx.params.get("health", 2)),
			"permanent"
		)
