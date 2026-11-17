extends Mechanic
## 11.2.5 Venomous (example keyword): destroys the first unit it deals damage to each combat.

const USED: StringName = &"venom_used"


func on_damage_dealt(
	combat: Combat, unit: CombatUnit, target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	if unit.state_int(USED) != 0 or target.gone:
		return
	if not combat.trigger(unit, &"venomous"):
		return
	unit.set_state(USED, 1)
	combat.destroy(unit, target)
	combat.show_status(unit, &"venomous", false, unit)
