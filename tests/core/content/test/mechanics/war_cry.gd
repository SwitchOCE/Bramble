extends Mechanic
## "Whenever this attacks": +1 Attack this fight.


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	if combat.trigger(unit, &"test_war_cry"):
		combat.buff(unit, 1, 0, unit)
