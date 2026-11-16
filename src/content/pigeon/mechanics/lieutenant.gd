extends Mechanic
## Lieutenant: Start of fight (main pass): if every slot of this row holds a unit (any tribe),
## each of them deals damage equal to the Attack its own slot gives it in this fight (an
## Edgewright's doubling and a Colour Ensign's copy included) to the enemy across from it (8.2.6);
## if that slot is empty, the nearest enemy in that row, else any enemy. Plain damage: not an
## attack and not a Hit. A golden deals `percent` 200.


func param_kinds() -> Dictionary:
	return {"percent": MechanicParams.Kind.NUMBER}


func on_start_of_combat(combat: Combat, unit: CombatUnit, params: MechanicParams) -> void:
	var row: Array[int] = combat.geometry.row_of(unit.slot)
	var dealers: Array[CombatUnit] = []
	for slot: int in row:
		var here: CombatUnit = combat.unit_at(unit.side, slot)
		if here == null or here.gone:
			return
		dealers.append(here)
	if not combat.trigger(unit, &"pigeon_lieutenant"):
		return
	for dealer: CombatUnit in dealers:
		var amount: int = int(dealer.stats.slot_attack * params.num(&"percent") / 100.0)
		if amount <= 0 or combat.halted():
			continue
		var target: CombatUnit = _across(combat, dealer)
		if target != null:
			combat.deal_damage(dealer, target, amount)


func _across(combat: Combat, dealer: CombatUnit) -> CombatUnit:
	var enemy: int = 1 - dealer.side
	var slot: int = combat.geometry.across(dealer.slot)
	var found: CombatUnit = combat.unit_at(enemy, slot)
	if _standing(found):
		return found
	var best: CombatUnit = null
	var best_distance: float = INF
	for other: int in combat.geometry.row_of(slot):
		var candidate: CombatUnit = combat.unit_at(enemy, other)
		if not _standing(candidate):
			continue
		var distance: float = absf(combat.geometry.x_of(other) - combat.geometry.x_of(slot))
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if best != null:
		return best
	var rest: Array[CombatUnit] = combat.units(enemy).filter(_standing)
	return rest[combat.effect_rng.index(rest.size())] if not rest.is_empty() else null


## Dying units stay on the board inside one effect: skip those already at 0 Health.
static func _standing(unit: CombatUnit) -> bool:
	return unit != null and not unit.gone and unit.health() > 0
