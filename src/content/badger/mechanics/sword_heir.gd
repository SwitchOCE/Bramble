extends Mechanic
## Sword-heir: after a unit in front of this dies (9.7.2 step 3, by its last-known slot), gain its
## own Attack and own maximum Health (SHARED-RULES 43: no slot buff, lent stats, auras or Tide)
## and its own Fury (printed, given for good and this fight's; not an aura's or the Marshal's),
## this fight. Golden: double the Attack and Health (`times`).

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")


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
	var fury: int = BadgerRules.own_fury(dead)
	if fury > 0:
		combat.bridge(unit.side).add_unit_counter(unit, BadgerRules.FURY_FIGHT, fury, false, unit)
	var times: int = params.num(&"times")
	combat.buff(unit, dead.stats.own_attack() * times, dead.stats.own_health() * times, unit)
