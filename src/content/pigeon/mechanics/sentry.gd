extends Mechanic

const KEY: StringName = &"supply:pigeon_sentry"


func param_kinds() -> Dictionary:
	return {"supply": MechanicParams.Kind.THRESHOLD, "amount": MechanicParams.Kind.NUMBER}


func on_end_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or unit.slot < 0 or unit.counter(KEY) <= 0:
		return
	if ctx.trigger(unit, &"pigeon_sentry"):
		unit.counters[KEY] = unit.counter(KEY) - 1
		ctx.add_renown(unit.slot, params.num(&"amount"), unit)
