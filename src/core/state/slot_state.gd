class_name SlotState
extends RefCounted
## Effects held by one board slot (rulebook 8.5): a stat buff and keywords that whatever unit
## stands in the slot has (a Guard post is a slot keyword), and its Renown. They stay when the
## unit moves, is sold or dies (8.5.1). A fight works on copies (8.5.2); "permanently" writes
## to both. Renown gained in a fight goes to the real slot only (FightSide.add_renown).

var attack: int = 0
var health: int = 0
## Keyword mechanic ids the unit in this slot has.
var keywords: Array[StringName] = []
## Renown (pitch-pigeon 1, variant A): +1/+1 for each to the unit that starts a fight here and to
## each reservist who steps in here; nothing else gets it (FightAuras, renown_slot). Permanent.
var renown: int = 0


func duplicate_slot() -> SlotState:
	var copy := SlotState.new()
	copy.attack = attack
	copy.health = health
	copy.keywords = keywords.duplicate()
	copy.renown = renown
	return copy


func view() -> Dictionary:
	return {
		"attack": attack,
		"health": health,
		"keywords": keywords.map(func(k: StringName) -> String: return String(k)),
		"renown": renown,
	}
