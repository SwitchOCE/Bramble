extends Mechanic
## Shorten one beside-Nest trip; the Egg stays on its Nest and fights.


func on_end_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	for slot: int in BoardGeometry.adjacent(ctx.source_slot):
		var entry: Dictionary = ctx.player.nest_at(slot)
		if entry.is_empty() or CoreUtil.to_int(entry["due"]) <= ctx.player.round_number + 1:
			continue
		var bird: RecruitUnit = entry["unit"]
		if not bird.has_tribe(HeldUnits.BIRDS):
			continue
		ctx.announce("dunnock")
		HeldUnits.shorten_trip(ctx.player, slot, CoreUtil.to_int(ctx.params.get("turns", 1)))
		return
