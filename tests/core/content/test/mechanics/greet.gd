extends Mechanic
## Entering a board, both phases: a friend that enters gets +1 Attack (this turn / fight).


func on_board_enter(
	ctx: RecruitContext, unit: Unit, entered: Unit, _params: MechanicParams
) -> void:
	if unit != null and entered != unit and ctx.trigger(unit, &"test_greet"):
		ctx.buff(entered, 1, 0, false, unit)


func on_fight_enter(
	combat: Combat, unit: CombatUnit, entered: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null or entered == unit or entered.side != unit.side:
		return
	if combat.trigger(unit, &"test_greet"):
		combat.buff(entered, 1, 0, unit)
