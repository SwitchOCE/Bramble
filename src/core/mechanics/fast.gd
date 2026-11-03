extends Mechanic
## Fast (library entry 56): at End of Turn, if you made no paid refresh this turn the count goes
## up by 1, else back to 0. At `turns` the Feast happens: +`feast_attack`/+`feast_health`
## permanently, and the count resets. The count is shown as `counters.fast`. Only the refresh
## action is built (SPEC changes after the scope review); Break Fast is left out.


func on_end_of_turn(player: PlayerState, unit: RecruitUnit, params: Dictionary) -> void:
	var count: int = 0
	if player.paid_refreshes == 0:
		count = CoreUtil.to_int(unit.counters.get("fast", 0)) + 1
	if count >= CoreUtil.to_int(params.get("turns", 2)):
		unit.attack += CoreUtil.to_int(params.get("feast_attack", 0))
		unit.health += CoreUtil.to_int(params.get("feast_health", 0))
		count = 0
	unit.counters["fast"] = count
