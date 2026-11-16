extends Mechanic
## Lance Corporal: Order (cost): give the slots in front of this +amount/+amount, permanently,
## empty or not. From the front row there are no slots in front, so it does nothing there (the
## core has no hook to make an ability unusable by position; see the tribe's report).


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD, "amount": MechanicParams.Kind.NUMBER}


func has_ability() -> bool:
	return true


func ability_cost(params: MechanicParams) -> int:
	return params.num(&"cost")


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
	var slots: Array[int] = ctx.geometry().in_front_of(unit.slot)
	if slots.is_empty() or not ctx.trigger(unit, &"pigeon_lance_corporal"):
		return
	for slot: int in slots:
		ctx.slot_buff(slot, params.num(&"amount"), params.num(&"amount"), unit)
