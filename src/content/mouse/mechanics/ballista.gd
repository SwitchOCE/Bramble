extends Mechanic
## Toothpick Ballista: start of fight (main pass), Hit the enemy with the least Health, `times`
## times (golden: twice, choosing again). A Hit is not an attack.

const MouseRules := preload("res://src/content/mouse/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if unit.attack() <= 0 or MouseRules.least_health_enemy(combat, unit) == null:
		return
	if combat.trigger(unit, &"mouse_ballista"):
		MouseRules.hit_weakest(combat, unit, params.num(&"times"))
