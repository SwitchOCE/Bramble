class_name AuraContext
extends RefCounted
## What an aura may read (12.2.1) in either phase: the board it sits on, each unit's numbers
## as they stand, the fixed Outnumbered count in a fight, and its player's lasting numbers and
## heaps. Rebuilt whenever auras are
## recalculated, so an aura that reads any of these follows them.

var geometry: BoardGeometry
## The unit defs on this board by slot (null for an empty slot).
var defs: Array[UnitDef] = []
var reservist_slots: Array[int] = []
var in_combat: bool = false
## The player's lasting numbers (PlayerState.counters, or the fight's copy).
var counters: Dictionary = {}
## The player's heaps by name (CardHeap).
var heaps: Dictionary = {}
## Each slot's unit's lasting numbers (Unit.counters; Supply), {} for an empty slot.
var unit_counters: Array[Dictionary] = []
## Outnumbered: fixed at fight start (Combat.outnumbered_by); 0 outside a fight.
var outnumbered_by: int = 0
## Each slot's unit's numbers as they stand (Attack, maximum Health, Health), for auras that lend
## a unit's own total (Lends): read them with attack_at, max_health_at, health_at.
var stats: Array[Vector3i] = []
## Set when an aura read stats: the core then runs the aura pass a second time on the totals.
var read_stats: bool = false


func own_count() -> int:
	var count: int = 0
	for def: UnitDef in defs:
		if def != null:
			count += 1
	return count


func count_tribe(tribe: String) -> int:
	var count: int = 0
	for def: UnitDef in defs:
		if def != null and def.has_tribe(tribe):
			count += 1
	return count


func def_at(slot: int) -> UnitDef:
	return defs[slot] if slot >= 0 and slot < defs.size() else null


## A number on the unit in `slot` (Unit.counters), 0 if none.
func unit_counter(slot: int, key: StringName) -> int:
	if slot < 0 or slot >= unit_counters.size():
		return 0
	return CoreUtil.to_int(unit_counters[slot].get(key, 0))


func counter(key: StringName) -> int:
	return CoreUtil.to_int(counters.get(key, 0))


func heap_size(heap_name: StringName) -> int:
	var heap: CardHeap = heaps.get(heap_name, null)
	return heap.size() if heap != null else 0


## The Attack of the unit in `slot` as it stands (Renown and auras included), 0 for an
## empty slot. Lends: "extra Attack equal to this unit's Attack".
func attack_at(slot: int) -> int:
	return _stat(slot).x


## The maximum Health of the unit in `slot` as it stands (Renown and auras included).
func max_health_at(slot: int) -> int:
	return _stat(slot).y


## The current Health of the unit in `slot` (maximum Health less damage in a fight).
func health_at(slot: int) -> int:
	return _stat(slot).z


func _stat(slot: int) -> Vector3i:
	read_stats = true
	if slot < 0 or slot >= stats.size():
		return Vector3i.ZERO
	return stats[slot]
