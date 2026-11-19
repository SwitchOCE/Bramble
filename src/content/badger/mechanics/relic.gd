extends Mechanic
## Relic Seeker: after each fight, gain `gold` gold, or `more` if you were outnumbered by 3 or
## more, win or lose (a pass 1 proposal, 19 Nov; it paid gold for every 2 units). Only one
## Relic Seeker pays: the one that pays most, the first in reading order on a tie. It was on the
## board in the fight, since the board doesn't change between the fight and this. The gold is
## the player's now; gold carries over, so it is spent next turn.

const RELIC: StringName = &"badger_relic"
## The count from which a Relic Seeker pays `more`.
const HIGH_COUNT: int = 3


func param_kinds() -> Dictionary:
	return {"gold": MechanicParams.Kind.NUMBER, "more": MechanicParams.Kind.NUMBER}


func after_fight(
	ctx: RecruitContext, unit: Unit, report: FightReport, params: MechanicParams
) -> void:
	if unit == null:
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
		ctx.gain_gold(pay, unit)


static func _gold(unit: Unit) -> int:
	var best: int = 0
	for bound: BoundMechanic in unit.mechanics:
		if bound.id == RELIC:
			best = maxi(best, bound.params.num(&"gold"))
	return best
