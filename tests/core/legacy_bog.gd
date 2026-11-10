class_name LegacyBog
extends RefCounted
## Opt-in archived Bog definitions for pass 2 mechanic regressions; live games use current cards.

const WAVE1 := preload("res://tests/core/legacy_wave1.gd")


## A deep copy of build(), built once a run (tests/core/library_cache.gd).
static func library(restore_wave1: bool = true, restore_hunters: bool = true) -> UnitLibrary:
	return TestLibraries.cached(
		"bog:%s:%s" % [restore_wave1, restore_hunters], build.bind(restore_wave1, restore_hunters)
	)


## Builds the library afresh; library() hands out copies of one build a run.
static func build(restore_wave1: bool = true, restore_hunters: bool = true) -> UnitLibrary:
	var current: UnitLibrary = WAVE1.library(false) if restore_wave1 else UnitLibrary.load_dir()
	var parsed: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/pass2_bog_units.json")
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
	return WAVE1.with_hunters(out) if restore_hunters else out
