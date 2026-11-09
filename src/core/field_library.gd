# gdlint:disable=max-returns
# Validation reports the first malformed field without executing any game state.
class_name FieldLibrary
extends RefCounted
## Exact per-side combat inputs, with a checked content manifest and gameplay configuration.

const VERSION: int = 1
const CONFIG_VERSION: int = 1
const RUNTIME_KEYS: Array = ["bots", "human_bot", "opponents", "field_library"]
const MAX_BYTES: int = 10000000

var data: Dictionary = {}
var error: String = ""


static func read(path: String, library: UnitLibrary) -> FieldLibrary:
	var out := FieldLibrary.new()
	if not FileAccess.file_exists(path):
		out.error = "Field library does not exist: %s" % path
		return out
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_BYTES:
		out.error = "Field library cannot be read or exceeds 10 MB"
		return out
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		out.error = "Field library must be a JSON object"
		return out
	out.data = parsed
	out.error = out._validate(library)
	return out


## Launchers adopt the recorded lever/economy rules; direct callers must already match them.
static func configure(config: GameConfig, library: UnitLibrary, path: String) -> String:
	var field := read(path, library)
	if field.error != "":
		return field.error
	var source: Dictionary = field.data["config"]
	for key: String in source:
		if not key in RUNTIME_KEYS:
			config.set_value(key, source[key])
	config.set_value("opponents", "field")
	config.set_value("field_library", path)
	return ""


func config_problem(config: GameConfig) -> String:
	var source: Dictionary = data["config"]
	var defaults := GameConfig.defaults()
	for key: String in defaults._values:
		if key in RUNTIME_KEYS:
			continue
		if canonical(source.get(key, defaults.get_value(key))) != canonical(config.get_value(key)):
			return "Field library config mismatch: %s" % key
	return ""


func _validate(library: UnitLibrary) -> String:
	if data.get("version") != VERSION or data.get("config_version") != CONFIG_VERSION:
		return "Field library content/config format version mismatch"
	if not data.get("config") is Dictionary or not data.get("content_hashes") is Dictionary:
		return "Field library needs config and content hashes"
	var hashes: Dictionary = data["content_hashes"]
	var paths: PackedStringArray = []
	for folder: String in ["units", "heroes", "spells"]:
		var dir := DirAccess.open("res://content/" + folder)
		for filename: String in dir.get_files():
			if filename.ends_with(".json"):
				paths.append("content/%s/%s" % [folder, filename])
	if paths.size() != hashes.size():
		return "Field library content version mismatch (manifest)"
	for path: String in paths:
		if hashes.get(path, "") != FileAccess.get_sha256("res://" + path):
			return "Field library content version mismatch: %s" % path
	var config := GameConfig.defaults()
	var source: Dictionary = data["config"]
	for key: String in source:
		if not config._values.has(key) or typeof(source[key]) != typeof(config.get_value(key)):
			# JSON integral numbers are floats. Validate them as numbers, not key type changes.
			if not config._values.has(key) or not _both_numbers(source[key], config.get_value(key)):
				return "Field library unknown config key/type: %s" % key
		config.set_value(key, source[key])
	if not data.get("source") is Dictionary or not data.get("lines") is Dictionary:
		return "Field library needs provenance and lines"
	return _validate_lines(ScaleOverlay.library_for(library, config))


func _validate_lines(library: UnitLibrary) -> String:
	var lines: Dictionary = data["lines"]
	if lines.is_empty():
		return "Field library has no lines"
	for id: String in lines:
		if not lines[id] is Dictionary:
			return "Invalid field line: %s" % id
		var line: Dictionary = lines[id]
		if not line.get("tribe") is String or not line.get("trajectories") is Array:
			return "Field line needs tribe and trajectories: %s" % id
		var trajectories: Array = line["trajectories"]
		if trajectories.is_empty():
			return "Empty field line: %s" % id
		for item: Variant in trajectories:
			if not item is Dictionary:
				return "Invalid field trajectory"
			var trajectory: Dictionary = item
			if (
				not trajectory.get("id") is String
				or not trajectory.get("name") is String
				or not trajectory.get("hero") is String
				or library.get_hero(str(trajectory["hero"])).is_empty()
				or not trajectory.get("rounds") is Dictionary
			):
				return "Field trajectory needs a known hero and rounds"
			var rounds: Dictionary = trajectory["rounds"]
			if rounds.is_empty():
				return "Empty field trajectory"
			for number: int in range(1, rounds.size() + 1):
				if not rounds.has(str(number)) or not _valid_frame(rounds[str(number)], library):
					return "Invalid or noncontiguous field round: %s/%d" % [id, number]
	return ""


static func _valid_frame(value: Variant, library: UnitLibrary) -> bool:
	if not value is Dictionary:
		return false
	var frame: Dictionary = value
	for key: String in ["board", "slots", "hero_effects"]:
		if not frame.get(key) is Array:
			return false
	if frame.has("views") and (not frame["views"] is Array):
		return false
	var board: Array = frame["board"]
	var slots: Array = frame["slots"]
	if (
		board.size() != BoardGeometry.SLOTS
		or slots.size() != BoardGeometry.SLOTS
		or not frame.get("fight_rules") is Dictionary
		or not _both_numbers(frame.get("tier"), 1)
		or CoreUtil.to_int(frame["tier"]) < 1
		or CoreUtil.to_int(frame["tier"]) > 6
	):
		return false
	for spec: Variant in frame["board"]:
		if spec != null and not _valid_spec(spec, library):
			return false
	for effects: Variant in frame["slots"]:
		if not effects is Array:
			return false
	return true


static func _valid_spec(value: Variant, library: UnitLibrary) -> bool:
	if not value is Dictionary:
		return false
	var spec: Dictionary = value
	if library.get_unit(str(spec.get("def_id", ""))).is_empty():
		return false
	for held: Variant in spec.get("held", []):
		if not _valid_spec(held, library):
			return false
	return true


static func _both_numbers(a: Variant, b: Variant) -> bool:
	return typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]


static func canonical(value: Variant) -> String:
	# Integral JSON numbers normalize identically before comparing to native config integers.
	if value is float and value == floor(value):
		var number: float = value
		return JSON.stringify(int(number))
	if value is Array:
		var values: Array = value
		return "[" + ",".join(values.map(canonical)) + "]"
	if value is Dictionary:
		var object: Dictionary = value
		var keys: Array = object.keys()
		keys.sort()
		var parts: PackedStringArray = []
		for key: String in keys:
			parts.append(JSON.stringify(key) + ":" + canonical(object[key]))
		return "{" + ",".join(parts) + "}"
	return JSON.stringify(value)
