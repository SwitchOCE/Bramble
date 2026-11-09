# gdlint:disable=max-returns
# Validation reports the first malformed field without executing any game state.
class_name FieldLibrary
extends RefCounted
## Exact per-side combat inputs, with a checked content manifest and gameplay configuration.

const VERSION: int = 2
const CONFIG_VERSION: int = 1
const BUNDLED_PATH: String = "res://content/fields/baseline.json.gz"
const RUNTIME_KEYS: Array = ["bots", "human_bot", "opponents", "field_library", "field_strength"]
const CONTENT_FOLDERS: Array = ["units", "heroes", "spells", "levers", "schema"]
const DISPLAY_KEYS: Array = [
	"text",
	"golden_text",
	"details",
	"golden_details",
	"overlay_text",
	"mechanic_text",
	"text_rules",
	"source",
	"_comment"
]

var data: Dictionary = {}
var error: String = ""


static func read(path: String, library: UnitLibrary) -> FieldLibrary:
	var out := FieldLibrary.new()
	if not FileAccess.file_exists(path):
		out.error = "Field library does not exist: %s" % path
		return out
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		out.error = "Field library cannot be read: %s" % path
		return out
	var parsed: Variant = out._document(file, path)
	if not out.error.is_empty():
		return out
	if not parsed is Dictionary:
		out.error = "Field library must be a JSON object"
		return out
	out.data = parsed
	out.error = out._validate(library)
	return out


func _document(file: FileAccess, path: String) -> Variant:
	var text: String
	if path.ends_with(".gz"):
		var packed: PackedByteArray = file.get_buffer(file.get_length())
		if packed.size() < 18 or packed[0] != 31 or packed[1] != 139 or packed[2] != 8:
			error = "Field library has an invalid or truncated gzip header: %s" % path
			return null
		var unpacked: PackedByteArray = packed.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		if unpacked.is_empty():
			error = "Field library gzip decompression failed or produced an empty file: %s" % path
			return null
		text = unpacked.get_string_from_utf8()
		# Parsing owns its String; release both byte buffers before constructing the JSON graph.
		packed.clear()
		unpacked.clear()
	else:
		text = file.get_as_text()
	var document := JSON.new()
	if document.parse(text) != OK:
		error = (
			"Field library JSON error at line %d: %s"
			% [document.get_error_line(), document.get_error_message()]
		)
		return null
	return document.data


## Launchers adopt the recorded lever/economy rules; direct callers must already match them.
static func configure(config: GameConfig, library: UnitLibrary, path: String) -> String:
	return prepare(config, library, path).error


## Keep this validated snapshot and pass it to GameSession.create; no second read or validation.
static func prepare(config: GameConfig, library: UnitLibrary, path: String) -> FieldLibrary:
	var field := read(path, library)
	if field.error != "":
		return field
	var source: Dictionary = field.data["config"]
	for key: String in source:
		if not key in RUNTIME_KEYS:
			config.set_value(key, source[key])
	config.set_value("opponents", "field")
	config.set_value("field_library", path)
	return field


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
	if data.get("manifest", "") != "gameplay-v1":
		return "Field library needs a gameplay content manifest"
	var hashes: Dictionary = data["content_hashes"]
	var observed: Dictionary = _content_manifest()
	if not error.is_empty():
		return error
	if hashes.size() != observed.size():
		return "Field library content version mismatch (manifest)"
	for path: String in observed:
		if hashes.get(path, "") != observed[path]:
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


## Missing exports must fail before gameplay, never fall through after a null directory call.
func _content_manifest(content_root: String = "res://content") -> Dictionary:
	error = ""
	var observed: Dictionary = {}
	for folder: String in CONTENT_FOLDERS:
		var dir := DirAccess.open(content_root.path_join(folder))
		if dir == null:
			error = "Cannot validate field content: missing directory content/%s" % folder
			return {}
		var count: int = 0
		for filename: String in dir.get_files():
			if not filename.ends_with(".json"):
				continue
			var path: String = "content/%s/%s" % [folder, filename]
			var file := FileAccess.open(
				content_root.path_join(folder).path_join(filename), FileAccess.READ
			)
			if file == null:
				error = "Cannot validate field content: unreadable %s" % path
				return {}
			var json := JSON.new()
			if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
				error = "Cannot validate field content: invalid JSON %s" % path
				return {}
			observed[path] = gameplay_hash(json.data, folder == "schema")
			count += 1
		if count == 0:
			error = "Cannot validate field content: no JSON files in content/%s" % folder
			return {}
	return observed


