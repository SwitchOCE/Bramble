extends SceneTree
## Load-only diagnostic: -- library=<path> mode=prepared|legacy
## Run under /usr/bin/time -v for process peak RSS. No games are played.


func _initialize() -> void:
	var options: Dictionary = {"library": "", "mode": "prepared"}
	for arg: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = arg.split("=", true, 1)
		if pair.size() != 2 or not options.has(pair[0]):
			printerr("load-profile: invalid option: %s" % arg)
			quit(2)
			return
		options[pair[0]] = pair[1]
	if options["mode"] not in ["prepared", "legacy"] or str(options["library"]).is_empty():
		printerr("load-profile: require library=<path> mode=prepared|legacy")
		quit(2)
		return
	var units := UnitLibrary.load_dir()
	var config := GameConfig.full_game()
	var start: int = Time.get_ticks_msec()
	var prepared: FieldLibrary = null
	var problem: String
	if options["mode"] == "legacy":
		# Reproduce the previous configure + create path, which discarded the first snapshot.
		problem = FieldLibrary.configure(config, units, str(options["library"]))
	else:
		prepared = FieldLibrary.prepare(config, units, str(options["library"]))
		problem = prepared.error
	var loaded: int = Time.get_ticks_msec()
	if problem != "":
		printerr("load-profile: %s" % problem)
		quit(1)
		return
	var session := GameSession.create(71, units, config, Bot.create, prepared)
	if session == null:
		printerr("load-profile: session rejected the library/config")
		quit(1)
		return
	print(
		(
			"load-profile: "
			+ JSON.stringify(
				{
					"mode": options["mode"],
					"library": options["library"],
					"load_ms": loaded - start,
					"session_ms": Time.get_ticks_msec() - loaded,
					"total_ms": Time.get_ticks_msec() - start,
					"reused_snapshot": prepared != null and session._field.library == prepared
				}
			)
		)
	)
	quit()
