extends SceneTree
## Allocation checkpoints: mount the eager baseline export with --main-pack.
## Run in a fresh process under /usr/bin/time -v; no gameplay changes.


func checkpoint(label: String) -> void:
	var row: Dictionary = {
		"stage": label,
		"static_bytes": OS.get_static_memory_usage(),
		"static_peak_bytes": OS.get_static_memory_peak_usage()
	}
	var status := FileAccess.open("/proc/self/status", FileAccess.READ)
	while not status.eof_reached():
		var line: String = status.get_line()
		for key: String in ["VmRSS", "VmHWM"]:
			if line.begins_with(key + ":"):
				row[key + "_kib"] = int(line.get_slice(":", 1).strip_edges().get_slice(" ", 0))
	print("profile-stage: " + JSON.stringify(row))


func _initialize() -> void:
	var units := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	checkpoint("units_and_config")
	var field: FieldLibrary = parse_bundle()
	checkpoint("parsed_tree_only")
	field.error = field._validate(units)
	assert(field.error == "", field.error)
	checkpoint("validated_tree")
	var header: Dictionary = field.data["config"]
	var restored: Dictionary = Pass3Rates.restore_values(header)
	for key: String in restored:
		if key not in FieldLibrary.RUNTIME_KEYS:
			config.set_value(key, restored[key])
	config.set_value("opponents", "field")
	config.set_value("field_library", FieldLibrary.BUNDLED_PATH)
	checkpoint("configured_tree")
	var session := GameSession.create(71, units, config, Bot.create, field)
	assert(session != null)
	checkpoint("dealt_7_plus_ghost")
	if session.get_state()["pending_choice"] != null:
		assert(session.choose(0) == "")
	checkpoint("first_recruit_with_frames")
	print("profile-library-sha256: " + FileAccess.get_sha256(FieldLibrary.BUNDLED_PATH))
	quit(0)


func parse_bundle() -> FieldLibrary:
	var packed: PackedByteArray = FileAccess.get_file_as_bytes(FieldLibrary.BUNDLED_PATH)
	assert(not packed.is_empty())
	checkpoint("gzip_buffer")
	var unpacked: PackedByteArray = packed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	checkpoint("gzip_and_utf8_buffers")
	var text: String = unpacked.get_string_from_utf8()
	checkpoint("buffers_and_utf32_string")
	packed.clear()
	unpacked.clear()
	checkpoint("string_only")
	var document := JSON.new()
	assert(document.parse(text) == OK)
	checkpoint("parsed_tree_and_string")
	var field := FieldLibrary.new()
	field.data = document.data
	return field
