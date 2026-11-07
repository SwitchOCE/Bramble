extends HitReactor
## Bubble and Squeak: `splits` times a fight, after this survives a hit, half its Attack and Health
## go to a copy in the nearest gap. The copy's Belly is empty and its split is used.


func hit_counter() -> String:
	return "bubble_hit"


func after_hit(combat: Combat, unit: CombatUnit, params: Dictionary) -> void:
	var used: int = CoreUtil.to_int(unit.counters.get("split", 0))
	var limit: int = CoreUtil.to_int(params.get("splits", 1))
	var slot: int = BoardGeometry.summon_slot(combat._occupied(unit.side), unit.slot, false)
	@warning_ignore("integer_division")
	var attack: int = unit.attack / 2
	@warning_ignore("integer_division")
	var health: int = unit.health / 2
	if used >= limit or slot < 0 or health <= 0:
		return
	unit.counters["split"] = used + 1
	combat.trigger(unit, "bubble")
	combat.buff(unit, -attack, -health, unit)
	var spec: Dictionary = {
		"def_id": unit.def_id(), "golden": unit.golden, "attack": attack, "health": health
	}
	var copy: CombatUnit = combat.enter_from_spec(spec, unit.side, slot, unit)
	if copy != null:
		copy.counters["split"] = limit
	combat._resolve_deaths(unit.side)
