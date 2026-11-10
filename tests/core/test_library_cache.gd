extends GutTest
## The cache hands out complete deep copies; mutations never contaminate its master.


func test_a_deeply_mutated_copy_does_not_change_current_content() -> void:
	var changed: UnitLibrary = TestLibraries.current()
	# A stat inside a spell's effect, below the card dictionary.
	changed.get_card("sample_growth")["do"]["attack"] = -999
	changed.get_unit("aunt_aspic")["mechanics"][0]["bonus"] = -999
	changed.get_hero("sample_painter")["power"]["do"]["attack"] = -999
	changed._errors.append("only this copy")
	var current: UnitLibrary = TestLibraries.current()
	var fresh: UnitLibrary = UnitLibrary.load_dir()
	assert_eq(current.all_units(), fresh.all_units(), "units")
	assert_eq(current.all_cards(), fresh.all_cards(), "cards, including nested stats")
	assert_eq(current._heroes, fresh._heroes, "heroes")
	assert_eq(current.load_errors(), fresh.load_errors(), "errors")


func test_copy_keeps_every_unit_library_field() -> void:
	var source: UnitLibrary = UnitLibrary.load_dir()
	# Non-default errors ensure this field is copied too.
	source._errors.append("copy this error")
	var copied: UnitLibrary = TestLibraries.copy(source)
	var fields: Array[String] = []
	for property: Dictionary in source.get_property_list():
		if CoreUtil.to_int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			fields.append(str(property["name"]))
	fields.sort()
	# An added field must be considered explicitly, even if its default would compare equal.
	assert_eq(fields, ["_by_id", "_cards", "_errors", "_heroes", "_units"])
	for field: String in fields:
		var actual: Variant = copied.get(field)
		var expected: Variant = source.get(field)
		var matches: bool = actual == expected
		assert_true(matches, "copied %s" % field)
	var indexed: Dictionary = copied._by_id["aunt_aspic"]
	var matching: Array = copied._units.filter(
		func(unit: Dictionary) -> bool: return unit["id"] == "aunt_aspic"
	)
	assert_eq(matching.size(), 1)
	var matching_unit: Dictionary = matching[0]
	assert_same(indexed, matching_unit)
	assert_false(is_same(copied._by_id["aunt_aspic"], source._by_id["aunt_aspic"]))
