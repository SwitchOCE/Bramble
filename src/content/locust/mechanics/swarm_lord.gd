extends Mechanic
## Swarm-lord. A death counter (9.7.4): at every `every`th friendly Locust death in a fight
## (Hoppers are Locusts; a returning Locust counts each death), Tide +`amount`. Eaten or drummed
## units didn't die and don't count.

const Locust := preload("res://src/content/locust/locust.gd")
const SEEN: StringName = &"locust_swarm_lord_seen"


func param_kinds() -> Dictionary:
	return {"every": MechanicParams.Kind.THRESHOLD, "amount": MechanicParams.Kind.NUMBER}


func on_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or not dead.def.has_tribe(Locust.TRIBE):
		return
	var seen: int = unit.state_int(SEEN) + 1
	if seen < maxi(1, params.num(&"every")):
		unit.set_state(SEEN, seen)
		return
	unit.set_state(SEEN, 0)
	if combat.trigger(unit, &"locust_swarm_lord"):
		combat.bridge(unit.side).add_counter(Locust.TIDE, params.num(&"amount"), unit)
