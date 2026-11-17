extends Mechanic
## Joining the fight: a friend summoned or stepping in gets +1 Attack this fight.


func on_fight_enter(
	combat: Combat, unit: CombatUnit, entered: CombatUnit, _params: MechanicParams
) -> void:
	if unit == null or entered == unit or entered.side != unit.side:
		return
	if combat.trigger(unit, &"test_greet"):
		combat.buff(entered, 1, 0, unit)
