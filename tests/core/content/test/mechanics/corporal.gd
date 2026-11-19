extends Mechanic
## Order (1): give the slots in front of this 1 Renown. Usable only where there are slots in front
## (the back row): ability_usable.


func has_ability() -> bool:
	return true


func ability_cost(_params: MechanicParams) -> int:
	return 1


func ability_usable(player: PlayerState, unit: Unit, _params: MechanicParams) -> bool:
	return player != null and unit.slot >= 0 and unit.slot >= 4


func on_ability(ctx: RecruitContext, unit: Unit, _target: Unit, _params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"test_corporal"):
		return
	for slot: int in ctx.geometry().in_front_of(unit.slot):
		ctx.add_renown(slot, 1, unit)
