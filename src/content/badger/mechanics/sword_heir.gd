extends Mechanic
## Sword-heir: after a unit in front of this dies (9.7.2 step 3, by its last-known slot), gain its
## own Attack and own maximum Health (SHARED-RULES 43: excluding Renown, lent stats, auras and Tide)
## and its own Fury (printed and given; not an aura's or the Marshal's), this fight. Golden:
## double the Attack and Health (`times`), not the Fury.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"times": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or dead == unit or dead.side != unit.side:
		return
	if not combat.geometry.in_front_of(unit.slot).has(dead.slot):
		return
	if not combat.trigger(unit, &"badger_sword_heir"):
		return
	BadgerRules.give_fight_fury(combat, unit, BadgerRules.own_fury(dead), unit)
	var times: int = params.num(&"times")
	combat.buff(unit, dead.stats.own_attack() * times, dead.stats.own_health() * times, unit)
