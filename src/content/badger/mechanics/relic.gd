extends Mechanic
## Relic Seeker: at the start of your turn, gain `gold` gold, or `more` if you were outnumbered by
## 3 or more last fight. Only one pays: the one that pays most, the first in reading order on a tie.

const RELIC: StringName = &"badger_relic"
## The count from which a Relic Seeker pays `more`.
const HIGH_COUNT: int = 3


func param_kinds() -> Dictionary:
	return {"gold": MechanicParams.Kind.NUMBER, "more": MechanicParams.Kind.NUMBER}


func on_start_of_turn(
	ctx: RecruitContext, unit: Unit, report: FightReport, params: MechanicParams
) -> void:
	if unit == null or report == null:
		return
	var high: bool = report.outnumbered_by >= HIGH_COUNT
	var pay: int = params.num(&"more") if high else params.num(&"gold")
	if pay <= 0:
		return
	for other: Unit in ctx.player.board_units():
		if other == unit:
			break
		if _gold(other) >= params.num(&"gold"):
			return
	for other: Unit in ctx.player.board_units():
		if other.slot > unit.slot and _gold(other) > params.num(&"gold"):
			return
	if ctx.trigger(unit, RELIC):
		ctx.gain_gold(pay, unit, true)


static func _gold(unit: Unit) -> int:
	var best: int = 0
	for bound: BoundMechanic in unit.mechanics:
		if bound.id == RELIC:
			best = maxi(best, bound.params.num(&"gold"))
	return best
