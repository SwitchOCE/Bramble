class_name GhostStore
extends RefCounted
## Read-only folder store shared with the run cutter.

var directory: String


func _init(root: String) -> void:
	directory = root


func fetch(id: String, library: UnitLibrary, registry: MechanicRegistry) -> Dictionary:
	if id.length() != 64 or not id.is_valid_hex_number() or id != id.to_lower():
		return _failure(id, "invalid SHA-256 ID")
	var path: String = directory.path_join("runs").path_join(id.left(2)).path_join(id + ".json")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(id, "cannot open %s" % path)
	var length: int = file.get_length()
	var bytes: PackedByteArray = file.get_buffer(length)
	if bytes.size() != length:
		return _failure(id, "cannot read all bytes of %s" % path)
	var hasher := HashingContext.new()
	hasher.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():
		hasher.update(bytes)
	if hasher.finish().hex_encode() != id:
		return _failure(id, "SHA-256 mismatch")
	var result: Dictionary = GhostRun.parse(bytes, library, registry)
	if not CoreUtil.to_bool(result["ok"]):
		return _failure(id, str(result["message"]))
	return result


static func _failure(id: String, message: String) -> Dictionary:
	return {"ok": false, "message": "run %s: %s" % [id, message]}
