extends Mechanic
## Orchard Stripper. When this dies, deal `amount` damage to every enemy in both rows. Needs a
## fight: in the shop it does nothing (ruling 34).

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var enemies: Array[CombatUnit] = Locust.living_enemies(combat, unit)
	if enemies.is_empty() or not combat.trigger(unit, &"locust_death_damage_all"):
		return
	for enemy: CombatUnit in enemies:
		combat.deal_damage(unit, enemy, params.num(&"amount"))
