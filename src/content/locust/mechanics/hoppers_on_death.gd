extends Mechanic
## Green Recruit. When this dies, summon `count` Hoppers: the first into its slot (8.4.1), the
## rest nearest (8.4.2); with no room they wait. Set off without a death (War-drummer) its slot
## is taken, so all go nearest or wait. Eaten in the shop they land on the recruit board.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if combat.trigger(unit, &"locust_hoppers_on_death"):
		Locust.summon_hoppers(combat, unit, params.num(&"count"), true)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if ctx.trigger(unit, &"locust_hoppers_on_death"):
		Locust.recruit_summon_hoppers(ctx, unit, params.num(&"count"))
