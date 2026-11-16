extends Mechanic
## Overrun: when an attack by this unit deals more damage in the damage exchange than its target
## has Health left, the rest is dealt to another enemy, picked as this unit's next attack would
## pick (combat.choose_target, which never picks a dying unit), and so on. Only the first target
## was attacked and strikes back; the carried damage is plain damage (no Thorns, Fury or "is
## attacked"), and its kills are this unit's. Not for a Hit or a pile-on hit; if a pile-on killed
## the target there is no exchange and nothing to carry. A target saved by Stiff Upper Lip or a
## shield wasn't killed, so nothing carries on.
##
## combat.damage_from_attack() tells the exchange from a Hit or plain damage. It is also true for
## a Cleave splash and for this unit's strike back when it is attacked, so the defender of this
## unit's own attack is noted in on_attack: only damage to that unit carries.

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
	if not combat.damage_from_attack() or target.health() >= 0:
		return
	if unit.state_int(TARGET) == 0 or unit.state_int(TARGET) != target.uid:
		return
	unit.set_state(TARGET, 0)
	var rest: int = -target.health()
	while rest > 0 and not combat.halted():
		var next: CombatUnit = combat.choose_target(unit)
		if next == null or not combat.trigger(unit, &"badger_overrun"):
			return
		var before: int = next.health()
		combat.deal_damage(unit, next, rest, false)
		rest = rest - before if next.should_die() else 0
