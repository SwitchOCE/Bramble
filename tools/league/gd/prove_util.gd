extends SceneTree
## Capture utility oracle vectors from the pinned Godot executable.
## timeout -k 10 60 godot --headless -s res://tools/league/gd/prove_util.gd


func _initialize() -> void:
	var vectors: Array = []
	for seed_text: String in ["0", "1", "-1", "4294967295", "9223372036854775807", "-9223372036854775808"]:
		var seed_value: int = seed_text.to_int()
		for label: String in ["", "shop:3", "pairings", "⛄|à"]:
			var rng: Rng = Rng.derive(seed_value, label)
			vectors.append(_rng_vector(seed_text, label, rng))
		vectors.append(_rng_vector(seed_text, "DIRECT", Rng.new(seed_value)))
	var tie_orders: Dictionary = {}
	for size: int in [17, 24, 64, 257]:
		var tied: Array = []
		for i: int in size:
			tied.append([i % 5, i])
		tied.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var order: Array = []
		for item: Array in tied:
			order.append(item[1])
		tie_orders[str(size)] = order
	var escape_text: String = "\\\"\b\f\n\r\t\v/ café ⛄ 🦔 \u0001"
	var number_values: Array = [0, -1, -9223372036854775807 - 1, 9223372036854775807,
		0.0, -0.0, 1.0, -1.0, 0.1, -123.456, 1.2345678901234567,
		1e20, -1e20, 1e-20, -1e-35, 1e-100, 1e300, INF, -INF]
	var cases: Dictionary = {
		"escapes": JSON.stringify(escape_text),
		"unicode_keys": JSON.stringify({"🦔": 1, "é": 2, "z": 3, "⛄": 4, "a": 5}),
		"numbers": JSON.stringify(number_values),
		"nested": JSON.stringify({"z": [{}, [], {"a": null, "b": false}], "a": {}}),
	}
	var text: String = JSON.stringify({"rng": vectors, "sort": tie_orders, "json": cases})
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			var file := FileAccess.open(arg.substr(4), FileAccess.WRITE)
			if file == null:
				printerr("cannot write utility oracle")
				quit(1)
				return
			file.store_string(text)
			file.close()
	print("BRAMBLE_UTIL_VECTORS=" + text)
	quit()


func _rng_vector(seed_text: String, label: String, rng: Rng) -> Dictionary:
	var initial: Array = Array(rng._s)
	var next: Array = []
	for _i: int in 12:
		next.append(rng.next_u32())
	var ranges: Array = []
	for _i: int in 12:
		ranges.append(rng.range_int(-13, 27))
	for _i: int in 12:
		ranges.append(rng.range_int(0, 2147483648))
	var shuffled: Array = []
	for i: int in 24:
		shuffled.append(i)
	rng.shuffle(shuffled)
	return {"seed": seed_text, "label": label, "initial": initial, "next": next,
		"ranges": ranges, "shuffle": shuffled, "final": Array(rng._s)}
