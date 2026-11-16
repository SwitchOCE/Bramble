extends Mechanic
## Granary Glutton. Whenever you sell a Locust (Hoppers too), this eats it, unless a Gorger that
## hasn't eaten this turn does; with two Gluttons the first in reading order eats. When this is
## sold itself it is off the board and eats nothing.

const Locust := preload("res://src/content/locust/locust.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func on_any_sold(ctx: RecruitContext, unit: Unit, sold: Unit, params: MechanicParams) -> void:
	if unit != null:
		Locust.eat(ctx, unit, sold, Locust.GLUT, params.num(&"times"))
