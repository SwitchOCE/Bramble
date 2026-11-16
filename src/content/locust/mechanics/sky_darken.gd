extends Mechanic
## Sky-darkener. Start of fight (main pass): summon `count` Hoppers in the empty slots nearest
## this unit (8.4.2); the rest wait.

const Locust := preload("res://src/content/locust/locust.gd")


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"locust_sky_darken"):
		Locust.summon_hoppers(combat, unit, params.num(&"count"), false)
