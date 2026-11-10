class_name LegacyPrototypes
extends RefCounted
## Test-only prototype pool for original shop, pool and rollback regressions.
## Live TestLibraries.current() and frozen field fixture bytes remain untouched.


static func library() -> UnitLibrary:
	return TestLibraries.cached("legacy-prototypes", build)


static func build() -> UnitLibrary:
	return restore(UnitLibrary.load_dir())


## Restore only the thirteen flags/cards changed by the final retirement. Never replace the
## other twenty-five prototypes: older tribe archives intentionally restore their historical flags.
static func restore(current: UnitLibrary) -> UnitLibrary:
	var archive: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://tests/core/data/legacy_prototype_units.json")
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
	for hero: Dictionary in current.all_heroes():
		out.register_hero(hero)
	return out
