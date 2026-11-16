extends Mechanic
## Overrun (the badgers'): when an attack's damage exchange deals more than its target has Health
## left, the rest goes to the enemy this unit's next attack would pick (combat.choose_target,
## which never picks a dying unit), and so on. combat.damage_from_attack() tells the exchange
## from a Hit or plain damage; the carried damage is plain, so it doesn't carry again by itself.


func on_damage_dealt(
	combat: Combat, unit: CombatUnit, target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	if not combat.damage_from_attack() or target.health() >= 0:
		return
	var rest: int = -target.health()
	while rest > 0 and not combat.halted():
		var next: CombatUnit = combat.choose_target(unit)
		if next == null or not combat.trigger(unit, &"test_overrun"):
			return
		var before: int = next.health()
		combat.deal_damage(unit, next, rest, false)
		rest = rest - before if next.should_die() else 0
