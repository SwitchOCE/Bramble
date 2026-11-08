extends SceneTree
## Step 2c. Raw fights stay in build/; summary rows retain the original guessed ranks.
## godot --headless -s res://tools/sim/benchmark_run.gd -- seeds=200 first_seed=1
## Default output prefix: build/sim/step2/benchmark

const Boards := preload("res://tools/sim/benchmark_boards.gd")
const Tournament := preload("res://tools/sim/benchmark_tournament.gd")
const BOARD_COLUMNS: Array[String] = [
	"id",
	"tribe",
	"round",
	"roll",
	"tier",
	"guessed_rank",
	"measured_rank",
	"rank_change",
	"stat_total",
	"fights",
	"wins",
	"draws",
	"losses",
	"win_rate",
	"draw_rate",
	"point_rate",
	"limitation_count"
]
const TRIBE_COLUMNS: Array[String] = [
	"tribe", "fights", "wins", "draws", "losses", "win_rate", "draw_rate", "point_rate"
]

var _options: Dictionary = {
	"seeds": "200", "first_seed": "1", "out": "build/sim/step2/benchmark", "input": Boards.INPUT
}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		if parts.size() != 2 or not _options.has(parts[0]):
			printerr("benchmark: bad option " + arg)
			quit(2)
			return
		_options[parts[0]] = parts[1]
	for key: String in ["seeds", "first_seed"]:
		if not str(_options[key]).is_valid_int() or str(_options[key]).to_int() < 1:
			printerr("benchmark: %s must be a positive integer" % key)
			quit(2)
			return
	var library: UnitLibrary = UnitLibrary.load_dir()
	var loaded: Dictionary = Boards.load_all(library, str(_options["input"]))
	var errors: Array = loaded["errors"]
	if not errors.is_empty():
		for problem: Variant in errors:
			printerr("benchmark: " + str(problem))
		quit(2)
		return
	var prefix: String = str(_options["out"])
	if DirAccess.make_dir_recursive_absolute(prefix.get_base_dir()) != OK:
		printerr("benchmark: cannot create output directory " + prefix.get_base_dir())
		quit(2)
		return
	var raw: FileAccess = FileAccess.open(prefix + ".fights.csv", FileAccess.WRITE)
	if raw == null:
		printerr("benchmark: cannot open output prefix " + prefix)
		quit(2)
		return
	_run(library, loaded, prefix, raw)
	quit(0)


func _run(library: UnitLibrary, loaded: Dictionary, prefix: String, raw: FileAccess) -> void:
	var boards: Array = loaded["boards"]
	var pairs: Array[Dictionary] = Tournament.schedule(boards)
	var records: Array = []
	var pair_rows: Array[Dictionary] = []
	for _board: Variant in boards:
		records.append(Tournament.empty_record())
	var seeds: int = str(_options["seeds"]).to_int()
	var first_seed: int = str(_options["first_seed"]).to_int()
	var config: GameConfig = GameConfig.full_game()
	var started: int = Time.get_ticks_msec()
	raw.store_csv_line(
		PackedStringArray(
			[
				"pair",
				"round",
				"roll",
				"seed",
				"leg",
				"side_0",
				"side_1",
				"winner_side",
				"winner_board",
				"reason",
				"damage",
				"last_blow"
			]
		)
	)
	for pair_index: int in pairs.size():
		var pair: Dictionary = pairs[pair_index]
		var a: int = pair["a"]
		var b: int = pair["b"]
		var pair_record: Dictionary = Tournament.empty_record()
		for fight_seed: int in range(first_seed, first_seed + seeds):
			for leg: int in 2:
				var left: int = a if leg == 0 else b
				var right: int = b if leg == 0 else a
				var left_board: Dictionary = boards[left]
				var right_board: Dictionary = boards[right]
				var result: Dictionary = Tournament.fight(
					library, config, left_board, right_board, fight_seed
				)
				var winner: int = CoreUtil.to_int(result["winner"])
				var reason: String = str(result["reason"])
				var left_record: Dictionary = records[left]
				var right_record: Dictionary = records[right]
				Tournament.record_result(left_record, winner, 0, reason)
				Tournament.record_result(right_record, winner, 1, reason)
				Tournament.record_result(pair_record, winner, leg, reason)
				var winner_id: String = ""
				if winner >= 0:
					winner_id = str(boards[left if winner == 0 else right]["id"])
				raw.store_csv_line(
					PackedStringArray(
						[
							str(pair_index),
							str(pair["round"]),
							str(pair["roll"]),
							str(fight_seed),
							str(leg),
							str(boards[left]["id"]),
							str(boards[right]["id"]),
							str(winner),
							winner_id,
							reason,
							str(result["damage"]),
							str(result["last_blow"])
						]
					)
				)
		var pair_row: Dictionary = Tournament.rates(pair_record)
		pair_row.merge(
			{
				"a": boards[a]["id"],
				"b": boards[b]["id"],
				"round": pair["round"],
				"roll": pair["roll"]
			}
		)
		pair_rows.append(pair_row)
		raw.flush()
		print(
			(
				"benchmark: pair %d/%d %s vs %s"
				% [pair_index + 1, pairs.size(), boards[a]["id"], boards[b]["id"]]
			)
		)
	var board_rows: Array[Dictionary] = Tournament.board_rows(boards, records)
	var tribe_rows: Array[Dictionary] = Tournament.tribe_rows(boards, records)
	var limitations: Array[Dictionary] = []
	for board: Dictionary in boards:
		limitations.append(
			{
				"id": board["id"],
				"unrepresentable": board["unrepresentable"],
				"assumptions": board["assumptions"]
			}
		)
	var summary: Dictionary = {
		"input": loaded["path"],
		"input_sha256": loaded["sha256"],
		"input_base_commit": loaded["base_commit"],
		"engine": Engine.get_version_info(),
		"config": "GameConfig.full_game()",
		"seeds_per_pair_per_side": seeds,
		"first_seed": first_seed,
		"sides": 2,
		"board_count": boards.size(),
		"pair_count": pairs.size(),
		"fight_count": pairs.size() * seeds * 2,
		"seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"ranking": "competition rank by wins + half draws; strict wins reported separately",
		"boards": board_rows,
		"tribes": tribe_rows,
		"pairs": pair_rows
	}
	_write_json(prefix + ".summary.json", summary)
	_write_json(prefix + ".limitations.json", limitations)
	_write_json(prefix + ".translated.json", boards)
	_write_csv(prefix + ".boards.csv", board_rows, BOARD_COLUMNS)
	_write_csv(prefix + ".tribes.csv", tribe_rows, TRIBE_COLUMNS)
	print(
		(
			"benchmark: %d fights in %.1fs; %s.summary.json"
			% [summary["fight_count"], summary["seconds"], prefix]
		)
	)


func _write_json(path: String, data: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")


func _write_csv(path: String, rows: Array[Dictionary], columns: Array[String]) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(columns))
	for row: Dictionary in rows:
		var fields: PackedStringArray = []
		for column: String in columns:
			fields.append(str(row[column]))
		file.store_csv_line(fields)
