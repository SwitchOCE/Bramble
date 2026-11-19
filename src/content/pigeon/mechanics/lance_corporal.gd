extends Mechanic
## Lance Corporal, an Active ("{cost}: ..."): give the slots in front of this `amount` Renown,
## permanently, empty or not. From the front row there are no slots in front, so the Active can't
## be used there (ability_usable: not a legal action, and the view shows it dimmed). A golden
## pays the same cost for double the Renown.


func param_kinds() -> Dictionary:
	return {"cost": MechanicParams.Kind.THRESHOLD, "amount": MechanicParams.Kind.NUMBER}


func has_ability() -> bool:
	return true


func ability_cost(params: MechanicParams) -> int:
	return params.num(&"cost")


func ability_usable(_player: PlayerState, unit: Unit, _params: MechanicParams) -> bool:
	return unit != null and unit.slot >= 0 and not _in_front(unit.slot).is_empty()


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, params: MechanicParams) -> void:
	var slots: Array[int] = ctx.geometry().in_front_of(unit.slot)
	if slots.is_empty() or not ctx.trigger(unit, &"pigeon_lance_corporal"):
		return
	for slot: int in slots:
		ctx.add_renown(slot, params.num(&"amount"), unit)


static func _in_front(slot: int) -> Array[int]:
	return BoardGeometry.standard().in_front_of(slot)
