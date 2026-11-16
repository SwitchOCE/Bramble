extends Mechanic
## Seed: when this dies, add a copy of it to your Compost (a death effect, 9.7.2 step 2). A
## golden adds 2, and so does a golden Crab-apple's Pip. Set off without a death (drummed,
## eaten) it still adds its entry.

const Compost := preload("res://src/content/thorn/compost_rules.gd")


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"thorn_seed"):
		return
	for _i: int in _entries(params, unit.counter(Compost.GOLDEN_PIP)):
		combat.bridge(unit.side).heap_add(Compost.HEAP, unit.def.id, unit.def.tier, unit)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"thorn_seed"):
		return
	for _i: int in _entries(params, unit.counter(Compost.GOLDEN_PIP)):
		ctx.heap_add(Compost.HEAP, unit.def.id, unit)


static func _entries(params: MechanicParams, golden_pip: int) -> int:
	return 2 if params.golden or golden_pip > 0 else 1
