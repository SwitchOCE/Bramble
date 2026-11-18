extends SceneTree
## See tools/league/fights/FORMAT.md. No recruit or end-turn hooks run here.
# gdlint: disable=max-returns
# Input validation reports the first problem without executing a partial fight.

var _content: GameContent


func _initialize() -> void:
	var opts: Dictionary = {"first": "0", "count": "-1"}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		opts[key] = arg.substr(key.length() + 1)
	if not opts.has("cases") or not opts.has("out"):
		printerr("usage: -- cases=<file> out=<file> [first=<n> count=<n>]")
		quit(2)
		return
	if (
		ProjectSettings.globalize_path(str(opts["cases"]))
		== ProjectSettings.globalize_path(str(opts["out"]))
	):
		printerr("cases and out must differ")
		quit(2)
		return
	var source := FileAccess.open(str(opts["cases"]), FileAccess.READ)
	if source == null:
		printerr("cannot open cases: ", FileAccess.get_open_error())
		quit(2)
		return
	var target := FileAccess.open(str(opts["out"]), FileAccess.WRITE)
	if target == null:
		printerr("cannot open out: ", FileAccess.get_open_error())
		quit(2)
		return
	_content = GameContent.load_default()
	if not _content.errors.is_empty():
		printerr("content errors: ", _content.errors)
		quit(2)
		return
	var first: int = str(opts["first"]).to_int()
	var count: int = str(opts["count"]).to_int()
	if first < 0 or count < -1:
		printerr("first must be >= 0; count must be >= 0 or -1 (all)")
		quit(2)
		return
	var completed: int = 0
	var rejected: int = 0
	var started: int = Time.get_ticks_usec()
	var line_number: int = _skip_lines(source, first)
	while not source.eof_reached() and (count < 0 or completed < count):
		var line: String = source.get_line()
		if line == "" and source.eof_reached():
			break
		line_number += 1
		var parser := JSON.new()
		var result: Dictionary
		if parser.parse(line) != OK or not parser.data is Dictionary:
			result = {"id": -1, "error": "line %d: expected JSON object" % line_number}
		else:
			var saved: Dictionary = parser.data
			result = _run(saved)
		if result.has("error"):
			rejected += 1
		target.store_line(JSON.stringify(result))
		completed += 1
		if completed % 1000 == 0:
			target.flush()
			printerr("fight_run progress cases=%d rejected=%d" % [completed, rejected])
	var elapsed: int = Time.get_ticks_usec() - started
	target.flush()
	var write_error: Error = target.get_error()
	target.close()
	source.close()
	printerr(
		(
			"fight_run cases=%d rejected=%d elapsed_us=%d us_per_fight=%.3f"
			% [completed, rejected, elapsed, float(elapsed) / maxi(1, completed)]
		)
	)
	quit(2 if write_error != OK else 0)


## Skip large shard prefixes as bytes, rather than decoding thousands of discarded payloads.
func _skip_lines(source: FileAccess, count: int) -> int:
	var skipped: int = 0
	while skipped < count and source.get_position() < source.get_length():
		var start: int = source.get_position()
		var bytes: PackedByteArray = source.get_buffer(1048576)
		var cursor: int = 0
		while cursor < bytes.size():
			var newline: int = bytes.find(10, cursor)
			if newline < 0:
				break
			skipped += 1
			cursor = newline + 1
			if skipped == count:
				source.seek(start + cursor)
				return skipped
	return skipped


func _run(saved: Dictionary) -> Dictionary:
	var case_id: int = CoreUtil.to_int(saved.get("id", -1))
	var problem: String = _validate(saved)
	if problem != "":
		return {"id": case_id, "error": problem}
	var game: GameSession = _content.new_session(str(saved["game_seed"]).to_int())
	game.keep_fight_events = false
	game.round_number = CoreUtil.to_int(saved["round"])
	var a: Dictionary = saved["a"]
	var b: Dictionary = saved["b"]
	_restore_player(game, a)
	_restore_player(game, b)
	var a_id: int = CoreUtil.to_int(a["id"])
	var b_id: int = CoreUtil.to_int(b["id"])
	game.pairings = [[a_id, b_id]]
	var fight: Dictionary = game._fight(a_id, b_id)
	var result: Dictionary = fight["result"]
	var state: String = JSON.stringify(RecordState.session_state(game))
	return {
		"id": case_id,
		"winner": result["winner"],
		"loser": fight["loser"],
		"damage": fight["damage"],
		"reason": result["reason"],
		"state": state,
		"hash": state.sha256_text(),
	}


