extends Mechanic
## Stiff Upper Lip: the first time damage would kill this each fight, it stays on 1 Health. Any
## kind of damage; not a death and not a return. Destroy effects don't go through damage, so they
## ignore it. Once a fight for each unit, whatever gives it (one state key).

const USED: StringName = &"pigeon_stiff_upper_lip_used"


func absorb_damage(
	combat: Combat, unit: CombatUnit, amount: int, _from_attack: bool, _params: MechanicParams
) -> int:
	if unit.state_int(USED) != 0 or amount < unit.health() or unit.health() <= 0:
		return amount
	if not combat.trigger(unit, &"pigeon_stiff_upper_lip"):
		return amount
	unit.set_state(USED, 1)
	combat.show_status(unit, &"pigeon_stiff_upper_lip", false)
	return unit.health() - 1


## A returned unit is the same unit for "a fight" limits (SHARED-RULES 21): a used Stiff Upper
## Lip stays used on its return.
func on_returned(
	_combat: Combat, gone: CombatUnit, back: CombatUnit, _params: MechanicParams
) -> void:
	if gone.state_int(USED) != 0:
		back.set_state(USED, 1)
