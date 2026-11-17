extends Mechanic
## Seed: when this dies, add a copy of it to your Compost (a death effect, 9.7.2 step 2). A
## golden adds 2, and so does a golden Crab-apple's golden Pip. Set off without a death (drummed,
## eaten) it still adds its entry.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"thorn_seed"):
		return
	for _i: int in _entries(params):
		combat.bridge(unit.side).heap_add(Compost.HEAP, unit.def.id, unit.def.tier, unit)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"thorn_seed"):
		return
	for _i: int in _entries(params):
		ctx.heap_add(Compost.HEAP, unit.def.id, unit)


static func _entries(params: MechanicParams) -> int:
	return 2 if params.golden else 1
