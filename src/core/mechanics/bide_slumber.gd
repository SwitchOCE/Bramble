extends Mechanic
## Bide (Slumber) (library entry 9): starts waiting. While waiting, each time its side's order
## chooses it, it gains +`attack`/+`health` this combat and the turn passes to the side's next
## unit. It wakes when it takes damage, or when no friendly unit that isn't waiting can attack;
## then it attacks as normal (SPEC 4.2).


func setup(unit: CombatUnit, _params: Dictionary) -> void:
	unit.statuses["waiting"] = {}


func choose_turn_action(combat: Combat, unit: CombatUnit, params: Dictionary) -> String:
	if not unit.has_status("waiting"):
		return ""
	if not _others_can_attack(combat, unit):
		combat.set_status(unit, "waiting", false, unit)
		return ""
	combat.trigger(unit, "bide")
	combat.buff(
		unit,
		CoreUtil.to_int(params.get("attack", 0)),
		CoreUtil.to_int(params.get("health", 0)),
		unit
	)
	combat.emit_event("skip", {"side": unit.side, "uid": unit.uid, "reason": "bide"})
	return "skip"


func on_damage_taken(combat: Combat, unit: CombatUnit, _params: Dictionary, hit: Hit) -> void:
	if hit.amount > 0 and unit.has_status("waiting"):
		combat.set_status(unit, "waiting", false, unit)


## Whistle units never attack, so they don't keep it waiting (library entry 10, 9.9.1).
static func _others_can_attack(combat: Combat, unit: CombatUnit) -> bool:
	for other: CombatUnit in combat.units_of(unit.side):
		if other != unit and other.can_attack() and not other.has_status("waiting"):
			return true
	return false
