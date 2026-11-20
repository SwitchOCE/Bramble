extends Mechanic
## Bridge, lasting unit state: at the start of the next turn, a mark (two if it survived), and +1/+1 for
## good per mark earned.


func on_start_of_turn(
	ctx: RecruitContext, unit: Unit, report: FightReport, _params: MechanicParams
) -> void:
	if report == null or unit == null or not ctx.trigger(unit, &"test_mark_after_fight"):
		return
	var marks: int = 2 if report.survived(unit) else 1
	ctx.add_unit_counter(unit, &"test_mark", marks, unit)
	ctx.buff(unit, marks, marks, true, unit)
