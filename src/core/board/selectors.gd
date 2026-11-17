class_name Selectors
extends RefCounted
## The selector library (prototype lesson: write each positional selector once). A selector
## names a set of occupied slots on the same board as `slot`, in reading order. Both phases
## use it: the recruit board and each side of a combat.
##   self, adjacent, behind, in_front, neighbours, front_row, back_row, all, others

const NAMES: PackedStringArray = [
	"self", "adjacent", "behind", "in_front", "neighbours", "front_row", "back_row", "all", "others"
]


static func is_known(selector: String) -> bool:
	return NAMES.has(selector)


## `slot` is the source's slot (or last-known slot, 12.2.3); -1 means no slot, for which only
## the board-wide selectors find anything.
static func slots(
	geometry: BoardGeometry, slot: int, occupied: Array[bool], selector: String
) -> Array[int]:
	var candidates: Array[int] = []
	var has_slot: bool = geometry.is_valid(slot)
	match selector:
		"self":
			if has_slot:
				candidates.append(slot)
		"adjacent":
			if has_slot:
				candidates = geometry.adjacent(slot)
		"behind":
			if has_slot:
				candidates = geometry.behind(slot)
		"in_front":
			if has_slot:
				candidates = geometry.in_front_of(slot)
		"neighbours":
			if has_slot:
				candidates = geometry.neighbours(slot)
		"front_row":
			candidates = geometry.front.duplicate()
		"back_row":
			candidates = geometry.back.duplicate()
		"all", "others":
			for other: int in geometry.slot_count:
				if selector == "all" or other != slot:
					candidates.append(other)
	var out: Array[int] = []
	for candidate: int in candidates:
		if occupied[candidate]:
			out.append(candidate)
	out.sort()
	return out
