extends Mechanic
## Spoon Catapult: Ambush its target before its first attack, then exchange damage normally.
## Windfury and out-of-turn attacks share the same once-per-fight allowance.

const MouseRules := preload("res://src/content/mouse/lib/mouse_rules.gd")


func on_attack(
	combat: Combat, unit: CombatUnit, defender: CombatUnit, _params: MechanicParams
) -> void:
	MouseRules.ambush(combat, unit, defender, &"mouse_catapult")
