extends Mechanic
## After a friendly unit returns, give it +2/+2 this fight.


func after_friendly_return(
	combat: Combat, unit: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	if unit != null and combat.trigger(unit, &"test_welcome_back"):
		combat.buff(back, 2, 2, unit)
