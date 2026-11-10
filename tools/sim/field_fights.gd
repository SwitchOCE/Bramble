extends SceneTree
## -- FIELD.json OUTPUT.jsonl [replicates_per_orientation=8] [aggregate|per_seed] [SEEDS.json]
## per_seed preserves the designed-field seed family and pairs both orientations per row.


static func seed_for(
	round_key: String, left_id: String, right_id: String, rep: int, per_seed: bool = false
) -> int:
	if per_seed:
		var base_seed: int = ("designed|%s|%s|%s" % [round_key, left_id, right_id]).hash()
		return base_seed * 4096 + rep
	return ("field|%s|%s|%s|%d" % [round_key, left_id, right_id, rep]).hash()


static func explicit_seed(value: Variant) -> int:
	assert(value is String and str(str(value).to_int()) == str(value))
	return str(value).to_int()


static func result_row(
	round_number: int,
	left_id: String,
	right_id: String,
	wins: Array[int],
	draws: int,
	trials: int,
	replicate: int = -1,
	fight_seed: int = 0
) -> Dictionary:
	var row: Dictionary = {"round": round_number, "a": left_id, "b": right_id}
	if replicate >= 0:
		row.merge({"replicate": replicate, "seed": str(fight_seed)})
	row.merge({"wins_a": wins[0], "wins_b": wins[1], "draws": draws, "trials": trials})
	return row


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2 or args.size() > 5:
		printerr("field_fights: expected field.json output.jsonl [replicates] [mode] [seeds.json]")
		quit(2)
		return
	var mode: String = args[3] if args.size() > 3 else "aggregate"
	if mode not in ["aggregate", "per_seed"]:
		printerr("field_fights: unknown output mode %s" % mode)
		quit(2)
		return
	var per_seed: bool = mode == "per_seed"
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var reps: int = args[2].to_int() if args.size() > 2 else 8
	assert(reps > 0 and (not per_seed or reps <= 4096 or args.size() == 5))
	var explicit_seeds: Array = []
	if args.size() == 5:
		explicit_seeds = JSON.parse_string(FileAccess.get_file_as_string(args[4]))
		assert(per_seed and explicit_seeds.size() == reps)
		var seen: Dictionary = {}
		for value: Variant in explicit_seeds:
			explicit_seed(value)
			assert(not seen.has(value), "duplicate explicit fight seed")
			seen[value] = true
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
				var left_id: String = str(left["id"])
				var right_id: String = str(right["id"])
				var totals: Array[int] = [0, 0]
				var total_draws: int = 0
				for rep: int in reps:
					var fight_seed: int = (
						explicit_seed(explicit_seeds[rep])
						if not explicit_seeds.is_empty()
						else seed_for(round_key, left_id, right_id, rep, per_seed)
					)
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
					for side: int in 2:
						totals[side] += wins[side]
					total_draws += draws
					if per_seed:
						output.store_line(
							JSON.stringify(
								result_row(
									round_key.to_int(),
									left_id,
									right_id,
									wins,
									draws,
									2,
									rep,
									fight_seed
								)
							)
						)
				if not per_seed:
					output.store_line(
						JSON.stringify(
							result_row(
								round_key.to_int(), left_id, right_id, totals, total_draws, 2 * reps
							)
						)
					)
		output.flush()
	print("field_fights: %d fights in %.3f s" % [count, (Time.get_ticks_msec() - started) / 1000.0])
	output.close()
	quit(0)
