extends RefCounted
## What the recruit screen reads out of a state, without any nodes: spells merged in with the units,
## aiming rules, hero cards, and the "then fight" note.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const GamePort := preload("res://src/ui/adapter/game_port.gd")

## The line a Pass travels along, F1-B1-F2-B2-F3-B3-F4 (docs/ideation/content/SLICE.md).
const ZIGZAG: Array[int] = [0, 4, 1, 5, 2, 6, 3]
const SLOT_NAMES: PackedStringArray = ["F1", "F2", "F3", "F4", "B1", "B2", "B3"]
## Acorn items in size order; three of one combine into the next.
const ACORN_SIZES: PackedStringArray = ["Acorn", "Stash", "Great Hoard"]


## The state as this screen shows it: spells on the shelf after the units, and spells and items in
## the hand after the units. Each keeps its index in the list the port wants back.
static func with_cards(raw: Dictionary) -> Dictionary:
	var merged: Dictionary = raw.duplicate()
	merged["shop"] = _tagged(raw, "shop", "shop_spells")
	merged["hand"] = _tagged(raw, "hand", "hand_items")
	return merged


static func _tagged(raw: Dictionary, units_key: String, cards_key: String) -> Array:
	var out: Array = Data.a(raw, units_key).duplicate()
	var cards: Array = Data.a(raw, cards_key)
	for i: int in cards.size():
		var source: Dictionary = cards[i]
		var card: Dictionary = source.duplicate()
		card["card_index"] = i
		out.append(card)
	return out


## Whether a spell or power with this aim can land on a slot.
static func aim_fits(aim: String, has_unit: bool) -> bool:
	match aim:
		"unit":
			return has_unit
		"empty_slot":
			return not has_unit
	return true


## A unit plays into an empty slot, or onto a unit it merges into (its "merge_into" is a tribe or
## "any").
static func can_play_on(unit: Dictionary, target: Dictionary) -> bool:
	if target.is_empty():
		return true
	var fits: String = Data.s(unit, "merge_into")
	return fits == "any" or (fits != "" and Data.a(target, "tribes").has(fits))


## Hero offers as cards for the picker.
static func hero_cards(options: Array) -> Array:
	var cards: Array = []
	for entry: Variant in options:
		var hero: Dictionary = entry
		cards.append(hero_card(hero))
	return cards


static func hero_card(hero: Dictionary) -> Dictionary:
	return {
		"def_id": Data.s(hero, "id"),
		"name": Data.s(hero, "name"),
		"kind": "spell",
		"type_word": "Hero",
		"text": Data.s(hero, "text"),
		"cost": Data.i(hero, "cost", 0),
		"tribes": [],
	}


## "then fight Old Tansy"; "" when the next opponent isn't known.
static func fight_note(view: Dictionary) -> String:
	var opponent: String = next_name(view)
	return "" if opponent.is_empty() else "then fight %s" % opponent