static func gameplay_hash(value: Variant, schema: bool = false) -> String:
	return canonical(gameplay_value(value, true, schema)).sha256_text()


## Card names are presentation. Nested mechanic names identify once/limit counters and Rings.
static func gameplay_value(value: Variant, root: bool = true, schema: bool = false) -> Variant:
	if value is Array:
		var values: Array = value
		var items: Array = []
		for item: Variant in values:
			items.append(gameplay_value(item, false))
		return items
	if value is Dictionary:
		var original: Dictionary = value
		var out: Dictionary = {}
		for key: String in original:
			if key in DISPLAY_KEYS or key.to_lower().contains("portrait"):
				continue
			if root and (key == "name" or (schema and key == "keywords")):
				continue
			out[key] = gameplay_value(original[key], false)
		return out
	return value


## All candidates keep their source lobby's full tribe set; filtering only their primary line
## would allow splash units from tribes that the current lobby has excluded.
func eligible(lobby_tribes: PackedStringArray, strength: String = "top4") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if strength not in ["top4", "all"]:
		return out
	var lines: Dictionary = data.get("lines", {})
	for line_id: String in lines:
		var line: Dictionary = lines[line_id]
		for trajectory: Dictionary in line["trajectories"]:
			if strength == "top4" and CoreUtil.to_int(trajectory["finish_place"]) > 4:
				continue
			var allowed: bool = true
			if not lobby_tribes.is_empty():
				for tribe: String in trajectory["lobby_tribes"]:
					if not lobby_tribes.has(tribe):
						allowed = false
						break
			if allowed:
				out.append({"line": line_id, "trajectory": trajectory})
	return out


func can_deal(lobby_tribes: PackedStringArray, strength: String = "top4", count: int = 8) -> String:
	if strength not in ["top4", "all"]:
		return "Unknown field strength: %s (expected top4 or all)" % strength
	var choices: Array[Dictionary] = eligible(lobby_tribes, strength)
	var ids: Dictionary = {}
	for choice: Dictionary in choices:
		var trajectory: Dictionary = choice["trajectory"]
		ids[trajectory["id"]] = true
	if ids.size() < count:
		return (
			"Field library has only %d eligible %s trajectories for lobby [%s]; need %d"
			% [ids.size(), strength, ", ".join(lobby_tribes), count]
		)
	return ""


static func _valid_metadata(trajectory: Dictionary) -> bool:
	if not _both_numbers(trajectory.get("finish_place"), 1):
		return false
	var place: int = CoreUtil.to_int(trajectory["finish_place"])
	if place < 1 or place > 8 or canonical(trajectory["finish_place"]) != str(place):
		return false
	if not trajectory.get("lobby_tribes") is Array:
		return false
	var tribes: Array = trajectory["lobby_tribes"]
	var seen: Dictionary = {}
	for tribe: Variant in tribes:
		if not tribe is String or str(tribe).is_empty() or seen.has(tribe):
			return false
		seen[tribe] = true
	return true


func _validate_lines(library: UnitLibrary) -> String:
	var lines: Dictionary = data["lines"]
	if lines.is_empty():
		return "Field library has no lines"
	var seen: Dictionary = {}
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
			var identity: String = str(trajectory["id"])
			if identity.is_empty() or seen.has(identity):
				return "Duplicate or empty field trajectory id: %s" % identity
			seen[identity] = true
			if not _valid_metadata(trajectory):
				return "Field trajectory needs source placement and lobby tribes"
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
