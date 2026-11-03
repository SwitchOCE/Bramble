extends Mechanic
## Whistle (library entry 10): never attacks. On its turn it whistles instead: the highest-Attack
## enemy not already warned deals half damage (rounded up) with its next attack. The whistle uses
## the side's turn and counts toward the attack limit (SPEC 4.2); ties are random.


func acts_without_attack(_params: Dictionary) -> bool:
	return true


func choose_turn_action(combat: Combat, unit: CombatUnit, _params: Dictionary) -> String:
	var best: Array[CombatUnit] = []
	for enemy: CombatUnit in combat.units_of(1 - unit.side):
		if enemy.has_status("warned"):
			continue
		if best.is_empty() or enemy.attack > best[0].attack:
			best = [enemy]
		elif enemy.attack == best[0].attack:
			best.append(enemy)
	combat.trigger(unit, "whistle")
	var warned: Array = []
	if not best.is_empty():
		var target: CombatUnit = best[combat.rng.randi_range(0, best.size() - 1)]
		combat.set_status(target, "warned", true, unit)
		warned.append(target.uid)
	combat.emit_event("whistle", {"side": unit.side, "uid": unit.uid, "warned": warned})
	return "turn"
