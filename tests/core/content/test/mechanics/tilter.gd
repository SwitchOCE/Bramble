extends Mechanic
## Start of Combat: attack immediately, taking no damage while it resolves.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if combat.trigger(unit, &"test_tilter"):
		combat.attack_now(unit, null, true)
