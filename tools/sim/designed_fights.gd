extends SceneTree
## Complete fixed-setup field; archive one paired-orientation observation per seed.
## -- FIELD.json TRIALS.jsonl [independent_seeds_per_pair=64]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("designed_fights: expected field.json trials.jsonl [independent seeds]")
		quit(2)
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var reps: int = args[2].to_int() if args.size() > 2 else 64
	assert(reps > 0 and reps <= 4096)
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	var library := UnitLibrary.load_dir()
	var count: int = 0
	var started: int = Time.get_ticks_msec()
	for round_key: String in data["rounds"]:
		var boards: Array = data["rounds"][round_key]["boards"]
		assert(boards.size() >= 2)
		library = FightCapture.library_for(boards[0]["config"], library)
		for a: int in boards.size():
			for b: int in range(a + 1, boards.size()):
				var left: Dictionary = boards[a]
				var right: Dictionary = boards[b]
				var base_seed: int = (
					("designed|%s|%s|%s" % [round_key, left["id"], right["id"]]).hash()
				)
				for rep: int in reps:
					var fight_seed: int = base_seed * 4096 + rep
					var wins: Array[int] = [0, 0]
					var draws: int = 0
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
										"replicate": rep,
										"seed": str(fight_seed),
										"wins_a": wins[0],
										"wins_b": wins[1],
										"draws": draws,
										"trials": 2,
									}
								)
							)
						)
					)
		output.flush()
	output.close()
	print(
		"designed_fights: %d fights in %.3f s" % [count, (Time.get_ticks_msec() - started) / 1000.0]
	)
	quit(0)
