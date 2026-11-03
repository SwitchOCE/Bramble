class_name BoardGeometry
extends RefCounted
## The 4-3 brick board of rulebook chapter 8. Slots are ints 0-6 in reading order (1.2.3):
## 0 = F1 ... 3 = F4, 4 = B1, 5 = B2, 6 = B3. Everything here is the relations table of 8.2 and
## the summon placement table of 8.4.2, as data.

const SLOTS: int = 7
const FRONT: Array[int] = [0, 1, 2, 3]
const BACK: Array[int] = [4, 5, 6]
const LABELS: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
## 8.2.2 adjacent: next to each other in the same row.
const ADJACENT: Array = [[1], [0, 2], [1, 3], [2], [5], [4, 6], [5]]
## 8.2.1 the slots in front of each slot (only back slots have any).
const IN_FRONT: Array = [[], [], [], [], [0, 1], [1, 2], [2, 3]]
## 8.2.1 the slots behind each slot (only front slots have any).
const BEHIND: Array = [[4], [4, 5], [5, 6], [6], [], [], []]
## 8.4.2 the order in which empty slots are tried for a summon from each source slot.
const SUMMON_ORDER: Array = [
	[1, 2, 3, 4, 5, 6],
	[2, 0, 3, 5, 4, 6],
	[3, 1, 0, 6, 5, 4],
	[2, 1, 0, 6, 5, 4],
	[5, 6, 1, 0, 2, 3],
	[6, 4, 2, 1, 3, 0],
	[5, 4, 3, 2, 1, 0],
]


static func is_front(slot: int) -> bool:
	return slot >= 0 and slot < 4


static func is_back(slot: int) -> bool:
	return slot >= 4 and slot < SLOTS


static func is_valid(slot: int) -> bool:
	return slot >= 0 and slot < SLOTS


static func adjacent(slot: int) -> Array[int]:
	return _ints(ADJACENT[slot])


static func in_front_of(slot: int) -> Array[int]:
	return _ints(IN_FRONT[slot])


static func behind(slot: int) -> Array[int]:
	return _ints(BEHIND[slot])


## 8.2.3 neighbours: adjacent plus in front of and behind.
static func neighbours(slot: int) -> Array[int]:
	var out: Array[int] = adjacent(slot)
	out.append_array(in_front_of(slot))
	out.append_array(behind(slot))
	out.sort()
	return out


## 8.2.6 the enemy slot across from a slot has the same label.
static func across(slot: int) -> int:
	return slot


## 8.4.1-8.4.3: where a summon goes. `occupied[i]` says whether slot i is taken. `source_slot` is
## the source's slot, or -1 for a source with no slot (8.4.3). `own_slot_first` is true for a
## dying unit's own death effect (8.4.1). Returns -1 when the board is full (8.4.5).
static func summon_slot(occupied: Array[bool], source_slot: int, own_slot_first: bool) -> int:
	if source_slot < 0:
		for slot: int in SLOTS:
			if not occupied[slot]:
				return slot
		return -1
	if own_slot_first and not occupied[source_slot]:
		return source_slot
	var order: Array = SUMMON_ORDER[source_slot]
	for candidate: Variant in order:
		var slot: int = candidate
		if not occupied[slot]:
			return slot
	return -1


static func _ints(values: Variant) -> Array[int]:
	var out: Array[int] = []
	var raw: Array = values
	for value: Variant in raw:
		out.append(CoreUtil.to_int(value))
	return out
