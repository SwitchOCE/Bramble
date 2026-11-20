class_name LayeredGhostStore
extends GhostStore
## Local player runs are writable, and the shipped store is only read.
## Writable entries take precedence when the same ID occurs in both folders.

var _shipped: GhostStore


func _init(writable_root: String = "", shipped_root: String = "") -> void:
	super(writable_root)
	_shipped = GhostStore.new(shipped_root)


func fetch(
	id: String, library: UnitLibrary = null, registry: MechanicRegistry = null
) -> Dictionary:
	var local: Dictionary = super.fetch(id, library, registry)
	if local.get("missing", false):
		return _shipped.fetch(id, library, registry)
	return local


func find(query: Dictionary = {}) -> Array[Dictionary]:
	var local: Array[Dictionary] = super.find(query)
	if error != "":
		return []
	var shipped: Array[Dictionary] = _shipped.find(query)
	error = _shipped.error
	if error != "":
		return []
	var seen: Dictionary = {}
	for info: Dictionary in local:
		seen[info["id"]] = true
	for info: Dictionary in shipped:
		if not seen.has(info["id"]):
			local.append(info)
			seen[info["id"]] = true
	return local
