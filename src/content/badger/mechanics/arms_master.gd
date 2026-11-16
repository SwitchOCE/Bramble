extends Mechanic
## Master-at-Arms: when played, give a friendly unit on the board (any tribe, this one included)
## +N Fury for good. It is a counter on the unit (badger_fury_kept); the standing
## badger_fury_given turns it into Fury. A plain copy of the unit doesn't have it.
##
## Closest version until the core can grant a numbered effect through RecruitContext (core pass
## 4): the counter plus a standing aura. With other units on the board the core offers only them
## as targets, not this unit itself.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"fury": MechanicParams.Kind.NUMBER}


func play_target(_params: MechanicParams) -> Target:
	return Target.FRIENDLY_UNIT


func on_played(ctx: RecruitContext, unit: Unit, target: Unit, params: MechanicParams) -> void:
	var chosen: Unit = target if target != null else unit
	if ctx.trigger(unit, &"badger_arms_master"):
		ctx.add_unit_counter(chosen, BadgerRules.FURY_KEPT, params.num(&"fury"), unit)
