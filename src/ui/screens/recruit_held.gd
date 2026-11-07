extends RefCounted
## What the recruit screen says and shows about Bellies, birds away and Nests. Reads only a state
## dict, so tests need no screen.

const Data := preload("res://src/ui/view_data.gd")

const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]


## Whether this board unit can take that one in now.
static func can_swallow(target: Dictionary, moved: Dictionary) -> bool:
	if target.is_empty() or moved.is_empty() or target == moved:
		return false
	if Data.s(moved, "kind") == "spell" or not Data.a(moved, "held").is_empty():
		return false
	return Data.i(target, "belly", 0) > Data.a(target, "held").size()


## Slots with a Belly that has room for this unit.
static func bellies_for(board: Array, moved: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for slot: int in board.size():
		if board[slot] is Dictionary and can_swallow(Data.entry(board, slot), moved):
			out.append(slot)
	return out


## The slip on a tile: what's inside against how much fits.
static func belly_slip(unit: Dictionary) -> String:
	var size: int = Data.i(unit, "belly", 0)
	if size <= 0:
		return ""
	return "In %d/%d" % [Data.a(unit, "held").size(), size]


## The unit's view with who's inside, for the full text. Last in comes out first.
static func with_inside(unit: Dictionary) -> Dictionary:
	var held: Array = Data.a(unit, "held")
	if held.is_empty():
		return unit
	var names: PackedStringArray = []
	for index: int in range(held.size() - 1, -1, -1):
		var inside: Dictionary = Data.entry(held, index)
		names.append(
			(
				"%s %d/%d"
				% [Data.s(inside, "name"), Data.i(inside, "attack", 0), Data.i(inside, "health", 0)]
			)
		)
	var view: Dictionary = unit.duplicate()
	var line: String = "Inside, next out first: %s." % ", ".join(names)
	view["text"] = ("%s\n%s" % [Data.s(unit, "text"), line]).strip_edges()
	return view


## What the sell button says: a bird that has fought flies, and a Belly lets out what it holds.
static func sell_word(unit: Dictionary, round_number: int) -> String:
	if Data.i(unit, "fly_south", 0) <= 0:
		return "Sell"
	if Data.b(unit, "plain_copy", false):
		return "Sell for good"
	return "Fly south" if Data.i(unit, "played_round", -1) != round_number else "Sell for good"


static func sell_note(unit: Dictionary, round_number: int) -> String:
	if not Data.a(unit, "held").is_empty():
		return "Selling this lets out what's inside."
	match sell_word(unit, round_number):
		"Fly south":
			return (
				"Flies for no sale gold. It comes home in %d turns." % Data.i(unit, "fly_south", 2)
			)
		"Sell for good":
			if Data.b(unit, "plain_copy", false):
				return "A plain copy: a sale is final."
			return "Played or landed this turn, so a sale is final."
	return ""


## Slot marks with each slot's Nest: "nest" true, "nest_left" turns (-1 unseen), "nest_name".
static func with_nests(marks: Array, away: Array) -> Array:
	for value: Variant in away:
		var bird: Dictionary = value
		var slot: int = Data.i(bird, "nest", -1)
		if slot >= 0 and slot < marks.size():
			var mark: Dictionary = marks[slot]
			mark["nest"] = true
			mark["nest_left"] = Data.i(bird, "turns_left", 0)
			mark["nest_name"] = Data.s(bird, "name")
			var goose: bool = Data.s(bird, "def_id") == "mother_goose"
			var attack: int = 0 if goose else ceili(Data.i(bird, "attack") / 2.0)
			var health: int = 2 if goose else ceili(Data.i(bird, "health", 2) / 2.0)
			# Rings belong to the Egg's slot, after the away Bird's stats have been halved.
			mark["egg_attack"] = maxi(0, attack + Data.i(mark, "slot_attack"))
			mark["egg_health"] = maxi(1, health + Data.i(mark, "slot_health"))
	return marks


## A scouted board shows where its Nests are, never who's away.
static func with_their_nests(marks: Array, nests: Array) -> Array:
	for value: Variant in nests:
		var slot: int = Data.as_int(value)
		if slot >= 0 and slot < marks.size():
			var mark: Dictionary = marks[slot]
			mark["nest"] = true
			mark["nest_left"] = -1
	return marks


static func nest_note(mark: Dictionary) -> String:
	if not Data.b(mark, "nest", false):
		return ""
	var left: int = Data.i(mark, "nest_left", -1)
	var egg: String = (
		"An empty Nest holds an Egg with half the Bird's Attack and Health, rounded up. "
		+ "Mother Goose's own Egg stays 0/2."
	)
	if mark.has("egg_attack"):
		egg = (
			"With nobody on it, a %d/%d Egg fights here with no text."
			% [Data.i(mark, "egg_attack"), Data.i(mark, "egg_health")]
		)
		if Data.i(mark, "slot_attack") != 0 or Data.i(mark, "slot_health") != 0:
			egg += " Ring stats are included."
	if left < 0:
		return "A Nest: a bird of theirs is away. %s" % egg
	return "A Nest: %s comes home in %s. %s" % [Data.s(mark, "nest_name"), _turns(left), egg]


## The card panel when nothing's selected and birds are out: who's away, who's waiting for room.
static func sky_card(state: Dictionary) -> Dictionary:
	var lines: PackedStringArray = []
	for value: Variant in Data.a(state, "away"):
		var bird: Dictionary = value
		var slot: int = Data.i(bird, "nest", -1)
		var where: String = " (Nest on %s)" % SLOT_NAMES[slot] if slot >= 0 else ""
		lines.append(
			(
				"%s: home in %s%s."
				% [Data.s(bird, "name"), _turns(Data.i(bird, "turns_left", 0)), where]
			)
		)
	for value: Variant in Data.a(state, "doorstep"):
		var bird: Dictionary = value
		lines.append(
			"%s: on the doorstep. It lands when your hand has room." % Data.s(bird, "name")
		)
	if lines.is_empty():
		return {}
	return {
		"name": "Birds away", "kind": "spell", "type_word": "Fly South", "text": "\n".join(lines)
	}


static func _turns(count: int) -> String:
	return "1 turn" if count == 1 else "%d turns" % count


static func sell_gold(unit: Dictionary, round_number: int) -> int:
	return 0 if sell_word(unit, round_number) == "Fly south" else Data.i(unit, "sell_value", 1)
