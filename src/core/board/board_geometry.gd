class_name BoardGeometry
extends RefCounted
## Rulebook chapter 8 as instance data (prototype lesson: geometry as instance data, so a
## modifier can change the board's shape in one place). Slots are ints in reading order (1.2.3):
## the front row first, then the back row; for the 4-3 board 0 = F1 ... 3 = F4, 4 = B1 ... 6 = B3.
## The tables are built from each slot's row and x position (8.1.3), so they hold for any row
## sizes where the back row sits between front slots. Cards and the engine ask this module; they
## never do slot arithmetic.

var slot_count: int = 0
var labels: PackedStringArray = []
var front: Array[int] = []
var back: Array[int] = []
var _x: PackedFloat64Array = []
var _adjacent: Array = []
var _in_front: Array = []
var _behind: Array = []
var _summon_order: Array = []


## The working board: 4 front, 3 back (8.1.1-8.1.2), or other row sizes.
static func standard(front_count: int = 4, back_count: int = 3) -> BoardGeometry:
	var geometry := BoardGeometry.new()
	geometry._build(front_count, back_count)
	return geometry


func _build(front_count: int, back_count: int) -> void:
	slot_count = front_count + back_count
	for i: int in front_count:
		front.append(i)
		labels.append("F%d" % (i + 1))
		_x.append(float(i))
	for i: int in back_count:
		back.append(front_count + i)
		labels.append("B%d" % (i + 1))
		_x.append(float(i) + 0.5)
	for slot: int in slot_count:
		_adjacent.append(_same_row_within(slot, 1.0))
		_in_front.append(_other_row_within(slot, 0.5) if is_back(slot) else ([] as Array[int]))
		_behind.append(_other_row_within(slot, 0.5) if is_front(slot) else ([] as Array[int]))
		_summon_order.append(_nearest_order(slot))


func _same_row_within(slot: int, distance: float) -> Array[int]:
	var out: Array[int] = []
	for other: int in row_of(slot):
		if other != slot and absf(_x[other] - _x[slot]) <= distance:
			out.append(other)
	return out


func _other_row_within(slot: int, distance: float) -> Array[int]:
	var out: Array[int] = []
	for other: int in back if is_front(slot) else front:
		if absf(_x[other] - _x[slot]) <= distance:
			out.append(other)
	return out


## 8.4.2: same row first, then the other row; nearest by x, a tie goes to the right.
func _nearest_order(slot: int) -> Array[int]:
	var out: Array[int] = []
	for row: Array[int] in [row_of(slot), back if is_front(slot) else front]:
		var others: Array[int] = []
		for other: int in row:
			if other != slot:
				others.append(other)
		var origin: float = _x[slot]
		others.sort_custom(
			func(a: int, b: int) -> bool:
				var da: float = absf(_x[a] - origin)
				var db: float = absf(_x[b] - origin)
				return da < db if da != db else _x[a] > _x[b]
		)
		out.append_array(others)
	return out


func is_valid(slot: int) -> bool:
	return slot >= 0 and slot < slot_count


func is_front(slot: int) -> bool:
	return front.has(slot)


func is_back(slot: int) -> bool:
	return back.has(slot)


func label(slot: int) -> String:
	return labels[slot] if is_valid(slot) else "-"


func x_of(slot: int) -> float:
	return _x[slot]


## 8.2.7 the slots of this slot's row, in reading order.
func row_of(slot: int) -> Array[int]:
	return front if is_front(slot) else back


## 8.2.2 next to each other in the same row.
func adjacent(slot: int) -> Array[int]:
	var row: Array[int] = _adjacent[slot]
	return row.duplicate()


## 8.2.1 the front slots a back slot sits between.
func in_front_of(slot: int) -> Array[int]:
	var row: Array[int] = _in_front[slot]
	return row.duplicate()


## 8.2.1 the back slots touching a front slot.
func behind(slot: int) -> Array[int]:
	var row: Array[int] = _behind[slot]
	return row.duplicate()


## 8.2.3 adjacent plus in front of and behind, in reading order.
func neighbours(slot: int) -> Array[int]:
	var out: Array[int] = adjacent(slot)
	out.append_array(in_front_of(slot))
	out.append_array(behind(slot))
	out.sort()
	return out


## 8.2.3 how many neighbour steps each slot is from `slot` (0 for itself), through empty slots
## too: one entry per slot, in reading order. "Nearest" in a card's text (Hand-me-down) reads it.
func neighbour_steps(slot: int) -> Array[int]:
	var out: Array[int] = []
	out.resize(slot_count)
	out.fill(-1)
	if not is_valid(slot):
		return out
	out[slot] = 0
	var frontier: Array[int] = [slot]
	while not frontier.is_empty():
		var next: Array[int] = []
		for at: int in frontier:
			for other: int in neighbours(at):
				if out[other] < 0:
					out[other] = out[at] + 1
					next.append(other)
		frontier = next
	return out


## 8.2.6 the enemy slot with the same label.
func across(slot: int) -> int:
	return slot


## 8.4.2 the order empty slots are tried for a summon from `slot`.
func summon_order(slot: int) -> Array[int]:
	var row: Array[int] = _summon_order[slot]
	return row.duplicate()


## 8.4.1-8.4.5: where a summon goes. `occupied[i]` says whether slot i is taken. `source_slot`
## is -1 for a source with no slot (8.4.3). `own_slot_first` is for a dying unit's own death
## or return effect (8.4.1). Returns -1 when the board is full (8.4.5).
func summon_slot(occupied: Array[bool], source_slot: int, own_slot_first: bool) -> int:
	if not is_valid(source_slot):
		for slot: int in slot_count:
			if not occupied[slot]:
				return slot
		return -1
	if own_slot_first and not occupied[source_slot]:
		return source_slot
	var order: Array[int] = _summon_order[source_slot]
	for slot: int in order:
		if not occupied[slot]:
			return slot
	return -1
