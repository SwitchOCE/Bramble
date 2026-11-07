extends Mechanic
## Aunt Aspic: End of Turn, what's inside the Oozes in front of this gains these stats.

const OOZES: String = "Oozes"


func on_end_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	var attack: int = CoreUtil.to_int(ctx.params.get("attack", 1))
	var health: int = CoreUtil.to_int(ctx.params.get("health", 1))
	for slot: int in BoardGeometry.in_front_of(ctx.source_slot):
		var ooze: RecruitUnit = ctx.player.board[slot]
		if ooze == null or not ooze.has_tribe(OOZES) or ooze.held.is_empty():
			continue
		ctx.announce("aspic")
		for inner: RecruitUnit in ooze.held:
			ctx.buff(inner, attack, health, "permanent")
