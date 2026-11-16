extends Mechanic
## Famine-caller. When this dies, Tide +`amount`: at once, for the rest of the game, whether it
## died, was drummed or was eaten.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"amount": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"locust_tide_on_death"):
		combat.bridge(unit.side).add_counter(Locust.TIDE, params.num(&"amount"), unit)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if ctx.trigger(unit, &"locust_tide_on_death"):
		ctx.add_counter(Locust.TIDE, params.num(&"amount"), unit)
