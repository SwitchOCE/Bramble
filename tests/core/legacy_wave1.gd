class_name LegacyWave1
extends RefCounted
## Archived card definitions keep old mechanic regression suites meaningful after a redesign.
## Opt-in only: real sessions, benches and all pass 3 tests load the current library.


static func library() -> UnitLibrary:
	var current: UnitLibrary = UnitLibrary.load_dir()
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_wave1_units.json")
	)
	var replacements: Dictionary = {}
	for card: Dictionary in parsed["units"]:
		replacements[str(card["id"])] = card
	var out := UnitLibrary.new()
	for card: Dictionary in current.all_units():
		var raw: Dictionary = replacements.get(str(card["id"]), card)
		out.register_unit(raw)
	for card: Dictionary in current.all_cards():
		out.register_card(card)
	for hero: Dictionary in current.all_heroes():
		out.register_hero(hero)
	return out
