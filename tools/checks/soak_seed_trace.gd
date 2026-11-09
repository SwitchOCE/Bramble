extends "res://tools/checks/soak.gd"
## Same QA soak, with a deterministic per-fight result trace for revision comparisons.
## Run the identical script and seeds in each revision; compare seed_trace lines.


## Hold synthetic inputs fixed across revisions. Otherwise a newly added effect
## creates another SoakContent pool unit, changing shops despite default switches.
func _play(game_seed: int) -> int:
	var manifest: String = OS.get_environment("BRAMBLE_SOAK_INPUTS")
	if game_seed % 3 == 2 and manifest != "":
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest))
		_full_library = UnitLibrary.load_dir()
		SoakContent._register(_full_library, SoakContent.TOKEN, [], 1, false)
		var index: int = 0
		for trigger: String in data["triggers"]:
			if not SoakContent.NEVER.has(trigger):
				SoakContent._register(
					_full_library,
					"soak_" + trigger,
					[SoakContent._trigger_entry(trigger)],
					index,
					true
				)
				index += 1
		for effect: String in data["effects"]:
			SoakContent._register(
				_full_library, "soak_do_" + effect, [SoakContent._effect_entry(effect)], index, true
			)
			index += 1
		SoakContent._add_heroes(_full_library)
	return super._play(game_seed)


func _check_fight(round_number: int, id_a: int, id_b: int, result: Dictionary) -> void:
	super._check_fight(round_number, id_a, id_b, result)
	var end: Dictionary = result["events"][-1]
	var outcome: Dictionary = result.duplicate()
	outcome.erase("events")
	outcome["survivors"] = end["survivors"]
	var trace: Dictionary = {
		"seed": _game_seed,
		"round": round_number,
		"players": [id_a, id_b],
		"outcome": outcome,
		"result_sha256": JSON.stringify(result).sha256_text(),
	}
	print("seed_trace: " + JSON.stringify(trace))
	var directory: String = OS.get_environment("BRAMBLE_FIGHT_TRACE_DIR")
	if directory != "":
		var path: String = "%s/%d-%d-%d-%d.json" % [directory, _game_seed, round_number, id_a, id_b]
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(result))
