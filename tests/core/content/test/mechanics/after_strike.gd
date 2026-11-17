extends Mechanic
## "After this attacks": +1 Health this fight.


func after_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	if combat.trigger(unit, &"test_after_strike"):
		combat.buff(unit, 0, 1, unit)
