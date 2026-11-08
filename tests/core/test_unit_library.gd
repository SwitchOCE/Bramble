extends GutTest
## UnitLibrary reads content/units/ as SPEC section 3 describes, and reports bad files.
# Assertions take Variants; GUT's untyped parameters count as unsafe arguments in 4.7.
@warning_ignore_start("unsafe_call_argument")

const BAD_DIR: String = "user://test_unit_library"

var _library: UnitLibrary = UnitLibrary.load_dir()


func test_loads_every_unit_file_without_errors() -> void:
	assert_eq(_library.load_errors(), PackedStringArray(), "no load errors")
	assert_eq(
		_library.all_units().size(),
		145,
		"37 library units, the Hoglet, 98 shop units and 9 created slice cards"
	)
	assert_eq(_library.pool_units().size(), 37, "the old library has no set")
	assert_eq(_library.pool_units("slice").size(), 98, "the slice's shop units")
	assert_eq(_library.pool_units().size(), 37, "tokens stay out of the pool")


func test_sorted_by_tier_then_name() -> void:
	var units: Array[Dictionary] = _library.all_units()
	for index: int in range(1, units.size()):
		var before: Dictionary = units[index - 1]
		var after: Dictionary = units[index]
		var tier_before: int = before["tier"]
		var tier_after: int = after["tier"]
		var name_before: String = before["name"]
		var name_after: String = after["name"]
		var ordered: bool = (
			tier_before < tier_after or (tier_before == tier_after and name_before <= name_after)
		)
		assert_true(ordered, "%s before %s" % [name_before, name_after])


func test_numbers_are_ints() -> void:
	var unit: Dictionary = _library.get_unit("hoglet_mother")
	assert_eq(typeof(unit["tier"]), TYPE_INT, "tier is an int")
	assert_eq(typeof(unit["attack"]), TYPE_INT, "attack is an int")
	var mechanics: Array = unit["mechanics"]
	var bristle: Dictionary = mechanics[0]
	assert_eq(typeof(bristle["n"]), TYPE_INT, "mechanic numbers are ints")


func test_unknown_unit_is_empty() -> void:
	assert_eq(_library.get_unit("no_such_unit"), {}, "unknown id gives {}")


func test_unbuilt_units_lists_units_with_unbuilt_mechanics() -> void:
	var unbuilt: PackedStringArray = _library.unbuilt_units()
	for unit: Dictionary in _library.all_units():
		var missing: bool = false
		var mechanics: Array = unit["mechanics"]
		for entry: Dictionary in mechanics:
			if not MechanicRegistry.is_built(str(entry["id"])):
				missing = true
		assert_eq(unbuilt.has(str(unit["id"])), missing, "%s listed iff unbuilt" % unit["id"])
	assert_false(unbuilt.has("belladonna_sprite"), "Nightshade is built")
	assert_false(unbuilt.has("dewdrop_ooze"), "plain units are never unbuilt")


func test_keyword_text_from_source_notes() -> void:
	var mother: Array = UnitLibrary.keyword_text_of(_library.get_unit("hoglet_mother"))
	assert_eq(mother.size(), 1, "one keyword")
	var entry: Dictionary = mother[0]
	assert_eq(entry["keyword"], "Bristle", "keyword name")
	var text: String = entry["text"]
	assert_true(text.begins_with("Bristle (N):"), "its own note: %s" % text)
	var hoglet: Array = UnitLibrary.keyword_text_of(_library.get_unit("hoglet"))
	var hoglet_entry: Dictionary = hoglet[0]
	assert_eq(hoglet_entry["text"], text, "the token's own note is the same Bristle text")
	var toad: Array = UnitLibrary.keyword_text_of(_library.get_unit("bitter_toad"))
	assert_eq(toad.size(), 1, "Bitter Toad's note is the Nightshade text")
	var plain: Array = UnitLibrary.keyword_text_of(_library.get_unit("dewdrop_ooze"))
	assert_eq(plain, [], "plain units have none")


func test_keyword_text_for_quick() -> void:
	var ermine: Array = UnitLibrary.keyword_text_of(_library.get_unit("ermine_duellist"))
	assert_eq(ermine.size(), 1, "Ermine Duellist's note explains Quick")
	var entry: Dictionary = ermine[0]
	var text: String = entry["text"]
	assert_true(text.begins_with("Quick: "), text)
	assert_true(text.ends_with("."), "one sentence: %s" % text)


func test_bad_files_are_skipped_and_reported() -> void:
	DirAccess.make_dir_recursive_absolute(BAD_DIR)
	var good: Dictionary = _library.get_unit("dewdrop_ooze").duplicate(true)
	good.erase("keyword_text")
	_write("dewdrop_ooze.json", JSON.stringify(good))
	_write("broken.json", "{ not json")
	var wrong_id: Dictionary = good.duplicate(true)
	_write("other_name.json", JSON.stringify(wrong_id))
	var missing: Dictionary = good.duplicate(true)
	missing.erase("tier")
	missing["id"] = "missing_tier"
	_write("missing_tier.json", JSON.stringify(missing))
	var library: UnitLibrary = UnitLibrary.load_dir(BAD_DIR)
	assert_eq(library.load_errors().size(), 3, "three bad files: %s" % [library.load_errors()])
	assert_eq(library.all_units().size(), 1, "the good file still loads")
	for file_name: String in DirAccess.get_files_at(BAD_DIR):
		DirAccess.remove_absolute(BAD_DIR.path_join(file_name))
	DirAccess.remove_absolute(BAD_DIR)


func test_missing_directory_is_reported() -> void:
	var library: UnitLibrary = UnitLibrary.load_dir("res://no/such/dir")
	assert_eq(library.load_errors().size(), 1, "one error")
	assert_eq(library.all_units().size(), 0, "no units")


func _write(file_name: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(BAD_DIR.path_join(file_name), FileAccess.WRITE)
	file.store_string(text)
	file.close()
