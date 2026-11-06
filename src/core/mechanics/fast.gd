extends Mechanic
## Fast (library entry 56): at End of Turn, if you made no paid refresh this turn the count goes
## up by 1, else back to 0. At `turns` the Feast happens: +`feast_attack`/+`feast_health`
## permanently, and the count resets. The count is shown as `counters.fast`. Only the refresh
## action is built (SPEC changes after the scope review); Break Fast is left out.


func on_end_of_turn(ctx: RecruitContext) -> void:
	var unit: BoardUnit = ctx.source
	var count: int = 0
	if ctx.player.paid_refreshes == 0:
		count = CoreUtil.to_int(unit.counters.get("fast", 0)) + 1
	if count >= CoreUtil.to_int(ctx.params.get("turns", 2)):
		unit.add_permanent(
			CoreUtil.to_int(ctx.params.get("feast_attack", 0)),
			CoreUtil.to_int(ctx.params.get("feast_health", 0))
		)
		count = 0
	unit.counters["fast"] = count
