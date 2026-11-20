extends Mechanic
## Start of turn (3.2.1 step 5): gain `amount` gold.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_start_of_turn(
	ctx: RecruitContext, unit: Unit, _report: FightReport, params: MechanicParams
) -> void:
	if ctx.trigger(unit, &"start_turn_gold"):
		ctx.gain_gold(params.num(&"amount"), unit)
