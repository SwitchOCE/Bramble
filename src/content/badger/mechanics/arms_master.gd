extends Mechanic
## Master-at-Arms: Recruit gives a friendly unit in hand or on board +N Fury permanently.
## It adds to that unit's own Fury. A plain copy loses it; a golden target doesn't double it.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"fury": MechanicParams.Kind.NUMBER}


func recruit_target(_params: MechanicParams) -> Target:
	return Target.FRIENDLY_UNIT


func on_recruited(ctx: RecruitContext, unit: Unit, target: Unit, params: MechanicParams) -> void:
	var chosen: Unit = target if target != null else unit
	if ctx.trigger(unit, &"badger_arms_master"):
		ctx.give_effect(chosen, BadgerRules.FURY, {"fury": params.num(&"fury")}, unit)
