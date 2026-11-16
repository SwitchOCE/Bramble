extends Mechanic
## Bridge, lasting unit state: after each fight, a medal (two if it survived), and +1/+1 for
## good per medal earned.


func after_fight(
	ctx: RecruitContext, unit: Unit, report: FightReport, _params: MechanicParams
) -> void:
	if unit == null or not ctx.trigger(unit, &"test_medal_after_fight"):
		return
	var medals: int = 2 if report.survived(unit) else 1
	ctx.add_unit_counter(unit, &"test_medal", medals, unit)
	ctx.buff(unit, medals, medals, true, unit)
