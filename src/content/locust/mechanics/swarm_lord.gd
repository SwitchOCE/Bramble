extends Mechanic
## Swarm-lord. A death counter (9.7.4): at every `every`th friendly Locust death in a fight
## (Hoppers are Locusts; a returning Locust counts each death), Tide +`amount`. Eaten or drummed
## units didn't die and don't count. The count is a fight count, so a Swarm-lord that returns
## (a Skin-shedder's Molt) keeps it.

const Locust := preload("res://src/content/locust/lib/locust.gd")
const SEEN: StringName = &"locust_swarm_lord_seen"


func param_kinds() -> Dictionary:
	return {"every": MechanicParams.Kind.THRESHOLD, "amount": MechanicParams.Kind.NUMBER}


func on_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or not dead.def.has_tribe(Locust.TRIBE):
		return
	unit.add_fight_count(SEEN)
	if unit.fight_count(SEEN) % maxi(1, params.num(&"every")) != 0:
		return
	if combat.trigger(unit, &"locust_swarm_lord"):
		combat.bridge(unit.side).add_counter(Locust.TIDE, params.num(&"amount"), unit)
