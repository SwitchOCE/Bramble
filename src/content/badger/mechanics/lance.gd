extends Mechanic
## Hedge Lancer: Start of fight (main pass): this attacks immediately and takes no damage from
## anything while that attack resolves (SHARED-RULES 26). Its later attacks are normal.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if combat.trigger(unit, &"badger_lance"):
		combat.attack_now(unit, null, true)
