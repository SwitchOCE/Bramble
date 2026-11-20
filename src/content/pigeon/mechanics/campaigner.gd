extends Mechanic


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER, "survived": MechanicParams.Kind.NUMBER}


func on_start_of_turn(
	ctx: RecruitContext, unit: Unit, report: FightReport, params: MechanicParams
) -> void:
	if (
		report != null
		and unit != null
		and unit.slot >= 0
		and ctx.trigger(unit, &"pigeon_campaigner")
	):
		ctx.add_renown(
			unit.slot, params.num(&"survived" if report.survived(unit) else &"amount"), unit
		)
