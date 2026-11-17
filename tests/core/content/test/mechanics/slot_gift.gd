extends Mechanic
## A spell aimed at a board slot: that slot gets +amount/+amount.


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func play_target(_params: MechanicParams) -> Target:
	return Target.SLOT


func on_played(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
	if ctx.trigger(unit, &"test_slot_gift"):
		ctx.slot_buff(ctx.target_index, params.num(&"amount"), params.num(&"amount"), unit)
