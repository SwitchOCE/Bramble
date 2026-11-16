extends Mechanic
## Overrun: when an attack's damage exchange deals more than its target has Health left, the rest
## is dealt to another enemy, picked as this unit's next attack would pick, and so on. Only the
## first target was attacked and strikes back; the carried damage is plain damage (no Thorns,
## Fury or "is attacked"), and its kills are this unit's. Not for a Hit or a pile-on hit; if a
## pile-on killed the target there is no exchange and nothing to carry. A target saved by Stiff
## Upper Lip or a shield wasn't killed, so nothing carries on.
##
## The exchange is told apart from other damage by the target: on_attack names the defender,
## and the first damage this unit then deals to it is the exchange's.

const BadgerRules := preload("res://src/content/badger/badger_rules.gd")
const TARGET: StringName = &"badger_overrun_target"


func on_attack(
	_combat: Combat, unit: CombatUnit, defender: CombatUnit, _params: MechanicParams
) -> void:
	unit.set_state(TARGET, defender.uid)


func after_attack(
	_combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	unit.set_state(TARGET, 0)


func on_damage_dealt(
	combat: Combat, unit: CombatUnit, target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	if unit.state_int(TARGET) == 0 or unit.state_int(TARGET) != target.uid:
		return
	unit.set_state(TARGET, 0)
	var rest: int = -target.health()
	while rest > 0 and not combat.halted():
		var next: CombatUnit = BadgerRules.next_target(combat, unit)
		if next == null or not combat.trigger(unit, &"badger_overrun"):
			return
		combat.deal_damage(unit, next, rest, false)
		rest = -next.health() if next.should_die() else 0
