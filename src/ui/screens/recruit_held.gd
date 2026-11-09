extends RefCounted
## What the recruit screen says and shows about Bellies, birds away and Nests. Reads only a state
## dict, so tests need no screen.

const Data := preload("res://src/ui/view_data.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")

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
				"Flies for no sale gold. It comes home in %s."
				% _turns(Data.i(unit, "fly_south", 2))
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
			mark["pass3_content"] = Data.b(bird, "pass3_content")
			mark["bird_attack"] = Data.i(bird, "attack")
			mark["bird_health"] = Data.i(bird, "health", 2)
			var pass3: bool = Data.b(bird, "pass3_content")
			var attack: int = Data.i(
				bird, "egg_attack", 0 if pass3 else ceili(Data.i(bird, "attack") / 2.0)
			)
			var health: int = Data.i(
				bird, "egg_health", 1 if pass3 else ceili(Data.i(bird, "health", 2) / 2.0)
			)
			# Rings belong to the Egg's slot, after its own body is determined.
			mark["egg_attack"] = maxi(0, attack + Data.i(mark, "slot_attack"))
			mark["egg_health"] = maxi(1, health + Data.i(mark, "slot_health"))
	return marks


## An empty own Nest opens the Egg's card, with both bodies and the live homecoming countdown.
static func egg_card(mark: Dictionary) -> Dictionary:
	if not Data.b(mark, "nest") or not mark.has("bird_attack"):
		return {}
	return {
		"def_id": "nest_egg",
		"name": "Egg",
		"type_word": "Nest",
		"tribes": [],
		"keywords": ["Nest"],
		"attack": Data.i(mark, "egg_attack"),
		"health": Data.i(mark, "egg_health"),
		"text":
		(
			"%s comes home in %s.\nBird: %d/%d."
			% [
				Data.s(mark, "nest_name"),
				_turns(Data.i(mark, "nest_left")),
				Data.i(mark, "bird_attack"),
				Data.i(mark, "bird_health"),
			]
		),
	}


## A Great Lump dragged to a slot reads its Bird, before Egg auras, and that slot's Rings.
## Remove the old aura first so moving between Nests never adds the borrowed body twice.
static func lump_preview(unit: Dictionary, mark: Dictionary) -> Dictionary:
	if Data.s(unit, "def_id") != "great_lump":
		return unit
	var out: Dictionary = unit.duplicate(true)
	var layers: Dictionary = Data.d(unit, "stat_layers")
	var factor: int = 2 if Data.b(unit, "golden") else 1
	var share: float = Data.f(
		unit, "nest_multiplier", float(factor) if Data.b(unit, "pass3_content") else factor / 2.0
	)
	var bonus := Vector2i.ZERO
	if Data.b(mark, "nest"):
		bonus = Vector2i(
			ceili(Data.i(mark, "bird_attack") * share), ceili(Data.i(mark, "bird_health") * share)
		)
	out["attack"] = maxi(
		0,
		(
			Data.i(unit, "attack")
			- Data.i(layers, "aura_attack")
			+ Data.i(mark, "slot_attack")
			+ bonus.x
		)
	)
	out["health"] = maxi(
		1,
		(
			Data.i(unit, "health")
			- Data.i(layers, "aura_health")
			+ Data.i(mark, "slot_health")
			+ bonus.y
		)
	)
	return out


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
		"An empty Nest holds a 0/1 Egg."
		if Data.b(mark, "pass3_content")
		else "An empty Nest holds an Egg with half the Bird's stats."
	)
	if mark.has("egg_attack"):
		egg = (
			"Empty, a %d/%d Egg fights here."
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
		var landing: String = ""
		if bird.has("home_attack") and bird.has("home_health"):
			landing = (
				" · %s/%s → %s/%s"
				% [
					StatNumbers.compact(Data.i(bird, "attack")),
					StatNumbers.compact(Data.i(bird, "health")),
					StatNumbers.compact(Data.i(bird, "home_attack")),
					StatNumbers.compact(Data.i(bird, "home_health")),
				]
			)
		lines.append(
			(
				"%s: home in %s%s%s."
				% [Data.s(bird, "name"), _turns(Data.i(bird, "turns_left", 0)), landing, where]
			)
		)
	for value: Variant in Data.a(state, "doorstep"):
		var bird: Dictionary = value
		lines.append("%s: on the doorstep until your hand has room." % Data.s(bird, "name"))
	if lines.is_empty():
		return {}
	return {
		"name": "Birds away", "kind": "spell", "type_word": "Fly South", "text": "\n".join(lines)
	}


static func _turns(count: int) -> String:
	return "1 turn" if count == 1 else "%d turns" % count


static func sell_gold(unit: Dictionary, round_number: int) -> int:
	return (
		0
		if sell_word(unit, round_number) == "Fly south"
		else Data.i(unit, "sell_payout", Data.i(unit, "sell_value", 1))
	)
