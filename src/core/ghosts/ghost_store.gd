class_name GhostStore
extends RefCounted
## Store contract (add, fetch, find), implemented here with a Rust-compatible local folder.
## Other backends can override those methods. Only the folder backend needs rebuild_index.
## After add, find or rebuild_index, error is empty on success or holds the failure message.

const _INDEX: String = "index.jsonl"

var directory: String
var error: String = ""


func _init(root: String = "") -> void:
	directory = root


## Returns the stored ID, or an empty string on error.
func add(bytes: PackedByteArray) -> String:
	error = ""
	var parsed: Dictionary = GhostRun.parse(bytes)
	if not parsed["ok"]:
		error = str(parsed["message"])
		return ""
	var info: Dictionary = parsed["info"]
	var infos: Array[Dictionary] = _read_index() if _has_index() else _scan()
	if error != "":
		return ""
	if infos.any(func(row: Dictionary) -> bool: return row["record_sha256"] == ""):
		# Older Rust indexes omit the source identity used to deduplicate.
		if rebuild_index() < 0:
			return ""
		infos = _read_index()
		if error != "":
			return ""
	return _add_run(bytes, info, infos)


func _add_run(bytes: PackedByteArray, info: Dictionary, infos: Array[Dictionary]) -> String:
	var id: String = info["id"]
	for existing: Dictionary in infos:
		if (
			existing["id"] != id
			and existing["record_sha256"] == info["record_sha256"]
			and existing["seat"] == info["seat"]
		):
			return str(existing["id"])

	var path: String = _run_path(id)
	if FileAccess.file_exists(path):
		var existing: Dictionary = _read_run(id)
		if not existing["ok"]:
			error = str(existing["message"])
			return ""
		if _has_index() and infos.any(func(row: Dictionary) -> bool: return row["id"] == id):
			return id
		# Recover a run published before an interrupted index update.
		return id if rebuild_index() >= 0 else ""

	if not _publish(path, bytes):
		return ""
	infos.append(info)
	return id if _write_index(infos) else ""


func fetch(
	id: String, library: UnitLibrary = null, registry: MechanicRegistry = null
) -> Dictionary:
	return _read_run(id, library, registry)


## Query fields are optional. placement is [minimum, maximum], inclusive. exclude is an ID set.
func find(query: Dictionary = {}) -> Array[Dictionary]:
	error = ""
	var infos: Array[Dictionary] = _read_index() if _has_index() else _scan()
	var matched: Array[Dictionary] = []
	for info: Dictionary in infos:
		if _matches(query, info):
			matched.append(info)
	return matched


## Rebuilds the index in lexicographic ID order. Returns the run count, or -1 on error.
func rebuild_index() -> int:
	error = ""
	var infos: Array[Dictionary] = _scan()
	if error != "" or not _write_index(infos):
		return -1
	return infos.size()


static func _matches(query: Dictionary, info: Dictionary) -> bool:
	var rules_hash: Variant = query.get("rules_hash")
	var kinds: Array = query.get("kinds", [])
	var labels: Array = query.get("labels", [])
	var placement: Variant = query.get("placement")
	var exclude: Dictionary = query.get("exclude", {})
	return (
		(rules_hash == null or info["rules_hash"] == rules_hash)
		and (kinds.is_empty() or kinds.has(info["kind"]))
		and (labels.is_empty() or labels.has(info["label"]))
		and (
			placement == null
			or (info["placement"] >= placement[0] and info["placement"] <= placement[1])
		)
		and not exclude.has(info["id"])
	)


func _has_index() -> bool:
	return FileAccess.file_exists(directory.path_join(_INDEX))


func _read_index() -> Array[Dictionary]:
	var path: String = directory.path_join(_INDEX)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		error = "cannot open %s" % path
		return []
	var infos: Array[Dictionary] = []
	while file.get_position() < file.get_length():
		var json := JSON.new()
		var parsed: Dictionary = {}
		if json.parse(file.get_line()) == OK:
			parsed = CoreUtil.to_dict(json.data)
		if not _valid_info(parsed):
			error = "%s:%d: invalid run info; rebuild the ghost index" % [path, infos.size() + 1]
			return []
		# Mirror Rust's defaults for indexes written before these fields were present.
		parsed.merge({"record_sha256": "", "seat": 0, "ended": null})
		infos.append(CoreUtil.to_dict(RecordState.value(parsed)))
	if file.get_error() != OK and file.get_error() != ERR_FILE_EOF:
		error = "cannot read %s: %s" % [path, error_string(file.get_error())]
		return []
	return infos


