extends Mechanic
## Hidden, on every Badger: lets a Badger with no printed Fury use Fury it gains in a fight
## (Sett Sexton, Sword-heir). Resolves exactly as badger_fury, once per attack.

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")


func on_attacked(
	combat: Combat, unit: CombatUnit, _attacker: CombatUnit, params: MechanicParams
) -> void:
	BadgerRules.rage(combat, unit, params)


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, params: MechanicParams
) -> void:
	BadgerRules.rage(combat, unit, params)
