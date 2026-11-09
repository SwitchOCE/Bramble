extends SceneTree
## -- <field.json> <pairs.jsonl> [replicates_per_orientation=8]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("field_fights: expected field.json pairs.jsonl [replicates]")
		quit(2)
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var reps: int = args[2].to_int() if args.size() > 2 else 8
	assert(reps > 0)
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	var library := UnitLibrary.load_dir()
	for card: Dictionary in data.get("test_cards", []):
		assert(library.register_unit(card) == "")
	var count: int = 0
	var started: int = Time.get_ticks_msec()
	var rounds: Dictionary = data["rounds"]
	for round_key: String in rounds:
		var boards: Array = rounds[round_key]["boards"]
		assert(boards.size() >= 2)
		var first_board: Dictionary = boards[0]
		var values: Dictionary = first_board["config"]
		library = FightCapture.library_for(values, library)
		for a: int in boards.size():
			for b: int in range(a + 1, boards.size()):
				var left: Dictionary = boards[a]
				var right: Dictionary = boards[b]
				var wins: Array[int] = [0, 0]
				var draws: int = 0
				for rep: int in reps:
					var fight_seed: int = (
						("field|%s|%s|%s|%d" % [round_key, left["id"], right["id"], rep]).hash()
					)
					for orientation: int in 2:
						var result: Dictionary = FieldCombat.fight(
							left if orientation == 0 else right,
							right if orientation == 0 else left,
							fight_seed,
							library
						)
						var winner: int = CoreUtil.to_int(result["winner"])
						if winner < 0:
							draws += 1
						else:
							wins[winner if orientation == 0 else 1 - winner] += 1
						count += 1
				(
					output
					. store_line(
						(
							JSON
							. stringify(
								{
									"round": round_key.to_int(),
									"a": left["id"],
									"b": right["id"],
									"wins_a": wins[0],
									"wins_b": wins[1],
									"draws": draws,
									"trials": 2 * reps,
								}
							)
						)
					)
				)
		output.flush()
	print("field_fights: %d fights in %.3f s" % [count, (Time.get_ticks_msec() - started) / 1000.0])
	output.close()
	quit(0)
