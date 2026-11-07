class_name CombatReactions
extends RefCounted
## Immediate attacks use a queue, never a recursive damage hook. Counters cannot cause counters;
## Pounces may cause Pounces, with their own per-cycle limit. Every attack consumes the fight cap.

var current_attacker: CombatUnit = null
var current_defender: CombatUnit = null
var kind: String = ""
var last_strike: bool = false
var completed: bool = false
var draining: bool = false
var pending: Array[Dictionary] = []


func enqueue(attacker: CombatUnit, defender: CombatUnit, attack_kind: String) -> void:
	if attack_kind == "counter" and kind != "":
		return
	pending.append({"attacker": attacker, "defender": defender, "kind": attack_kind})


func attack(
	combat: Combat, attacker: CombatUnit, defender: CombatUnit, attack_kind: String = ""
) -> void:
	current_attacker = attacker
	current_defender = defender
	kind = attack_kind
	completed = false
	last_strike = false
	combat._perform_attack(attacker, defender)
	current_attacker = null
	current_defender = null
	kind = ""
	drain(combat)


func drain(combat: Combat) -> void:
	if draining:
		return
	draining = true
	while not pending.is_empty() and not combat._halted:
		var entry: Dictionary = pending.pop_front()
		var attacker: CombatUnit = entry["attacker"]
		var defender: CombatUnit = entry["defender"]
		if not attacker.can_attack() or attacker.is_dead() or attacker.is_stopped():
			continue
		if not defender.on_board or defender.is_dead() or attacker.side == defender.side:
			continue
		var lock: CombatUnit = CombatLanes.lock_target(combat, attacker)
		if lock != null and lock != defender:
			continue
		if combat.attacks_made >= combat.config.get_int("attack_limit"):
			pending.clear()
			break
		combat.attacks_made += 1
		combat.emit_event(
			"immediate_attack",
			{"attacker": attacker.uid, "defender": defender.uid, "kind": entry["kind"]}
		)
		attack(combat, attacker, defender, str(entry["kind"]))
	draining = false


## Quick may finish an exchange before the return hit. Otherwise wait until the last damage
## step of the last strike, so Bitter doesn't alter the same attack's damage or fire per Peck.
func before_deaths(combat: Combat, final_step: bool) -> void:
	if completed or current_attacker == null or current_defender == null:
		return
	var terminal: bool = current_attacker.is_dead() or current_defender.is_dead()
	if not terminal and not (last_strike and final_step):
		return
	completed = true
	CombatLanes.bitter(combat, current_defender, current_attacker)
	for index: int in current_defender.scripts.size():
		current_defender.scripts[index].on_attacked_complete(
			combat, current_defender, current_defender.params[index], current_attacker
		)
