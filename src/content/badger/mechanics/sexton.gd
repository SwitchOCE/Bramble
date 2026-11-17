extends Mechanic
## Sett Sexton: after another friendly Badger dies (9.7.2 step 3), every friendly Badger on the
## board at that moment, this one included, has +N Fury for the rest of this fight (a Badger with
## no Fury now has Fury N). Badgers that arrive later don't get it; the outnumbered count doesn't
## change.

const BadgerRules := preload("res://src/content/badger/lib/badger_rules.gd")


func param_kinds() -> Dictionary:
	return {"fury": MechanicParams.Kind.NUMBER}


func after_friendly_death(
	combat: Combat, unit: CombatUnit, dead: CombatUnit, params: MechanicParams
) -> void:
	if unit == null or dead == unit or dead.side != unit.side:
		return
	if not dead.def.has_tribe(BadgerRules.BADGER):
		return
	if not combat.trigger(unit, &"badger_sexton"):
		return
	for friend: CombatUnit in combat.units(unit.side):
		if friend.def.has_tribe(BadgerRules.BADGER):
			BadgerRules.give_fight_fury(combat, friend, params.num(&"fury"), unit)
