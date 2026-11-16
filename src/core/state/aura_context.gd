class_name AuraContext
extends RefCounted
## What an aura may read (12.2.1) in either phase: the board it sits on, the other board's size
## in a fight, and its player's lasting numbers and heaps. Rebuilt whenever auras are
## recalculated, so an aura that reads any of these follows them.

var geometry: BoardGeometry
## The unit defs on this board by slot (null for an empty slot).
var defs: Array[UnitDef] = []
## Units on the other board in a fight; -1 in the Recruit Phase.
var enemy_count: int = -1
var in_combat: bool = false
## The player's lasting numbers (PlayerState.counters, or the fight's copy).
var counters: Dictionary = {}
## The player's heaps by name (CardHeap).
var heaps: Dictionary = {}


func own_count() -> int:
	var count: int = 0
	for def: UnitDef in defs:
		if def != null:
			count += 1
	return count


## The other board has more units. Never true outside a fight.
func outnumbered() -> bool:
	return in_combat and enemy_count > own_count()


func count_tribe(tribe: String) -> int:
	var count: int = 0
	for def: UnitDef in defs:
		if def != null and def.has_tribe(tribe):
			count += 1
	return count


func def_at(slot: int) -> UnitDef:
	return defs[slot] if slot >= 0 and slot < defs.size() else null


func counter(key: StringName) -> int:
	return CoreUtil.to_int(counters.get(key, 0))


func heap_size(heap_name: StringName) -> int:
	var heap: CardHeap = heaps.get(heap_name, null)
	return heap.size() if heap != null else 0
