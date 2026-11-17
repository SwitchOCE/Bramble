extends Mechanic
## 11.2.2 Divine Shield (example keyword): the first time this unit would take damage in a
## combat, it takes none and the shield is lost. Since no damage is dealt, it also stops
## Venomous, which stays unused (see the README's list of settled gaps).

const UP: StringName = &"divine_shield_up"


func on_combat_begin(_combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	unit.set_state(UP, 1)


func absorb_damage(
	combat: Combat, unit: CombatUnit, amount: int, _from_attack: bool, _params: MechanicParams
) -> int:
	if amount <= 0 or unit.state_int(UP) == 0:
		return amount
	unit.set_state(UP, 0)
	combat.show_status(unit, &"divine_shield", false)
	return 0
