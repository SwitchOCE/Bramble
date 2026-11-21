extends GutTest

@warning_ignore_start("unsafe_call_argument")

const FIXTURE: String = "res://tests/core/fixtures/ghost_run.json"
const SHIPPED: String = "res://tools/league/proof/fixtures/async-store"

var _store: GhostStore
var _root: String


func before_each() -> void:
	_root = GameRecord.directory.path_join(
		"ghost-store-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	)
	_store = GhostStore.new(_root)


func test_add_fetch_and_find_by_all_query_fields() -> void:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(FIXTURE)
	var id: String = _store.add(bytes)
	assert_eq(id, FileAccess.get_sha256(FIXTURE), _store.error)
	assert_eq(FileAccess.get_file_as_bytes(_path(id)), bytes)
	assert_eq(_store.add(bytes), id)
	var info: Dictionary = _store.fetch(id)["info"]
	var query: Dictionary = {
		"rules_hash": info["rules_hash"],
		"kinds": ["bot", info["kind"]],
		"labels": [info["label"]],
		"placement": [info["placement"], info["placement"]],
		"exclude": {},
	}
	assert_eq(_store.find(query), [info])
	for key: String in query:
		var mismatch: Dictionary = query.duplicate(true)
		mismatch[key] = {
			"rules_hash": "0".repeat(64),
			"kinds": ["test_realm"],
			"labels": ["no such label"],
			"placement": [100, 101],
			"exclude": {id: true},
		}[key]
		assert_eq(_store.find(mismatch), [], key)
	assert_eq(_store.find(), [info])
	assert_eq(_store.rebuild_index(), 1)
	assert_eq(
		FileAccess.get_file_as_string(_root.path_join("index.jsonl")), GhostJson.encode(info) + "\n"
	)


func test_add_deduplicates_one_record_seat_and_upgrades_legacy_index() -> void:
	var id: String = _store.add(FileAccess.get_file_as_bytes(FIXTURE))
	assert_ne(id, "", _store.error)
	var old: Dictionary = _store.find()[0]
	for key: String in ["record_sha256", "seat", "ended"]:
		old.erase(key)
	_save(_root.path_join("index.jsonl"), JSON.stringify(old) + "\n")
	assert_eq(_store.find()[0]["ended"], null)
	var run: Dictionary = _fixture()
	run["made"] = "2026-11-20T12:00:00Z"
	assert_eq(_store.add(GhostJson.encode(run).to_utf8_buffer()), id, _store.error)
	assert_eq(_store.find()[0]["record_sha256"], run["source"]["record_sha256"])
	run["source"]["record_sha256"] = "a".repeat(64)
	assert_ne(_store.add(GhostJson.encode(run).to_utf8_buffer()), id, _store.error)
	assert_eq(_store.find().size(), 2)


func test_add_recovers_a_published_run_missing_from_the_index() -> void:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(FIXTURE)
	var id: String = _store.add(bytes)
	_save(_root.path_join("index.jsonl"), "")
	assert_eq(_store.find().size(), 0)
	assert_eq(_store.add(bytes), id, _store.error)
	assert_eq(_store.find().size(), 1)


func test_bad_index_can_be_rebuilt_but_tampered_runs_fail_verification() -> void:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(FIXTURE)
	var id: String = _store.add(bytes)
	_save(_root.path_join("index.jsonl"), "unreadable")
	assert_eq(_store.find().size(), 0)
	assert_string_contains(_store.error, "invalid run info")
	assert_eq(_store.rebuild_index(), 1)
	_save(_path(id), bytes.get_string_from_utf8() + " ")
	assert_false(CoreUtil.to_bool(_store.fetch(id)["ok"]))
	assert_eq(_store.rebuild_index(), -1)
	assert_string_contains(_store.error, "SHA-256 mismatch")
	assert_eq(_store.find().size(), 1, "failed rebuild preserved the last published index")
	assert_eq(_store.add(bytes), "")
	assert_string_contains(_store.error, "SHA-256 mismatch")
	assert_eq(_store.add("{}".to_utf8_buffer()), "")
	assert_string_contains(_store.error, "expected run format")


func test_layer_reads_shipped_and_writable_runs_and_writes_only_to_writable() -> void:
	var layered := LayeredGhostStore.new(_root, SHIPPED)
	var infos: Array[Dictionary] = layered.find()
	assert_eq(infos.size(), 8, layered.error)
	var shipped_id: String = infos[0]["id"]
	assert_true(CoreUtil.to_bool(layered.fetch(shipped_id)["ok"]))
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(FIXTURE)
	var local_id: String = layered.add(bytes)
	assert_eq(local_id, FileAccess.get_sha256(FIXTURE), layered.error)
	assert_true(CoreUtil.to_bool(layered.fetch(local_id)["ok"]))
	assert_eq(_store.find().size(), 1)
	assert_eq(layered.find().size(), 9)
	var shipped_path: String = SHIPPED.path_join("runs").path_join(shipped_id.left(2))
	var shipped_bytes: PackedByteArray = FileAccess.get_file_as_bytes(
		shipped_path.path_join(shipped_id + ".json")
	)
	assert_eq(layered.add(shipped_bytes), shipped_id)
	assert_eq(layered.find().size(), 9, "an ID in both layers appears only once")
	assert_eq(layered.rebuild_index(), 2)
	_save(_path(shipped_id), shipped_bytes.get_string_from_utf8() + " ")
	assert_string_contains(str(layered.fetch(shipped_id)["message"]), "SHA-256 mismatch")


func test_index_uses_serde_json_control_character_escapes() -> void:
	var run: Dictionary = _fixture()
	var label: String = "é" + String.chr(1) + String.chr(11) + "\\v\t\n"
	run["source"]["label"] = label
	var bytes: PackedByteArray = GhostJson.encode(run).to_utf8_buffer()
	var id: String = _store.add(bytes)
	assert_ne(id, "", _store.error)
	var index: String = FileAccess.get_file_as_string(_root.path_join("index.jsonl"))
	assert_string_contains(index, "é\\u0001\\u000b\\\\v\\t\\n")
	assert_eq(_store.find()[0]["label"], label)


func _path(id: String) -> String:
	return _root.path_join("runs").path_join(id.left(2)).path_join(id + ".json")


func _fixture() -> Dictionary:
	return CoreUtil.to_dict(
		RecordState.value(JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)))
	)


func _save(path: String, contents: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()
