class_name LegacyWave1
extends RefCounted
## Archived card definitions keep old mechanic regression suites meaningful after a redesign.
## Opt-in only: real sessions, benches and all pass 3 tests load the current library.


static func library(restore_hunters: bool = true) -> UnitLibrary:
	var current: UnitLibrary = UnitLibrary.load_dir()
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_wave1_units.json")
	)
	var replacements: Dictionary = {}
	for card: Dictionary in parsed["units"]:
		replacements[str(card["id"])] = card
	# Keep rollback libraries entirely pre-pass-3 as later tribe waves replace shared IDs.
	var bog: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_bog_units.json")
	)
	for card: Dictionary in bog["units"]:
		replacements[str(card["id"])] = card
	var oozes: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_oozes_units.json")
	)
	for card: Dictionary in oozes["units"]:
		replacements[str(card["id"])] = card
	var hedgerow: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_hedgerow_units.json")
	)
	for card: Dictionary in hedgerow["units"]:
		replacements[str(card["id"])] = card
	var out := UnitLibrary.new()
	for card: Dictionary in current.all_units():
		var raw: Dictionary = replacements.get(str(card["id"]), card)
		out.register_unit(raw)
	for card: Dictionary in current.all_cards():
		out.register_card(card)
	for hero: Dictionary in current.all_heroes():
		out.register_hero(hero)
	return with_hunters(out) if restore_hunters else out


## Replace only the archived Hunters; all other current definitions are retained.
static func with_hunters(current: UnitLibrary) -> UnitLibrary:
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


## Replace Oozes alone where historical tests intentionally keep modern Birds/Fairies.
static func with_oozes(current: UnitLibrary) -> UnitLibrary:
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_oozes_units.json")
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


## Historical Hedgerow tests can keep the other five current tribes.
static func with_hedgerow(current: UnitLibrary) -> UnitLibrary:
	var archive: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_hedgerow_units.json")
	)
	var replacements: Dictionary = {}
	for card: Dictionary in archive["units"]:
		replacements[str(card["id"])] = card
	var out := UnitLibrary.new()
	for card: Dictionary in current.all_units():
		var definition: Dictionary = replacements.get(str(card["id"]), card)
		out.register_unit(definition)
	for card: Dictionary in current.all_cards():
		out.register_card(card)
	for card: Dictionary in current.all_heroes():
		out.register_hero(card)
	return out
