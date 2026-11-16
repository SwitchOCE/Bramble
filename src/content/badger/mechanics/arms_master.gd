extends Mechanic
## Master-at-Arms: when played (7.2.3), give a friendly unit on the board (any tribe, this one
## included) +N Fury for good: a badger_fury of its own that adds to the Fury it has. A plain
## copy of the unit doesn't have it. The number is this card's; a golden target doesn't double it.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"fury": MechanicParams.Kind.NUMBER}


func play_target(_params: MechanicParams) -> Target:
	return Target.FRIENDLY_UNIT


func on_played(ctx: RecruitContext, unit: Unit, target: Unit, params: MechanicParams) -> void:
	var chosen: Unit = target if target != null else unit
	if ctx.trigger(unit, &"badger_arms_master"):
		ctx.give_effect(chosen, BadgerRules.FURY, {"fury": params.num(&"fury")}, unit)
