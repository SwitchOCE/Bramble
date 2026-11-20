class_name GameRecord
extends RefCounted
## One append-only local JSONL file per game. No full turn states or combat event logs.
## Set directory before creating sessions to keep test/batch output in a chosen local folder.

const FORMAT: int = 4
static var directory: String = "user://records"
static var _serial: int = 0

var path: String = ""
var error: String = ""
var _file: FileAccess


static func begin(game: GameSession) -> GameRecord:
	var record := GameRecord.new()
	_serial += 1
	var folder_error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if folder_error != OK:
		record._fail("Cannot create records folder: %s" % error_string(folder_error))
		return record
	# Microseconds + process + serial prevent simultaneous games sharing a file, even at one seed.
	record.path = directory.path_join(
		(
			"%d-%d-%d.jsonl"
			% [Time.get_unix_time_from_system() * 1000000, OS.get_process_id(), _serial]
		)
	)
	record._file = FileAccess.open(record.path, FileAccess.WRITE)
	if record._file == null:
		record._fail("Cannot write game record: %s" % error_string(FileAccess.get_open_error()))
		return record
	var runs: Array[Dictionary] = []
	for seat: int in game.run_ids.size():
		if game.run_ids[seat] != "":
			runs.append({"seat": seat, "id": game.run_ids[seat]})
	(
		record
		. append(
			{
				"op": "header",
				"format": FORMAT,
				"mode": "live" if runs.is_empty() else "async",
				"runs": runs,
				"seed": str(game.seed_value),
				"build": RecordBuild.identity(),
				"recipe": game.record_recipe,
				"config": RecordState.fields(game.config),
				"initial_hash": RecordState.state_hash(game),
			}
		)
	)
	return record


func append(entry: Dictionary) -> void:
	if _file == null or error != "":
		return
	_file.store_line(JSON.stringify(entry))
	_file.flush()
	if _file.get_error() != OK:
		_fail("Cannot save game record: %s" % error_string(_file.get_error()))


func _fail(message: String) -> void:
	error = message
	push_error(message)
