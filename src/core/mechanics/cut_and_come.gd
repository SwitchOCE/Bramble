extends Mechanic
## Cut-and-Come-Again: every `every` starts of your turn, `copies` plain copies of the last non-Ooze
## inside come to hand. They're Created, hold no pool copy and don't count for triples.

const OOZES: String = "Oozes"


func on_start_of_turn(ctx: RecruitContext) -> void:
	if ctx.source_slot < 0:
		return
	var seen: int = CoreUtil.to_int(ctx.source.counters.get("cut", 0)) + 1
	if seen < CoreUtil.to_int(ctx.params.get("every", 2)):
		ctx.source.counters["cut"] = seen
		return
	var unit: RecruitUnit = ctx.source
	for index: int in range(unit.held.size() - 1, -1, -1):
		if unit.held[index].has_tribe(OOZES):
			continue
		ctx.source.counters["cut"] = 0
		ctx.announce("cut_and_come")
		for _copy: int in CoreUtil.to_int(ctx.params.get("copies", 1)):
			HeldUnits.give_plain_copy(ctx.rules, ctx.player, unit.held[index].def_id())
		return
	ctx.source.counters["cut"] = seen
