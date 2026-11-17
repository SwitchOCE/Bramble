extends Mechanic
## Overrun: when an attack by this unit deals more damage in the damage exchange than its target
## has Health left, the rest is dealt to another enemy, picked as this unit's next attack would
## pick (combat.choose_target, which never picks a dying unit), and so on. Only the first target
## was attacked and strikes back; the carried damage is plain damage (no Thorns, Fury or "is
## attacked"), and its kills are this unit's. Not for a Hit or a pile-on hit; if a pile-on killed
## the target there is no exchange and nothing to carry. A target saved by Stiff Upper Lip or a
## shield wasn't killed, so nothing carries on (SHARED-RULES 28).
##
## combat.damage_from_own_attack() is true only for this unit's own attack on its target: not its
## strike back when it is attacked, a Cleave splash, a Hit or the carried damage itself.


func on_damage_dealt(
	combat: Combat, unit: CombatUnit, target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	if not combat.damage_from_own_attack() or target.health() >= 0:
		return
	var rest: int = -target.health()
	while rest > 0 and not combat.halted():
		var next: CombatUnit = combat.choose_target(unit)
		if next == null or not combat.trigger(unit, &"badger_overrun"):
			return
		var before: int = next.health()
		combat.deal_damage(unit, next, rest, false)
		rest = rest - before if next.should_die() else 0
