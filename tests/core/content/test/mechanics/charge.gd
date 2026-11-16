extends Mechanic
## 9.4.12 Start of Combat: this attacks immediately.


func on_start_of_combat(combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	if combat.trigger(unit, &"test_charge"):
		combat.attack_now(unit)
