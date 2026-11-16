extends Mechanic
## Hedgerow Scout: whenever this attacks, summon a Cousin (golden: 2). It lands before any Pile
## on, nearest the Scout, and piles on in this attack if it lands next to the Scout.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func param_kinds() -> Dictionary:
	return {"count": MechanicParams.Kind.NUMBER}


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	if combat.trigger(unit, &"mouse_scout"):
		MouseRules.summon_cousins(combat, unit, params.num(&"count"))
