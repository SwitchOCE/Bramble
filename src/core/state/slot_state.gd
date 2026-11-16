class_name SlotState
extends RefCounted
## Effects held by one board slot (rulebook 8.5): a stat buff and keywords that whatever unit
## stands in the slot has (a Guard post is a slot keyword). They stay when the
## unit moves, is sold or dies (8.5.1). A fight works on copies (8.5.2); "permanently" writes
## to both.

var attack: int = 0
var health: int = 0
## Keyword mechanic ids the unit in this slot has.
var keywords: Array[StringName] = []


func duplicate_slot() -> SlotState:
	var copy := SlotState.new()
	copy.attack = attack
	copy.health = health
	copy.keywords = keywords.duplicate()
	return copy


func view() -> Dictionary:
	return {
		"attack": attack,
		"health": health,
		"keywords": keywords.map(func(k: StringName) -> String: return String(k)),
	}
