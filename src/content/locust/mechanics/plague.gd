extends Mechanic
## The Eighth Plague. After a friendly unit dies (9.7.2 step 3), deal damage to a random enemy,
## either row, equal to the number of friendly deaths this fight times `per` (1; 2 on a golden):
## the 10th death deals 10. The core counts a side's deaths as each one resolves
## (FightSide.deaths), so deaths before this unit arrived count and the second of two deaths in
## one batch reads 2; a death effect set off without a death doesn't count.


func param_kinds() -> Dictionary:
	return {"per": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, _dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null:
		return
	var number: int = combat.bridge(unit.side).deaths
	var target: CombatUnit = combat.random_enemy(unit)
	if target != null and combat.trigger(unit, &"locust_plague"):
		combat.deal_damage(unit, target, number * params.num(&"per"))
