class_name LegacyHunters
extends RefCounted
## Frozen Hunter definitions preserve pass 2 tests; current games load the native pass 3 cards.

const BOG := preload("res://tests/core/legacy_bog.gd")


static func library() -> UnitLibrary:
	var current: UnitLibrary = BOG.library()
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_hunters_units.json")
	)
	var replacements: Dictionary = {}
	for card: Dictionary in parsed["units"]:
		replacements[str(card["id"])] = card
	var out := UnitLibrary.new()
	for card: Dictionary in current.all_units():
		var replacement: Dictionary = replacements.get(str(card["id"]), card)
		out.register_unit(replacement)
	for card: Dictionary in current.all_cards():
		out.register_card(card)
	for hero: Dictionary in current.all_heroes():
		out.register_hero(hero)
	return out
