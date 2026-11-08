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
var pack_joiners: Array[CombatUnit] = []
var pack_rewarded: bool = false


func enqueue(
	attacker: CombatUnit, defender: CombatUnit, attack_kind: String, attack_bonus: int = 0
) -> void:
	if attack_kind == "counter" and kind != "":
		return
	if attack_kind == "pounce":
		for entry: Dictionary in pending:
			if entry["attacker"] == attacker and entry["kind"] == "pounce":
				return
	pending.append(
		{
			"attacker": attacker,
			"defender": defender,
			"kind": attack_kind,
			"attack_bonus": attack_bonus
		}
	)


func attack(
	combat: Combat, attacker: CombatUnit, defender: CombatUnit, attack_kind: String = ""
) -> void:
	current_attacker = attacker
	current_defender = defender
	kind = attack_kind
	completed = false
	pack_rewarded = false
	pack_joiners = []
	last_strike = false
	# Damage immunity follows the declared defender's row for this whole attack,
	# including declaration effects and Bristle, then ends before a queued reply.
	if attacker.has_mechanic("back_row_immunity") and BoardGeometry.is_back(defender.slot):
		attacker.counters["attacking_back_row"] = 1
	combat._perform_attack(attacker, defender)
	attacker.counters.erase("attacking_back_row")
	CombatHunt.after_attack(combat, attacker, attack_kind)
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
		var bonus: int = CoreUtil.to_int(entry.get("attack_bonus", 0))
		var can_reply: bool = (
			str(entry["kind"]) == "counter" and (attacker.held_down() or bonus > 0)
		)
		if (
			not attacker.on_board
			or attacker.acts_without_attack
			or attacker.is_dead()
			or attacker.is_stopped()
		):
			continue
		if not attacker.can_attack() and not can_reply:
			continue
		if not defender.on_board or defender.is_dead() or attacker.side == defender.side:
			continue
		var lock: CombatUnit = CombatLanes.lock_target(combat, attacker)
		if lock != null and lock != defender:
			continue
		if combat.attacks_made >= combat.config.get_int("attack_limit"):
			pending.clear()
			break
		if str(entry["kind"]) == "pounce":
			if not CombatHunt.use_pounce(combat, attacker):
				continue
		combat.attacks_made += 1
		combat.emit_event(
			"immediate_attack",
			{"attacker": attacker.uid, "defender": defender.uid, "kind": entry["kind"]}
		)
		if bonus > 0:
			combat.buff(attacker, bonus, 0, attacker)
		attack(combat, attacker, defender, str(entry["kind"]))
		if bonus > 0:
			combat.buff(attacker, -bonus, 0, attacker)
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
	CombatHunt.quarry_attacked(combat, current_attacker)
	for index: int in current_defender.scripts.size():
		current_defender.scripts[index].on_attacked_complete(
			combat, current_defender, current_defender.params[index], current_attacker
		)
