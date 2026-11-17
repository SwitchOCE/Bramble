extends Mechanic
## Toothpick Ballista: one opening Ambush of the weakest enemy, sharing the unit's allowance.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	MouseRules.ambush_weakest(combat, unit, &"mouse_ballista")
