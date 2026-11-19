extends Mechanic
## Fury N: whenever this attacks or is attacked, gain +N Attack, and +N more for each unit
## you're outnumbered by (this fight). Fury from every source adds into one N (BadgerRules.fury);
## the Marshal multiplies it last.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"fury": MechanicParams.Kind.NUMBER}


func on_attacked(
	combat: Combat, unit: CombatUnit, _attacker: CombatUnit, params: MechanicParams
) -> void:
	BadgerRules.rage(combat, unit, params)


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	BadgerRules.rage(combat, unit, params)
