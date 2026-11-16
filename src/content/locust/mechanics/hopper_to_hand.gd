extends Mechanic
## Horde-runner. At the start of your turn, get `count` Hoppers in hand (Created; lost with a
## full hand, 7.1.2). Given, not summoned: Mother of Thousands doesn't double it.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func on_start_of_turn(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if unit == null or not ctx.trigger(unit, &"locust_hopper_to_hand"):
		return
	for _i: int in params.num(&"count"):
		ctx.give_card(Locust.HOPPER, unit)
