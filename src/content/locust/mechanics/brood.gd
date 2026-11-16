extends Mechanic
## Brood Mother. When this dies, summon `count` Hoppers and add `bonus` to the player's Hopper
## bonus (every Hopper +bonus/+bonus for the rest of the game). Each time it resolves: a death,
## a drumbeat, being eaten; twice with a Dirge-singer.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER, "bonus": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"locust_brood"):
		return
	Locust.summon_hoppers(combat, unit, params.num(&"count"), true)
	combat.bridge(unit.side).add_counter(Locust.HOPPER_BONUS, params.num(&"bonus"), unit)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"locust_brood"):
		return
	Locust.recruit_summon_hoppers(ctx, unit, params.num(&"count"))
	ctx.add_counter(Locust.HOPPER_BONUS, params.num(&"bonus"), unit)
