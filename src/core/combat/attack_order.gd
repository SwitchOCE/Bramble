class_name AttackOrder
extends RefCounted
## 9.4.2: the order a side's units attack in: reading order, or the back row first when a hero's
## rule says so (Dame Hoolet, Combat.side_rules).


static func of(units: Array[CombatUnit], rules: Dictionary) -> Array[CombatUnit]:
	if not _back_row_first(rules):
		return units
	var out: Array[CombatUnit] = []
	for unit: CombatUnit in units:
		if BoardGeometry.is_back(unit.slot):
			out.append(unit)
	for unit: CombatUnit in units:
		if BoardGeometry.is_front(unit.slot):
			out.append(unit)
	return out


## A slot's place in its side's attack order.
static func rank(rules: Dictionary, slot: int) -> int:
	if not _back_row_first(rules):
		return slot
	return slot - 4 if BoardGeometry.is_back(slot) else slot + 3


static func _back_row_first(rules: Dictionary) -> bool:
	return CoreUtil.to_bool(rules.get("back_row_first", false))
