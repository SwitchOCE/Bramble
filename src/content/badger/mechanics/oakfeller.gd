extends Mechanic
## The Oakfeller: after this attacks and kills a unit with its own damage (the target, or one
## reached by Overrun), it attacks again, at once. Extra attacks never earn another. A
## kill a neighbour's pile-on makes is not its kill.
##
## State on the fight unit: SWING is 1 while a normal attack's deaths resolve and 2 for the
## extra attack's; a kill during a normal swing sets PENDING, and the extra attack is made
## after that round of deaths (once the dead have left the board).

const SWING: StringName = &"badger_oak_swing"
const PENDING: StringName = &"badger_oak_pending"
const EXTRA: StringName = &"badger_oak_extra"


func param_kinds() -> Dictionary:
	return {"extra_attacks": MechanicParams.Kind.NUMBER}


func text_params(params: MechanicParams) -> Dictionary:
	return {"follow_ups": UnitText.repeat_count(params.num(&"extra_attacks"))}


func on_attack(
	_combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	unit.set_state(SWING, 2 if unit.state_int(EXTRA) != 0 else 1)


func on_attacked(
	_combat: Combat, unit: CombatUnit, _attacker: CombatUnit, _params: MechanicParams
) -> void:
	unit.set_state(SWING, 0)


func on_kill(
	_combat: Combat, unit: CombatUnit, _victim: CombatUnit, _params: MechanicParams
) -> void:
	if unit.state_int(SWING) == 1:
		unit.set_state(PENDING, 1)


func after_death_round(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	if unit == null:
		return
	unit.set_state(SWING, 0)
	if unit.state_int(PENDING) == 0:
		return
	unit.set_state(PENDING, 0)
	if unit.gone or combat.units(1 - unit.side).is_empty():
		return
	if not combat.trigger(unit, &"badger_oakfeller"):
		return
	unit.set_state(EXTRA, 1)
	for _i: int in params.num(&"extra_attacks"):
		if not combat.attack_now(unit):
			break
	unit.set_state(EXTRA, 0)
	unit.set_state(SWING, 0)
