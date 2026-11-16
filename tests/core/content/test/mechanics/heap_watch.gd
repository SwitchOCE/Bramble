extends Mechanic
## Whenever an entry goes into your heap, gain +1 Attack permanently.


func on_heap_added(
	ctx: RecruitContext,
	unit: Unit,
	_heap: StringName,
	_card_id: StringName,
	_params: MechanicParams
) -> void:
	if unit != null and ctx.trigger(unit, &"test_heap_watch"):
		ctx.buff(unit, 1, 0, true, unit)
