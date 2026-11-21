extends Mechanic
## Skin-shedder. Start of fight, set-up pass (ruling 41): the units next to this (8.2.2, same
## row, any tribe) get `charges` more Molt charges for this fight (one for plain and golden); one
## without Molt is given it. This unit doesn't Molt itself.

const Locust := preload("res://src/content/locust/lib/locust.gd")


func param_kinds() -> Dictionary:
	return {"charges": MechanicParams.Kind.NUMBER}


func start_of_combat_priority(_params: MechanicParams) -> int:
	return SOC_SETUP


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var targets: Array[CombatUnit] = combat.select(unit, "adjacent")
	if targets.is_empty() or not combat.trigger(unit, &"locust_shed"):
		return
	var side: FightSide = combat.bridge(unit.side)
	for target: CombatUnit in targets:
		target.add_fight_count(Locust.MOLT_EXTRA, params.num(&"charges"))
		if not target.has_mechanic(Locust.MOLT):
			side.give_keyword(target, Locust.MOLT, false, unit)
		combat.show_uses(target, Locust.MOLT, Locust.molt_left(target), unit)
