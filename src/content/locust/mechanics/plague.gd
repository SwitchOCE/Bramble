extends Mechanic
## The Eighth Plague. After a friendly unit dies (9.7.2 step 3), deal damage to a random enemy,
## either row, equal to that death's number this fight times `per`: the 10th death deals 10.
## Deaths before this unit arrived count; a death effect set off without a death doesn't. The
## number comes from the standing locust_swarm (each death in order); without it, the side's
## death count.

const Locust := preload("res://src/content/locust/locust.gd")


func param_kinds() -> Dictionary:
	return {"per": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null:
		return
	var number: int = dead.state_int(Locust.DEATH_NUMBER)
	if number <= 0:
		number = combat.bridge(unit.side).deaths
	var target: CombatUnit = Locust.random_living_enemy(combat, unit)
	if target != null and combat.trigger(unit, &"locust_plague"):
		combat.deal_damage(unit, target, number * params.num(&"per"))
