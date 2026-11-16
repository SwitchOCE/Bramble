class_name SlotState
extends RefCounted
## Effects held by one board slot (rulebook 8.5): a stat buff and keywords that whatever unit
## stands in the slot has, plus named marks mechanics read (a guard post). They stay when the
## unit moves, is sold or dies (8.5.1). A fight works on copies (8.5.2); "permanently" writes
## to both.

var attack: int = 0
var health: int = 0
## Keyword mechanic ids the unit in this slot has.
var keywords: Array[StringName] = []
## Mechanic-defined numbers on the slot.
var marks: Dictionary = {}


func duplicate_slot() -> SlotState:
	var copy := SlotState.new()
	copy.attack = attack
	copy.health = health
	copy.keywords = keywords.duplicate()
	copy.marks = marks.duplicate()
	return copy


func mark(key: StringName) -> int:
	return CoreUtil.to_int(marks.get(key, 0))


func view() -> Dictionary:
	var out_marks: Dictionary = {}
	for key: Variant in marks:
		out_marks[str(key)] = marks[key]
	return {
		"attack": attack,
		"health": health,
		"keywords": keywords.map(func(k: StringName) -> String: return String(k)),
		"marks": out_marks,
	}
