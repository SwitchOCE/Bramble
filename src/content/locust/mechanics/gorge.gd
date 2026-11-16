extends Mechanic
## Gorger. The first time you sell a unit each turn (any tribe), this eats it: it gains the sold
## unit's own stats times `times` permanently, then the sold unit's death effects resolve in the
## Recruit Phase. Each Gorger eats once a turn; each sale is eaten once (a Gorger before a
## Granary Glutton).

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func on_any_sold(ctx: RecruitContext, unit: Unit, sold: Unit, params: MechanicParams) -> void:
	if unit != null:
		Locust.eat(ctx, unit, sold, Locust.GORGE, params.num(&"times"))