## The next opponent's name, for "then fight" and the scouting panel. "" if unknown.
static func next_name(view: Dictionary) -> String:
	var next_id: int = Data.i(view, "next_opponent_id", -2)
	if next_id == -1:
		return "the ghost"
	for entry: Variant in Data.a(view, "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -3) == next_id:
			return UiTheme.short_name(Data.s(standing, "name", "?"))
	return ""


## 1 for "Pass right", -1 for "Pass left", 0 for a card with no Pass.
static func pass_direction(view: Dictionary) -> int:
	var text: String = Data.s(view, "text")
	if text.contains("Pass right"):
		return 1
	return -1 if text.contains("Pass left") else 0


## The unit a Pass from `slot` ends on: along the zigzag through touching units, and the last one
## keeps it. -1 when the next place along is empty, so a gap is a real cost.
static func pass_landing(board: Array, slot: int, direction: int) -> int:
	var at: int = ZIGZAG.find(slot) + direction
	var landing: int = -1
	while at >= 0 and at < ZIGZAG.size() and board[ZIGZAG[at]] is Dictionary:
		landing = ZIGZAG[at]
		at += direction
	return landing


## Where a card's Pass lands if it goes to `target` (-1: it leaves, and the Pass starts from
## from_slot, the slot it left). -1 when it has no Pass or nobody to land on.
static func pass_preview(board: Array, card: Dictionary, from_slot: int, target: int) -> int:
	var direction: int = pass_direction(card)
	if direction == 0 or board.size() < ZIGZAG.size():
		return -1
	var after: Array = board.duplicate()
	if from_slot >= 0:
		after[from_slot] = after[target] if target >= 0 else null
	if target >= 0:
		after[target] = card
	return pass_landing(after, target if target >= 0 else from_slot, direction)


## One entry per slot from state slot_effects: a Rainbow entry (its name says band or rainbow) is a
## band, and anything else that gives power there reads as a Ring with its summed stats.
static func slot_marks(view: Dictionary) -> Array:
	var effects: Array = Data.a(view, "slot_effects")
	var out: Array = []
	for slot: int in SLOT_NAMES.size():
		var entries: Array = effects[slot] if slot < effects.size() else []
		var attack: int = 0
		var health: int = 0
		var mark: Dictionary = {"ring": "", "has_ring": false, "band": false, "text": ""}
		for entry: Variant in entries:
			var effect: Dictionary = entry
			var word: String = Data.s(effect, "name").to_lower()
			if word.contains("band") or word.contains("rainbow"):
				mark["band"] = true
			else:
				mark["has_ring"] = true
				attack += Data.i(effect, "attack", 0)
				health += Data.i(effect, "health", 0)
			var line: String = Data.s(effect, "text")
			if not line.is_empty():
				mark["text"] = (str(mark["text"]) + " " + line).strip_edges()
		if attack != 0 or health != 0:
			mark["ring"] = "%+d/%+d" % [attack, health]
		out.append(mark)
	return out


## The unit's view with what its slot gives and how long it has stood there, for the full text.
static func with_slot_note(unit: Dictionary, mark: Dictionary, slot: int) -> Dictionary:
	var view: Dictionary = unit.duplicate()
	var lines: PackedStringArray = [Data.s(view, "text")]
	var note: String = slot_note(mark, slot)
	if not note.is_empty():
		lines.append(note)
	var turns: int = Data.i(view, "turns_in_slot", 0)
	if turns > 0:
		lines.append("In this slot for %d turn%s." % [turns, "" if turns == 1 else "s"])
	view["text"] = "\n".join(lines).strip_edges()
	return view


## What lies on a slot in words; "" for a bare slot.
static func slot_note(mark: Dictionary, slot: int) -> String:
	var parts: PackedStringArray = []
	if mark.get("has_ring", false) == true:
		parts.append(("Ring %s" % str(mark.get("ring", ""))).strip_edges())
	if mark.get("band", false) == true:
		parts.append("Rainbow band")
	if parts.is_empty():
		return ""
	var note: String = "%s: %s." % [SLOT_NAMES[slot], ", ".join(parts)]
	var extra: String = str(mark.get("text", ""))
	return note if extra.is_empty() else "%s %s" % [note, extra]


## Non-golden copies owned (hand and board) per def_id.
static func copies(from_state: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for zone: String in ["hand", "board"]:
		for entry: Variant in Data.a(from_state, zone):
			if entry is Dictionary:
				var view: Dictionary = entry
				if not Data.b(view, "golden", false):
					var def_id: String = Data.s(view, "def_id")
					out[def_id] = Data.i(out, def_id, 0) + 1
	return out


## "Three Acorns made a Stash." when a bigger size just arrived and the smaller ones went.
static func combine_note(before: Dictionary, after: Dictionary) -> String:
	for i: int in range(1, ACORN_SIZES.size()):
		var big: String = ACORN_SIZES[i]
		var small: String = ACORN_SIZES[i - 1]
		var grew: bool = _named(after, big) > _named(before, big)
		if grew and _named(after, small) < _named(before, small):
			return "Three %ss made a %s." % [small, big]
	return ""


static func _named(view: Dictionary, card_name: String) -> int:
	var count: int = 0
	for entry: Variant in Data.a(view, "hand"):
		var item: Dictionary = entry
		count += 1 if Data.s(item, "name") == card_name else 0
	return count


## Shop to board: buy, then play whatever the buy put in the hand. That is the bought unit
## (same iid), or, if the buy made a triple, the one new hand unit (the golden). Never assumes
## the hand's last slot.
static func buy_and_play(port: GamePort, shop_index: int, slot: int) -> String:
	var before: Dictionary = {}
	for entry: Variant in Data.a(port.get_state(), "hand"):
		var old: Dictionary = entry
		before[Data.i(old, "iid", -1)] = true
	var bought_iid: int = Data.i(
		Data.entry(Data.a(port.get_state(), "shop"), shop_index), "iid", -1
	)
	var reason: String = port.buy(shop_index)
	if not reason.is_empty():
		return reason
	var hand: Array = Data.a(port.get_state(), "hand")
	var new_index: int = -1
	var new_count: int = 0
	for i: int in hand.size():
		var iid: int = Data.i(Data.entry(hand, i), "iid", -1)
		if iid == bought_iid:
			return port.play(i, slot)
		if not before.has(iid):
			new_index = i
			new_count += 1
	if new_count == 1:
		return port.play(new_index, slot)
	return "Bought; it's in your hand"