func _restore_player(game: GameSession, saved: Dictionary) -> void:
	var owner: PlayerState = game.player(CoreUtil.to_int(saved["id"]))
	owner.tier = CoreUtil.to_int(saved["tier"])
	var counters: Dictionary = saved["counters"]
	owner.counters = counters.duplicate(true)
	var board: Array = saved["board"]
	for slot: int in board.size():
		if board[slot] != null:
			var snapshot: Dictionary = board[slot]
			var card: Unit = FightSnapshot.restore_unit(snapshot, game, slot)
			owner.board[slot] = card
			game._next_uid = maxi(game._next_uid, card.uid + 1)
	var hand: Array = saved["hand"]
	for raw: Dictionary in hand:
		var card: Unit = FightSnapshot.restore_unit(raw, game)
		owner.hand.append(card)
		game._next_uid = maxi(game._next_uid, card.uid + 1)
	var slots: Array = saved["slots"]
	for i: int in slots.size():
		var raw: Dictionary = slots[i]
		owner.slots[i].attack = CoreUtil.to_int(raw["attack"])
		owner.slots[i].health = CoreUtil.to_int(raw["health"])
		for keyword: String in raw["keywords"]:
			owner.slots[i].keywords.append(StringName(keyword))
	var heaps: Dictionary = saved["heaps"]
	for key: String in heaps:
		var raw: Dictionary = heaps[key]
		var heap := CardHeap.new()
		heap._next_n = CoreUtil.to_int(raw["_next_n"])
		for entry: Dictionary in raw["entries"]:
			(
				heap
				. entries
				. append(
					{
						"id": StringName(str(entry["id"])),
						"tier": CoreUtil.to_int(entry["tier"]),
						"n": CoreUtil.to_int(entry["n"]),
					}
				)
			)
		owner.heaps[StringName(key)] = heap
	owner.standing.clear()
	for raw: Dictionary in saved["standing"]:
		var params := MechanicParams.new()
		var fields: Dictionary = raw["params"]
		params.golden = CoreUtil.to_bool(fields["golden"])
		for key: String in ["_ints", "_texts", "_kinds", "_golden_ints"]:
			var field: Dictionary = fields[key]
			params.set(key, field.duplicate(true))
		var mechanic_id := StringName(str(raw["id"]))
		owner.standing.append(
			BoundMechanic.new(
				mechanic_id,
				game.registry.get_mechanic(mechanic_id),
				params,
				CoreUtil.to_bool(raw["granted"])
			)
		)


func _integer(raw: Variant, low: int, high: int = 9007199254740991) -> bool:
	if not (raw is int or raw is float):
		return false
	var number: float = raw
	return is_finite(number) and number == floor(number) and number >= low and number <= high


func _numbers(raw: Variant) -> bool:
	if not raw is Dictionary:
		return false
	var fields: Dictionary = raw
	for key: String in fields:
		if not _integer(fields[key], -9007199254740991):
			return false
	return true


func _validate(saved: Dictionary) -> String:
	if not _integer(saved.get("id"), 0):
		return "id must be a nonnegative integer"
	var seed_text: Variant = saved.get("game_seed")
	if not seed_text is String or str(str(seed_text).to_int()) != str(seed_text):
		return "game_seed must be canonical signed int64 decimal text"
	if not _integer(saved.get("round"), 1, 50):
		return "round must be in 1..50"
	if not saved.get("mutations") is Array:
		return "mutations must be an array of strings"
	for mutation: Variant in saved["mutations"]:
		if not mutation is String:
			return "mutations must be an array of strings"
	var seen: Dictionary = {}
	for side: String in ["a", "b"]:
		if not saved.get(side) is Dictionary:
			return side + ": missing player payload"
		var payload: Dictionary = saved[side]
		var problem: String = _validate_player(payload, seen)
		if problem != "":
			return side + ": " + problem
	var a: Dictionary = saved["a"]
	var b: Dictionary = saved["b"]
	if a["id"] == b["id"]:
		return "a and b must have distinct player ids"
	return ""


