extends Mechanic
## Whenever this attacks, it attacks again immediately (bounded by MAX_ATTACK_DEPTH).


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	if combat.trigger(unit, &"test_frenzy"):
		combat.attack_now(unit)
