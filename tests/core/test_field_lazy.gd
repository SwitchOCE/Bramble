extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access", "unsafe_property_access")

const FieldTestData := preload("res://tests/core/field_test_data.gd")
var _path: String = "user://field-lazy-test.json.gz"


func after_each() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))


func _write(value: Dictionary) -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	file.store_buffer(JSON.stringify(value).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
	file.close()


func test_index_preserves_frames_names_and_unrelated_provenance_arrays() -> void:
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(FieldTestData.path())
	)
	var lines: Dictionary = document["lines"]
	var first: Dictionary = lines.values()[0]
	var trajectories: Array = first["trajectories"]
	var original: Dictionary = trajectories[0]
	original["name"] = 'Unicode 🍂 and braces { } with escaped "trajectories": [{}]'
	document["source"]["trajectories"] = ["unrelated provenance"]
	_write(document)
	var indexed := FieldLibrary.read(_path, UnitLibrary.load_dir())
	assert_eq(indexed.error, "")
	if indexed.error != "":
		return
	assert_gt(indexed._spans.size(), 0)
	assert_eq(indexed._loaded.size(), 0, "validation does not retain trajectory bodies")
	for id: String in lines:
		var source_line: Dictionary = lines[id]
		var index_line: Dictionary = indexed.data["lines"][id]
		var sources: Array = source_line["trajectories"]
		var headers: Array = index_line["trajectories"]
		for i: int in sources.size():
			var source: Dictionary = sources[i]
			var header: Dictionary = headers[i]
			assert_eq(header["id"], source["id"])
			assert_eq(header["name"], source["name"])
			var rounds: Dictionary = source["rounds"]
			for number: String in rounds:
				var expected: Dictionary = rounds[number]
				assert_eq(indexed.frame_for(header, int(number)), expected)
				assert_eq(indexed.frame_size(header, int(number)), FieldRivals.board_size(expected))
	assert_lte(indexed._loaded.size(), 8)


func test_invalid_undealt_frame_and_truncated_json_fail_before_play() -> void:
	var document: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(FieldTestData.path())
	)
	var lines: Dictionary = document["lines"]
	var last: Dictionary = lines.values()[-1]
	var trajectories: Array = last["trajectories"]
	var trajectory: Dictionary = trajectories[-1]
	trajectory["rounds"]["1"]["board"] = []
	_write(document)
	assert_string_contains(FieldLibrary.read(_path, UnitLibrary.load_dir()).error, "field round")
	var file := FileAccess.open(_path, FileAccess.WRITE)
	file.store_buffer(
		'{"lines":{"a":{"trajectories":[{'.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
	)
	file.close()
	assert_ne(FieldLibrary.read(_path, UnitLibrary.load_dir()).error, "")
