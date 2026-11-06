extends RefCounted
## What the recruit screen reads out of a state, without any nodes: spells merged in with the units,
## aiming rules, hero cards, and the "then fight" note.

const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


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


## "then fight Old Tansy": the next opponent's name from the standings; "the ghost" for -1.
static func fight_note(view: Dictionary) -> String:
	var next_id: int = Data.i(view, "next_opponent_id", -2)
	if next_id == -1:
		return "then fight the ghost"
	for entry: Variant in Data.a(view, "standings"):
		var standing: Dictionary = entry
		if Data.i(standing, "player_id", -3) == next_id:
			return "then fight %s" % UiTheme.short_name(Data.s(standing, "name", "?"))
	return ""
