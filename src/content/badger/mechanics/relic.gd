extends Mechanic
## Relic Seeker pays a base amount plus gold per unit outnumbering you last fight.
## Only the highest payout applies, with ties going to the first slot.

const RELIC: StringName = &"badger_relic"


func param_kinds() -> Dictionary:
	return {"gold": MechanicParams.Kind.NUMBER, "more": MechanicParams.Kind.NUMBER}


func on_start_of_turn(
	ctx: RecruitContext, unit: Unit, report: FightReport, params: MechanicParams
) -> void:
	if unit == null or report == null:
		return
	var pay: int = _payout(params, report.outnumbered_by)
	if pay <= 0:
		return
	for other: Unit in ctx.player.board_units():
		for bound: BoundMechanic in other.mechanics:
			if bound.id != RELIC:
				continue
			var other_pay: int = _payout(bound.params, report.outnumbered_by)
			if other_pay > pay or (other_pay == pay and other.slot < unit.slot):
				return
	if ctx.trigger(unit, RELIC):
		ctx.pay_fight_reward(ctx.gain_gold.bind(pay, unit))


static func _payout(params: MechanicParams, outnumbered_by: int) -> int:
	return params.num(&"gold") + params.num(&"more") * outnumbered_by
