extends "res://src/content/pigeon/lib/private_call.gd"


func accepts(combat: Combat, unit: CombatUnit, dead: CombatUnit) -> bool:
	return combat.geometry.in_front_of(unit.slot).has(dead.slot)


func mechanic_id() -> StringName:
	return &"pigeon_recruiting_sergeant"
