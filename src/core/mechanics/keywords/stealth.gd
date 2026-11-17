extends Mechanic
## 11.2.6 Stealth (example keyword): can't be targeted by attacks until it attacks or deals
## damage. A Stealthed front-row unit still protects the back row (9.5.3).

const HIDDEN: StringName = &"stealth_hidden"


func on_combat_begin(_combat: Combat, unit: CombatUnit, _params: MechanicParams) -> void:
	unit.set_state(HIDDEN, 1)


func on_attack(
	combat: Combat, unit: CombatUnit, _defender: CombatUnit, _params: MechanicParams
) -> void:
	_reveal(combat, unit)


func on_damage_dealt(
	combat: Combat, unit: CombatUnit, _target: CombatUnit, _amount: int, _params: MechanicParams
) -> void:
	_reveal(combat, unit)


func combat_query(unit: CombatUnit, query: StringName, value: int, _params: MechanicParams) -> int:
	if query == Q_UNTARGETABLE and unit.state_int(HIDDEN) != 0:
		return 1
	return value


func _reveal(combat: Combat, unit: CombatUnit) -> void:
	if unit.state_int(HIDDEN) != 0:
		unit.set_state(HIDDEN, 0)
		combat.show_status(unit, &"stealth", false)
