extends Mechanic
## Relic Seeker: after each fight, gain N gold for every 2 units you were outnumbered by, win or
## lose. Only one Relic Seeker pays: the one that pays most, the first in reading order on a tie.
## It was on the board in the fight, since the board doesn't change between the fight and this.
## The gold is the player's now; gold carries over, so it is spent next turn.

const RELIC: StringName = &"badger_relic"


func param_kinds() -> Dictionary:
	return {"gold": MechanicParams.Kind.NUMBER}


func after_fight(
	ctx: RecruitContext, unit: Unit, report: FightReport, params: MechanicParams
) -> void:
	if unit == null:
		return
	var pay: int = floori(report.outnumbered_by / 2.0) * params.num(&"gold")
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
