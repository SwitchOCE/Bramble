extends Mechanic
## Wheat Raider. When this dies, deal `amount` damage to a random enemy from either row (9.5.6):
## damage, not an attack or a Hit. Needs a fight: in the shop it does nothing (ruling 34).

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var target: CombatUnit = Locust.random_living_enemy(combat, unit)
	if target != null and combat.trigger(unit, &"locust_death_damage_random"):
		combat.deal_damage(unit, target, params.num(&"amount"))
