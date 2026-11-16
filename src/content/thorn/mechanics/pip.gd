extends Mechanic
## When this dies, summon a Pip (Crab-apple): a 3/3 Briar with Seed, into this unit's slot, else
## the nearest empty one; with no room it is lost (Pips don't wait). A golden summons a 6/6 Pip
## whose Seed adds 2. Eaten in the shop, the Pip goes on the recruit board like any summon.

const Compost := preload("res://src/content/thorn/lib/compost_rules.gd")
const PIP: StringName = &"pip"


func has_death_effect() -> bool:
	return true


func on_death(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if not combat.trigger(unit, &"thorn_pip"):
		return
	var made: CombatUnit = combat.summon(unit.side, PIP, unit.slot, true, unit)
	if made != null and params.golden:
		# The core summons tokens plain: a golden Pip is a Pip with doubled stats and Seed 2.
		combat.buff(made, made.def.attack, made.def.health, unit)
		combat.bridge(unit.side).add_unit_counter(made, Compost.GOLDEN_PIP, 1, false, unit)


func on_recruit_death(ctx: RecruitContext, unit: Unit, params: MechanicParams) -> void:
	if not ctx.trigger(unit, &"thorn_pip"):
		return
	var made: Unit = ctx.summon(PIP, unit.slot)
	if made != null and params.golden:
		ctx.buff(made, made.def.attack, made.def.health, true, unit)
		ctx.add_unit_counter(made, Compost.GOLDEN_PIP, 1, unit)
