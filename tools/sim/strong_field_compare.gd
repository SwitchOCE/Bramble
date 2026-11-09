extends SceneTree
## Fixed-sample comparison, independent of the existing harness measurements.
## -- arm=normal|all|top4 first_seed=1000 games=40 library=<capture library> out=<jsonl>
## Every game runs to full lobby placement, with Hard in human seat. Source seats and the
## evaluation seeds are disjoint; identical seed numbers do not imply matched shop RNG.

var _options: Dictionary = {
	"arm": "normal",
	"first_seed": "1000",
	"games": "40",
	"library": "res://build/strong-field/measurement-library.json",
	"out": ""
}


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = arg.split("=", true, 1)
		assert(pair.size() == 2 and _options.has(pair[0]), "unknown comparison option")
		_options[pair[0]] = pair[1]
	var arm: String = _options["arm"]
	assert(arm in ["normal", "all", "top4"])
	var file := FileAccess.open(str(_options["out"]), FileAccess.WRITE)
	assert(file != null)
	var library := UnitLibrary.load_dir()
	for index: int in str(_options["games"]).to_int():
		var seed_value: int = str(_options["first_seed"]).to_int() + index
		var started: int = Time.get_ticks_msec()
		var config := GameConfig.full_game()
		config.set_value("human_bot", "hard")
		if arm != "normal":
			config.set_value("field_strength", arm)
			# Dynamic load also allows the normal arm to run unchanged in a 9af89c2 archive.
			var field_script: GDScript = load("res://src/core/field_library.gd")
			var problem: String = field_script.call(
				"configure", config, library, str(_options["library"])
			)
			assert(problem == "", problem)
		var session := GameSession.create(seed_value, library, config)
		assert(session != null)
		var field: RefCounted = session.get("_field") if arm != "normal" else null
		var human_rounds: int = 0
		var human_switches: int = 0
		var human_done: bool = false
		while not session.is_over():
			var played_round: int = session._round
			var before_switches: Array = [] if field == null else field.get("switches")
			var previous_count: int = before_switches.size()
			session.end_turn()
			if not human_done:
				human_rounds = played_round
				human_switches = previous_count
				human_done = not session._players[0].alive
		var switches: Array = [] if field == null else field.get("switches")
		var rivals: int = (
			switches
			. filter(func(entry: Dictionary) -> bool: return CoreUtil.to_int(entry["seat"]) >= 1)
			. size()
		)
		var row: Dictionary = {
			"arm": arm,
			"seed": seed_value,
			"place": session._players[0].placement,
			"rounds": session._round,
			"human_rounds": human_rounds,
			"switches": switches.size(),
			"rival_switches": rivals,
			"ghost_switches": switches.size() - rivals,
			"switches_before_human_end": human_switches,
			"elapsed_ms": Time.get_ticks_msec() - started
		}
		file.store_line(JSON.stringify(row, "", true, true))
		file.flush()
		print(
			(
				"field-compare: %s seed=%d place=%d switches=%d ms=%d"
				% [
					arm,
					seed_value,
					session._players[0].placement,
					switches.size(),
					Time.get_ticks_msec() - started
				]
			)
		)
	file.close()
	quit(0)