static func _valid_info(info: Dictionary) -> bool:
	for key: String in ["id", "rules_hash", "label", "made"]:
		if not info.get(key) is String:
			return false
	return (
		info.get("record_sha256", "") is String
		and GhostRun._SOURCE_KINDS.has(str(info.get("kind")))
		and GhostRun._integer(info.get("placement"), -GhostRun._MAX_JSON_INT)
		and GhostRun._integer(info.get("last_turn"), 0)
		and GhostRun._integer(info.get("seat", 0), -GhostRun._MAX_JSON_INT)
		and (info.get("ended") == null or GhostRun._END_REASONS.has(str(info["ended"])))
	)


func _scan() -> Array[Dictionary]:
	var runs: String = directory.path_join("runs")
	var infos: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(runs):
		if FileAccess.file_exists(runs):
			error = "%s is not a directory" % runs
		return infos
	var shards: DirAccess = DirAccess.open(runs)
	if shards == null:
		error = "cannot open %s" % runs
		return []
	for shard: String in shards.get_directories():
		var folder: DirAccess = DirAccess.open(runs.path_join(shard))
		if folder == null:
			error = "cannot open shard %s" % shard
			return []
		for file: String in folder.get_files():
			if not file.ends_with(".json"):
				continue
			var id: String = file.trim_suffix(".json")
			if id.left(2) != shard:
				error = "%s/%s: run is in the wrong shard" % [shard, file]
				return []
			var loaded: Dictionary = _read_run(id)
			if not loaded["ok"]:
				error = str(loaded["message"])
				return []
			infos.append(loaded["info"])
	infos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	return infos


func _read_run(
	id: String, library: UnitLibrary = null, registry: MechanicRegistry = null
) -> Dictionary:
	if not GhostRun._hex(id, 64):
		return _failure(id, "invalid SHA-256 ID")
	var path: String = _run_path(id)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var failure: Dictionary = _failure(id, "cannot open %s" % path)
		failure["missing"] = FileAccess.get_open_error() == ERR_FILE_NOT_FOUND
		return failure
	var length: int = file.get_length()
	var bytes: PackedByteArray = file.get_buffer(length)
	if bytes.size() != length:
		return _failure(id, "cannot read all bytes of %s" % path)
	if GhostRun.sha256(bytes) != id:
		return _failure(id, "SHA-256 mismatch")
	var result: Dictionary = GhostRun.parse(bytes, library, registry)
	if not result["ok"]:
		return _failure(id, str(result["message"]))
	return result


func _run_path(id: String) -> String:
	return directory.path_join("runs").path_join(id.left(2)).path_join(id + ".json")


func _write_index(infos: Array[Dictionary]) -> bool:
	var lines: PackedStringArray = []
	for info: Dictionary in infos:
		# Field order is the Rust RunInfo declaration order.
		var row: Dictionary = {}
		for key: String in [
			"id",
			"rules_hash",
			"kind",
			"label",
			"placement",
			"last_turn",
			"made",
			"record_sha256",
			"seat",
			"ended"
		]:
			row[key] = info[key]
		lines.append(GhostJson.encode(row))
	if not lines.is_empty():
		lines.append("")
	return _publish(directory.path_join(_INDEX), "\n".join(lines).to_utf8_buffer())


## Same-directory rename publishes a complete file. There is one writer.
func _publish(path: String, bytes: PackedByteArray) -> bool:
	var result: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if result != OK:
		error = "cannot create folder for %s: %s" % [path, error_string(result)]
		return false
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		error = "cannot write %s: %s" % [temporary, error_string(FileAccess.get_open_error())]
		return false
	file.store_buffer(bytes)
	file.flush()
	result = file.get_error()
	file.close()
	if result == OK:
		result = DirAccess.rename_absolute(temporary, path)
	if result != OK:
		error = "cannot publish %s: %s" % [path, error_string(result)]
	return result == OK


static func _failure(id: String, message: String) -> Dictionary:
	return {"ok": false, "message": "run %s: %s" % [id, message]}
