class_name BoardGeometry
extends RefCounted
## The 4-3 brick board of rulebook chapter 8. Slots are ints 0-6 in reading order (1.2.3):
## 0 = F1 ... 3 = F4, 4 = B1, 5 = B2, 6 = B3. Everything here is the relations table of 8.2 and
## the summon placement table of 8.4.2, as data.

const SLOTS: int = 7
const FRONT: Array[int] = [0, 1, 2, 3]
const BACK: Array[int] = [4, 5, 6]
const LABELS: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
## The zigzag Pass travels and "touching" reads: F1-B1-F2-B2-F3-B3-F4.
const ZIGZAG: Array[int] = [0, 4, 1, 5, 2, 6, 3]
## 8.2.2 adjacent: next to each other in the same row.
const ADJACENT: Array = [[1], [0, 2], [1, 3], [2], [5], [4, 6], [5]]
## 8.2.1 the slots in front of each slot (only back slots have any).
const IN_FRONT: Array = [[], [], [], [], [0, 1], [1, 2], [2, 3]]
## 8.2.1 the slots behind each slot (only front slots have any).
const BEHIND: Array = [[4], [4, 5], [5, 6], [6], [], [], []]
## 8.2.5 the slot at the other end of each slot's row; -1 for the slots between the ends.
const ROW_END_PARTNER: Array[int] = [3, -1, -1, 0, 6, -1, 4]
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

## Typed copies of the tables above, built once; fights ask for them hundreds of times each.
static var _adjacent_ints: Array = _int_rows(ADJACENT)
static var _in_front_ints: Array = _int_rows(IN_FRONT)
static var _behind_ints: Array = _int_rows(BEHIND)


static func is_front(slot: int) -> bool:
	return slot >= 0 and slot < 4


static func is_back(slot: int) -> bool:
	return slot >= 4 and slot < SLOTS


static func is_valid(slot: int) -> bool:
	return slot >= 0 and slot < SLOTS


static func adjacent(slot: int) -> Array[int]:
	var row: Array[int] = _adjacent_ints[slot]
	return row.duplicate()


static func in_front_of(slot: int) -> Array[int]:
	var row: Array[int] = _in_front_ints[slot]
	return row.duplicate()


static func behind(slot: int) -> Array[int]:
	var row: Array[int] = _behind_ints[slot]
	return row.duplicate()


## 8.2.3 neighbours: adjacent plus in front of and behind.
static func neighbours(slot: int) -> Array[int]:
	var out: Array[int] = adjacent(slot)
	out.append_array(in_front_of(slot))
	out.append_array(behind(slot))
	out.sort()
	return out


## 8.2.5 the other end of this slot's row, or -1 if the slot isn't at an end.
static func row_end_partner(slot: int) -> int:
	return ROW_END_PARTNER[slot]


## 8.2.5 the slots at the ends of a row.
static func is_row_end(slot: int) -> bool:
	return ROW_END_PARTNER[slot] >= 0


## 8.2.7 every slot in the same row as this one, in reading order.
static func row_of(slot: int) -> Array[int]:
	return FRONT if is_front(slot) else BACK


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


## The unbroken run of occupied slots along the zigzag that includes `slot`, in zigzag order. A gap
## cuts it. Empty if the slot itself is empty.
static func touching(occupied: Array[bool], slot: int) -> Array[int]:
	var out: Array[int] = []
	if not is_valid(slot) or not occupied[slot]:
		return out
	var at: int = ZIGZAG.find(slot)
	var first: int = at
	while first > 0 and occupied[ZIGZAG[first - 1]]:
		first -= 1
	var index: int = first
	while index < ZIGZAG.size() and occupied[ZIGZAG[index]]:
		out.append(ZIGZAG[index])
		index += 1
	return out


## Pass goes to the last occupied zigzag slot other than its source. Gaps do not matter.
## A sold source is already absent; -1 means there is nobody else to pass to.
static func pass_landing(occupied: Array[bool], slot: int) -> int:
	for index: int in range(ZIGZAG.size() - 1, -1, -1):
		var candidate: int = ZIGZAG[index]
		if candidate != slot and occupied[candidate]:
			return candidate
	return -1


## A summon that names where it goes: "behind" tries the slots behind `anchor` and fails if they
## are full (8.4.6); "behind_or_nearest" falls back on 8.4.2; anything else is 8.4.1-8.4.3.
static func named_slot(occupied: Array[bool], at: String, anchor: int, own_first: bool) -> int:
	if at == "subject_slot":
		return anchor if is_valid(anchor) and not occupied[anchor] else -1
	if at == "behind" or at == "behind_or_nearest":
		if is_valid(anchor):
			for slot: int in behind(anchor):
				if not occupied[slot]:
					return slot
		if at == "behind":
			return -1
	return summon_slot(occupied, anchor, own_first)


## How many slots adjacent to this one (same row, 8.2.2) are empty.
static func empty_adjacent(occupied: Array[bool], slot: int) -> int:
	var count: int = 0
	for other: int in adjacent(slot):
		if not occupied[other]:
			count += 1
	return count


static func _int_rows(table: Array) -> Array:
	var out: Array = []
	for row: Variant in table:
		out.append(_ints(row))
	return out


static func _ints(values: Variant) -> Array[int]:
	var out: Array[int] = []
	var raw: Array = values
	for value: Variant in raw:
		out.append(CoreUtil.to_int(value))
	return out
