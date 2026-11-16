extends Mechanic
## Adjutant: after each fight, the units in the two slots in front of this on the recruit board
## each earn `medals` Medals, whether or not they lived. Any tribe.

const Medals := preload("res://src/content/pigeon/medals.gd")


func param_kinds() -> Dictionary:
	return {"medals": MechanicParams.Kind.NUMBER}


func after_fight(
	ctx: RecruitContext, unit: Unit, _report: FightReport, params: MechanicParams
) -> void:
	if unit == null or unit.slot < 0:
		return
	var front: Array[Unit] = []
	for slot: int in ctx.geometry().in_front_of(unit.slot):
		var here: Unit = ctx.player.board[slot]
		if here != null:
			front.append(here)
	if front.is_empty() or not ctx.trigger(unit, &"pigeon_adjutant"):
		return
	for here: Unit in front:
		Medals.earn(ctx, here, params.num(&"medals"), unit)
