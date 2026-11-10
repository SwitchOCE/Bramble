extends SceneTree
## Prints A3.5's rates override for a point on the dial paths, as one JSON object.
## godot --headless -s res://tools/checks/print_pass3_path.gd -- --t 1.5
## godot --headless -s res://tools/checks/print_pass3_path.gd -- --t birds=1.05,oozes=3
## Tribes left out of a per-tribe list sit at t = 0. Merge the output over the run's preset.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--t")
	if index < 0 or index + 1 >= args.size():
		printerr("pass3_path: usage: -- --t <t> | --t <tribe>=<t>[,<tribe>=<t>...]")
		quit(2)
		return
	var t: Variant = _parse(args[index + 1])
	if t == null:
		quit(2)
		return
	print(JSON.stringify(Pass3Path.override(t), "  ", true, true))
	quit(0)


func _parse(text: String) -> Variant:
	if not text.contains("="):
		if not text.is_valid_float():
			printerr("pass3_path: t must be a number: %s" % text)
			return null
		return text.to_float()
	var out: Dictionary = {}
	for part: String in text.split(","):
		var pair: PackedStringArray = part.split("=")
		if pair.size() != 2 or not Pass3Path.TRIBES.has(pair[0]) or not pair[1].is_valid_float():
			printerr(
				"pass3_path: bad tribe value %s (tribes: %s)" % [part, ", ".join(Pass3Path.TRIBES)]
			)
			return null
		out[pair[0]] = pair[1].to_float()
	return out
