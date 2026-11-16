extends Mechanic
## Sentry: at the end of your turn, give this slot +amount/+amount (permanent, 3.4.1).


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or unit.slot < 0 or not ctx.trigger(unit, &"pigeon_sentry"):
		return
	ctx.slot_buff(unit.slot, params.num(&"amount"), params.num(&"amount"), unit)
