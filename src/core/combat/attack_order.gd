class_name AttackOrder
extends RefCounted
## 9.4.2: the order a side's units attack in: reading order, or the back row first when a hero's
## rule says so (Dame Hoolet, Combat.side_rules).


static func of(units: Array[CombatUnit], rules: Dictionary) -> Array[CombatUnit]:
	var out: Array[CombatUnit] = []
	var early: Array[int] = early_slots(units)
	for unit: CombatUnit in units:
		if early.has(unit.slot):
			out.append(unit)
	var row_order: Array = [false, true] if _back_row_first(rules) else [true, false]
	for front: bool in row_order:
		for unit: CombatUnit in units:
			if BoardGeometry.is_front(unit.slot) == front and not early.has(unit.slot):
				out.append(unit)
	return out


static func early_slots(units: Array[CombatUnit]) -> Array[int]:
	var early: Array[int] = []
	for unit: CombatUnit in units:
		if BoardGeometry.is_back(unit.slot) and unit.has_mechanic("vault"):
			early.append(unit.slot)
	for unit: CombatUnit in units:
		if Pass3HunterCombat.has(unit, "brother_wolf") and not unit.is_dead():
			for candidate: CombatUnit in units:
				if (
					BoardGeometry.adjacent(unit.slot).has(candidate.slot)
					and not early.has(candidate.slot)
				):
					early.append(candidate.slot)
	return early


## A slot's place in its side's attack order.
static func rank(rules: Dictionary, slot: int, early: Array[int] = []) -> int:
	if early.has(slot):
		return early.find(slot)
	var offset: int = early.size()
	if not _back_row_first(rules):
		return offset + slot
	return offset + (slot - 4 if BoardGeometry.is_back(slot) else slot + 3)


static func _back_row_first(rules: Dictionary) -> bool:
	return CoreUtil.to_bool(rules.get("back_row_first", false))
