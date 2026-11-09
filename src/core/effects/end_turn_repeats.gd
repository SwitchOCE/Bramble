class_name EndTurnRepeats
extends RefCounted
## Doublers add one firing each; they do not recursively double each other.


static func count(ctx: RecruitContext) -> int:
	if ctx.trigger != "end_of_turn":
		return 1
	var total: int = 1
	for unit: RecruitUnit in ctx.player.board:
		if unit == null:
			continue
		for compiled: CompiledMechanic in MechanicRegistry.compiled(unit.def):
			if compiled.id == "end_turn_doubler":
				total += 2 if unit.golden else 1
		for grant: Dictionary in unit.grants:
			var entry: Dictionary = grant["entry"]
			if str(entry.get("id", "")) == "end_turn_doubler":
				total += 2 if CoreUtil.to_bool(grant.get("golden", false)) else 1
	return total
