class_name Mechanic
extends RefCounted
## Base class of the mechanic scripts (SPEC section 4): one script per mechanic id, implementing
## only the hooks it needs; every hook here is a no-op. Scripts are stateless and shared: state
## lives on the units (statuses, counters) and in the Combat. `params` are the unit file's
## parameters, with "number" parameters already doubled for a golden unit (4.4).


## Before the fight starts: initial statuses shown at combat_start (Shell, Bide's waiting).
func setup(_unit: CombatUnit, _params: Dictionary) -> void:
	pass


## True for a unit that takes turns without Attack (Whistle).
func acts_without_attack(_params: Dictionary) -> bool:
	return false


## 9.3 Start of Combat.
func on_start_of_combat(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


## 9.4.5: the unit was chosen. Returns "" to attack, "skip" (the side picks the next unit in the
## same turn) or "turn" (the unit used the side's turn without attacking).
func choose_turn_action(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> String:
	return ""


## Units that join this unit's attack (Swarm). The script flags them.
func joiners(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> Array[CombatUnit]:
	return []


## The enemy this unit must attack, ahead of 9.5 (Rival); null = no opinion.
func choose_target(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> CombatUnit:
	return null


## 9.6.1 before step 1, for every unit on both sides (Bystander, Both Ends).
func on_attack_declared(
	_combat: Combat,
	_unit: CombatUnit,
	_params: Dictionary,
	_attacker: CombatUnit,
	_defender: CombatUnit
) -> void:
	pass


## 9.6.1 step 2, the attacker's "whenever this attacks"; once per strike.
func on_before_attack(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


## How many strikes this unit's attack makes; 0 = no opinion (1).
func strikes(_params: Dictionary) -> int:
	return 0


## Quick: this unit deals its damage first in this exchange (9.6.2).
func strikes_first(_unit: CombatUnit, _params: Dictionary) -> bool:
	return false


## The amount of an incoming hit after this unit's modifiers; add a name to hit.modifiers.
func modify_damage_taken(_unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	return hit.amount


## The amount of an outgoing hit after this unit's modifiers (Rival); runs before the target's.
func modify_damage_dealt(_unit: CombatUnit, _params: Dictionary, hit: Hit) -> int:
	return hit.amount


## After a damage event, for its source.
func on_damage_dealt(_combat: Combat, _unit: CombatUnit, _params: Dictionary, _hit: Hit) -> void:
	pass


## After a damage event, for its target, before deaths are checked.
func on_damage_taken(_combat: Combat, _unit: CombatUnit, _params: Dictionary, _hit: Hit) -> void:
	pass


## After the attack's death resolution, for the defender while it is still on the board.
func on_survived_attack(
	_combat: Combat, _unit: CombatUnit, _params: Dictionary, _attacker: CombatUnit
) -> void:
	pass


## After the attack's death resolution, for the attacker while it is still on the board.
func on_after_attacking(
	_combat: Combat, _unit: CombatUnit, _params: Dictionary, _defender: CombatUnit
) -> void:
	pass


## 9.7.2 step 2, the dying unit's own death effects. The unit has left its slot; unit.slot is
## its last-known slot (12.2.3).
func on_death(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> void:
	pass


## 12.2.1: the Attack and Health this unit gets from its own aura right now (Both Ends).
func aura(_combat: Combat, _unit: CombatUnit, _params: Dictionary) -> Vector2i:
	return Vector2i.ZERO


## 3.4.1 step 1, End of Turn on the recruit board.
func on_end_of_turn(_player: PlayerState, _unit: RecruitUnit, _params: Dictionary) -> void:
	pass
