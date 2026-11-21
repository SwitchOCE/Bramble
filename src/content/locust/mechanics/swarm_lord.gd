extends Mechanic
## Swarm-lord. Each friendly Locust death in a fight raises the Tide. This includes Hoppers
## and each death of a returning Locust.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func on_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or not dead.def.has_tribe(Locust.TRIBE):
		return
	if combat.trigger(unit, &"locust_swarm_lord"):
		combat.bridge(unit.side).add_counter(Locust.TIDE, params.num(&"amount"), unit)