func _validate_player(saved: Dictionary, seen: Dictionary) -> String:
	if not _integer(saved.get("id"), 0, 7) or not _integer(saved.get("tier"), 1, 6):
		return "id must be in 0..7 and tier in 1..6 (ghosts unsupported)"
	for key: String in ["board", "hand", "slots", "standing"]:
		if not saved.get(key) is Array:
			return key + " must be an array"
	var board: Array = saved["board"]
	var slots: Array = saved["slots"]
	var hand: Array = saved["hand"]
	if board.size() != 7 or slots.size() != 7 or hand.size() > 7:
		return "expected 7 board slots, 7 slot states, and at most 7 hand cards"
	for key: String in ["board", "hand"]:
		for raw: Variant in saved[key]:
			if raw == null and key == "board":
				continue
			if not raw is Dictionary:
				return key + ": expected unit object"
			var unit_data: Dictionary = raw
			var problem: String = _validate_unit(unit_data, seen, key == "board")
			if problem != "":
				return key + ": " + problem
	for raw: Variant in slots:
		if not raw is Dictionary:
			return "slot must be an object"
		var slot: Dictionary = raw
		if not _integer(slot.get("attack"), 0) or not _integer(slot.get("health"), 0):
			return "slot stats must be nonnegative integers"
		if not slot.get("keywords") is Array:
			return "slot keywords must be an array"
		for keyword: Variant in slot["keywords"]:
			if not keyword is String or not _content.registry.has(StringName(str(keyword))):
				return "unknown slot keyword"
			if not _content.registry.kinds_of(StringName(str(keyword))).is_empty():
				return "slot keyword requires parameters"
	if not _numbers(saved.get("counters")):
		return "counters must be an integer dictionary"
	if not saved.get("heaps") is Dictionary:
		return "heaps must be an object"
	var heaps: Dictionary = saved["heaps"]
	for key: String in heaps:
		if MechanicRegistry.name_problem(_content.registry.prefixes, StringName(key), "heap") != "":
			return "heap name must have a content prefix"
		if not heaps[key] is Dictionary:
			return "heap must be an object"
		var heap: Dictionary = heaps[key]
		if not _integer(heap.get("_next_n"), 1) or not heap.get("entries") is Array:
			return "heap requires entries and positive _next_n"
		var previous: int = 0
		for raw: Variant in heap["entries"]:
			if not raw is Dictionary:
				return "heap entry must be an object"
			var entry: Dictionary = raw
			var card: UnitDef = _content.library.get_card(StringName(str(entry.get("id", ""))))
			if (
				card == null
				or card.is_spell()
				or not _integer(entry.get("tier"), card.tier, card.tier)
			):
				return "heap entry requires a valid unit card id and its exact tier"
			if not _integer(entry.get("n"), previous + 1, CoreUtil.to_int(heap["_next_n"]) - 1):
				return "heap entry n must increase and be below _next_n"
			previous = CoreUtil.to_int(entry["n"])
	for raw: Variant in saved["standing"]:
		if not raw is Dictionary:
			return "standing effect must be an object"
		var bound: Dictionary = raw
		if not _content.registry.has(StringName(str(bound.get("id", "")))):
			return "unknown standing effect"
		if not bound.get("granted") is bool or not bound.get("params") is Dictionary:
			return "standing effect requires granted and params"
		var params: Dictionary = bound["params"]
		if not params.get("golden") is bool or not params.get("_texts") is Dictionary:
			return "invalid standing parameter fields"
		for key: String in ["_ints", "_kinds", "_golden_ints"]:
			if not _numbers(params.get(key)):
				return "invalid standing parameter fields"
		var texts: Dictionary = params["_texts"]
		for key: String in texts:
			if not texts[key] is String:
				return "standing text parameter must be text"
	return ""


func _validate_unit(saved: Dictionary, seen: Dictionary, on_board: bool) -> String:
	var card: UnitDef = _content.library.get_card(StringName(str(saved.get("def", ""))))
	if card == null or (on_board and card.is_spell()):
		return "unknown card or board spell"
	if not _integer(saved.get("uid"), 1) or not saved.get("golden") is bool:
		return "unit requires positive uid and boolean golden"
	var uid: int = CoreUtil.to_int(saved["uid"])
	if seen.has(uid):
		return "duplicate uid %d" % uid
	seen[uid] = true
	if saved.has("from_triple") and not saved["from_triple"] is bool:
		return "from_triple must be boolean"
	for key: String in ["bought_copies", "pool_copies"]:
		if saved.has(key) and not _integer(saved[key], 0):
			return key + " must be a nonnegative integer"
	for key: String in ["stats", "counters", "turn_counters"]:
		if saved.has(key) and not _numbers(saved[key]):
			return key + " must be an integer dictionary"
	var stats: Dictionary = saved.get("stats", {})
	for key: String in stats:
		if not FightSnapshot.LAYERS.has(key):
			return "unknown stat layer: " + key
	for key: String in ["grants", "aura_grants"]:
		if saved.has(key) and not saved[key] is Array:
			return key + " must be an array"
		for raw: Variant in saved.get(key, []):
			if not raw is Array:
				return "grant must be an array"
			var entry: Array = raw
			if entry.size() < 1 or entry.size() > 2:
				return "grant must contain an id and optional values"
			var mechanic_id := StringName(str(entry[0]))
			if not _content.registry.has(mechanic_id):
				return "unknown granted mechanic"
			if entry.size() == 2 and not entry[1] is Dictionary:
				return "grant values must be an object"
			if (
				(entry.size() == 2 or key == "aura_grants")
				and (
					_content.registry.bind_given(
						mechanic_id, CoreUtil.to_dict(entry[1]) if entry.size() == 2 else {}
					)
					== null
				)
			):
				return "invalid granted mechanic parameters"
	return ""
