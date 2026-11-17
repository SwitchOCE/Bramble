extends Mechanic
## "Instead of attacking, deal 1 damage to a random enemy."


func instead_of_attack(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> bool:
	var target: CombatUnit = combat.random_enemy(unit)
	if target == null or not combat.trigger(unit, &"test_sling"):
		return false
	combat.deal_damage(unit, target, 1)
	return true
