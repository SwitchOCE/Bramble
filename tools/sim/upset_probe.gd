extends SceneTree
## -- <baseline-field.json> <frozen-plan.json> <trials.jsonl>
## A plan freezes exactly eight ID pairs and eight explicit seeds before any fight is run.


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("upset_probe: expected baseline-field.json frozen-plan.json trials.jsonl")
		quit(2)
		return
	var source_text: String = FileAccess.get_file_as_string(args[0])
	var field: Dictionary = JSON.parse_string(source_text)
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	assert(str(plan["field_sha256"]) == source_text.sha256_text(), "baseline field hash changed")
	var pairs: Array = plan["pairs"]
	var seeds: Array = plan["seeds"]
	assert(pairs.size() == 8 and seeds.size() == 8, "freeze eight pairs and eight seeds")
	var seen_seeds: Dictionary = {}
	for seed_value: Variant in seeds:
		var seed_text: String = str(seed_value)
		assert(seed_text.is_valid_int(), "seeds must be explicit integer strings")
		assert(not seen_seeds.has(seed_text), "duplicate seed")
		seen_seeds[seed_text] = true
	var indexed: Dictionary = {}
	var rounds: Dictionary = field["rounds"]
	for round_key: String in rounds:
		for board: Dictionary in rounds[round_key]["boards"]:
			var id: String = str(board["id"])
			assert(not indexed.has(id), "board IDs must be unique")
			indexed[id] = board
	var seen_pairs: Dictionary = {}
	for pair: Dictionary in pairs:
		var a: String = str(pair["a"])
		var b: String = str(pair["b"])
		assert(a != b and indexed.has(a) and indexed.has(b), "unknown/same board")
		var ids: Array[String] = [a, b]
		ids.sort()
		var key: String = JSON.stringify(ids)
		assert(not seen_pairs.has(key), "duplicate diagnostic pair")
		seen_pairs[key] = true
		var left: Dictionary = indexed[a]
		var right: Dictionary = indexed[b]
		assert(CoreUtil.to_int(left["round"]) == CoreUtil.to_int(right["round"]))
	var library := UnitLibrary.load_dir()
	for card: Dictionary in field.get("test_cards", []):
		assert(library.register_unit(card) == "")
	var output := FileAccess.open(args[2], FileAccess.WRITE)
	assert(output != null)
	var fights: int = 0
	for pair: Dictionary in pairs:
		var a: Dictionary = indexed[str(pair["a"])]
		var b: Dictionary = indexed[str(pair["b"])]
		for seed_value: Variant in seeds:
			for orientation: int in 2:
				var row: Dictionary = _trial(a, b, str(seed_value).to_int(), orientation, library)
				row["field_sha256"] = str(plan["field_sha256"])
				row["plan_sha256"] = FightCapture.canonical(plan).sha256_text()
				output.store_line(JSON.stringify(row))
				fights += CoreUtil.to_int(row["fights"])
		output.flush()
	output.close()
	assert(fights == 1024, "fixed diagnostic budget")
	print("upset_probe: 128 controlled trials, %d fights" % fights)
	quit(0)


func _trial(
	a: Dictionary, b: Dictionary, seed_value: int, orientation: int, library: UnitLibrary
) -> Dictionary:
	var left: Dictionary = a if orientation == 0 else b
	var right: Dictionary = b if orientation == 0 else a
	var input: Dictionary = FieldCombat.pair_input(left, right, seed_value)
	var original_hash: String = FightCapture.canonical(input).sha256_text()
	var prepared: Dictionary = UpsetCombat.prepare(input, library)
	var intact_library: UnitLibrary = prepared["intact_library"]
	var masked_library: UnitLibrary = prepared["library"]
	var masked_input: Dictionary = prepared["input"]
	var layouts: Dictionary = {}
	for board: Dictionary in [a, b]:
		var id: String = str(board["id"])
		var body: Array = board["board"]
		var rules: Dictionary = board["fight_rules"]
		layouts[id] = UpsetCombat.alternate_layout(id, body, rules)
	var outcomes: Dictionary = {}
	for masked: bool in [false, true]:
		var base: Dictionary = masked_input if masked else input
		var fight_library: UnitLibrary = masked_library if masked else intact_library
		var prefix: String = "masked" if masked else "intact"
		for layout: String in ["original", "a_alternate", "b_alternate"]:
			var changed: Dictionary = base.duplicate(true)
			if layout != "original":
				var board_id: String = str(a["id"] if layout == "a_alternate" else b["id"])
				var side: int = 0 if str(left["id"]) == board_id else 1
				# Move the MASKED specs using the same permutation, so grants remain masked.
				var old: Array = base["boards"][side]
				var moved: Array = old.duplicate(true)
				var mapping: Array = layouts[board_id]["old_to_new"]
				for slot: int in old.size():
					moved[CoreUtil.to_int(mapping[slot])] = old[slot]
				changed["boards"][side] = moved
			var run: Dictionary = UpsetCombat.run_input(changed, fight_library)
			outcomes[prefix + "." + layout] = _outcome(run, orientation)
		var flipped: Dictionary = UpsetCombat.run_input(base, fight_library, true)
		outcomes[prefix + ".coin_flipped"] = _outcome(flipped, orientation)
	assert(FightCapture.canonical(input).sha256_text() == original_hash, "baseline input mutated")
	for id: String in layouts:
		var layout: Dictionary = layouts[id]
		layout.erase("board")
	return {
		"version": 1,
		"a": a["id"],
		"b": b["id"],
		"round": input["round"],
		"seed": str(seed_value),
		"orientation": orientation,
		"side_board_ids": [left["id"], right["id"]],
		"baseline_input_sha256": original_hash,
		"mask_supported": prepared["supported"],
		"mask_scope": prepared["scope"],
		"mask_manifest": prepared["manifest"],
		"mask_unsupported": prepared["unsupported"],
		"layouts": layouts,
		"outcomes": outcomes,
		"fights": 8,
	}


func _outcome(run: Dictionary, orientation: int) -> Dictionary:
	var result: Dictionary = run["result"]
	result.erase("events")
	var winner: int = CoreUtil.to_int(result["winner"])
	return {
		"winner": winner if winner < 0 or orientation == 0 else 1 - winner,
		"result": result,
		"first_side_original": run["first_side_original"],
		"first_side_used": run["first_side_used"],
		"first_coin_eligible": run["first_coin_eligible"],
	}
