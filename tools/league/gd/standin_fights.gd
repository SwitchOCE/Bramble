extends "res://tools/league/gd/fight_run.gd"
## Random isolated-fight corpus and full-state oracle. No recruit or End of Turn hooks run.
## -- cases=<JSONL> out=<oracle JSONL> [count=20000 seed=20261118 folders=shared,badger]
## Empty/omitted folders loads stand-ins. Folder order is retained in each case's recipe.

const KEYWORDS: Array[StringName] = [
	&"taunt", &"divine_shield", &"windfury", &"reborn", &"venomous", &"stealth", &"cleave"
]

var _generator_content: GameContent
var _generator_rng: Rng
var _generator_folders: Array[String] = []
var _unit_ids: Array[StringName] = []
var _all_ids: Array[StringName] = []
var _coverage: Dictionary = {
	"board_sizes": [0, 0, 0, 0, 0, 0, 0, 0],
	"hand_sizes": [0, 0, 0, 0, 0, 0, 0, 0],
	"golden": 0,
	"slot_buffs": 0,
	"slot_keywords": 0,
	"grants": 0,
	"spells_in_hand": 0,
	"cards": {},
	"reasons": {},
}


func _initialize() -> void:
	var opts: Dictionary = {"count": "20000", "seed": "20261118", "folders": ""}
	for arg: String in OS.get_cmdline_user_args():
		var key: String = arg.get_slice("=", 0)
		opts[key] = arg.substr(key.length() + 1)
	if not opts.has("cases") or not opts.has("out"):
		printerr("usage: -- cases=<file> out=<file> [count=20000 seed=20261118 folders=]")
		quit(2)
		return
	var wanted: int = str(opts["count"]).to_int()
	var seed_text: String = str(opts["seed"])
	if wanted < 1 or str(seed_text.to_int()) != seed_text:
		printerr("count must be positive; seed must be canonical signed int64 decimal text")
		quit(2)
		return
	var paths: PackedStringArray = []
	if str(opts["folders"]) != "":
		for folder: String in str(opts["folders"]).split(","):
			if not _valid_folder(folder):
				printerr("folders must contain src/content folder names")
				quit(2)
				return
			_generator_folders.append(folder)
			paths.append("res://src/content/" + folder)
	_generator_content = GameContent.load_folders(paths)
	if not _generator_content.errors.is_empty():
		printerr("content errors: ", _generator_content.errors)
		quit(2)
		return
	# The inherited oracle restores a new session and calls _fight once per saved case.
	_content = _generator_content
	_generator_rng = Rng.new(seed_text.to_int())
	for card_id: StringName in _generator_content.library.ids():
		_all_ids.append(card_id)
		if not _generator_content.library.get_card(card_id).is_spell():
			_unit_ids.append(card_id)
	if _unit_ids.is_empty():
		printerr("content has no unit cards")
		quit(2)
		return
	var cases_path: String = str(opts["cases"])
	var out_path: String = str(opts["out"])
	if ProjectSettings.globalize_path(cases_path) == ProjectSettings.globalize_path(out_path):
		printerr("cases and out must differ")
		quit(2)
		return
	_generate(cases_path, out_path, wanted, seed_text)


func _valid_folder(folder: String) -> bool:
	if folder == "" or folder == "." or folder == "..":
		return false
	for character: String in folder:
		if not (
			(character >= "a" and character <= "z")
			or (character >= "A" and character <= "Z")
			or (character >= "0" and character <= "9")
			or character == "_"
			or character == "-"
		):
			return false
	return true


func _generate(cases_path: String, out_path: String, wanted: int, seed_text: String) -> void:
	var cases_file := FileAccess.open(cases_path, FileAccess.WRITE)
	var out_file := FileAccess.open(out_path, FileAccess.WRITE)
	var rejected_file := FileAccess.open(cases_path + ".rejected.jsonl", FileAccess.WRITE)
	if cases_file == null or out_file == null or rejected_file == null:
		printerr("cannot open corpus/oracle/rejected output: ", FileAccess.get_open_error())
		quit(2)
		return
	var completed: int = 0
	var attempted: int = 0
	var rejected: Dictionary = {}
	var started: int = Time.get_ticks_usec()
	while completed < wanted:
		var candidate: Dictionary = _make_case(attempted)
		var text: String = JSON.stringify(candidate)
		# Match a separately streamed runner's float-valued JSON numbers before restoration.
		var saved: Dictionary = JSON.parse_string(text)
		var result: Dictionary = _run(saved)
		attempted += 1
		if CoreUtil.to_int(result.get("id", -1)) != CoreUtil.to_int(candidate["id"]):
			printerr("oracle returned a missing or mismatched case id")
			quit(2)
			return
		if result.has("error"):
			var problem: String = str(result["error"])
			rejected[problem] = CoreUtil.to_int(rejected.get(problem, 0)) + 1
			rejected_file.store_line(JSON.stringify({"case": candidate, "error": problem}))
			if attempted > wanted * 10:
				printerr("too many rejected candidates: ", rejected)
				quit(2)
				return
			continue
		if not _complete_result(result):
			printerr("oracle returned an incomplete result for case ", candidate["id"])
			quit(2)
			return
		cases_file.store_line(text)
		out_file.store_line(JSON.stringify(result))
		_count_coverage(candidate, result)
		completed += 1
		if completed % 1000 == 0:
			cases_file.flush()
			out_file.flush()
			rejected_file.flush()
			printerr("standin_fights cases=%d attempted=%d" % [completed, attempted])
	cases_file.flush()
	out_file.flush()
	rejected_file.flush()
	var failed: bool = (
		cases_file.get_error() != OK
		or out_file.get_error() != OK
		or rejected_file.get_error() != OK
	)
	cases_file.close()
	out_file.close()
	rejected_file.close()
	var elapsed: int = Time.get_ticks_usec() - started
	var report: Dictionary = {
		"seed": seed_text,
		"count": completed,
		"attempted": attempted,
		"content": {"folders": _generator_folders},
		"rejected": rejected,
		"coverage": _coverage,
		"elapsed_us": elapsed,
		"us_per_fight": float(elapsed) / maxi(1, completed),
		"generator_sha256": FileAccess.get_sha256("res://tools/league/gd/standin_fights.gd"),
		"oracle_sha256": FileAccess.get_sha256("res://tools/league/gd/fight_run.gd"),
		"godot": Engine.get_version_info(),
	}
	var report_file := FileAccess.open(cases_path + ".report.json", FileAccess.WRITE)
	if report_file == null:
		failed = true
	else:
		report_file.store_line(JSON.stringify(report))
		report_file.flush()
		failed = failed or report_file.get_error() != OK
		report_file.close()
	printerr("standin_fights " + JSON.stringify(report))
	quit(2 if failed else 0)


func _complete_result(result: Dictionary) -> bool:
	for key: String in ["winner", "loser", "damage", "reason", "state", "hash"]:
		if not result.has(key):
			return false
	if not result["state"] is String or not result["hash"] is String:
		return false
	return str(result["state"]).sha256_text() == str(result["hash"])


func _make_case(case_id: int) -> Dictionary:
	var game_seed: String = _next_seed(case_id)
	var game: GameSession = _generator_content.new_session(game_seed.to_int())
	var a_id: int = _generator_rng.range_int(0, 7)
	var b_id: int = (a_id + _generator_rng.range_int(1, 7)) % 8
	var a: Dictionary = _make_player(game, a_id, case_id % 8)
	var b: Dictionary = _make_player(game, b_id, _generator_rng.range_int(0, 7))
	return {
		"id": case_id,
		"game_seed": game_seed,
		"round": _generator_rng.range_int(1, 50),
		"a": a,
		"b": b,
		"mutations": ["random:boards,hands,golden,stats,slots,grants"],
		"content": {"folders": _generator_folders.duplicate()},
	}


func _next_seed(case_id: int) -> String:
	if case_id < 4:
		return ["-9223372036854775808", "9223372036854775807", "0", "-1"][case_id]
	# Bitwise composition retains every signed int64 bit without floating-point conversion.
	return str((_generator_rng.next_u32() << 32) | _generator_rng.next_u32())


func _make_player(game: GameSession, player_id: int, board_count: int) -> Dictionary:
	var owner: PlayerState = game.player(player_id)
	owner.tier = _generator_rng.range_int(1, 6)
	var positions: Array = [0, 1, 2, 3, 4, 5, 6]
	_generator_rng.shuffle(positions)
	for i: int in board_count:
		var slot: int = CoreUtil.to_int(positions[i])
		var card: Unit = _make_unit(game, false)
		card.slot = slot
		owner.board[slot] = card
	for _i: int in _generator_rng.range_int(0, 7):
		owner.hand.append(_make_unit(game, true))
	for slot: SlotState in owner.slots:
		if _generator_rng.range_int(0, 2) == 0:
			slot.attack = _generator_rng.range_int(0, 20)
			slot.health = _generator_rng.range_int(0, 20)
		if _generator_rng.range_int(0, 4) == 0:
			slot.keywords.append(KEYWORDS[_generator_rng.index(KEYWORDS.size())])
			if _generator_rng.range_int(0, 3) == 0:
				slot.keywords.append(KEYWORDS[_generator_rng.index(KEYWORDS.size())])
	var heaps: Dictionary = {}
	for key: StringName in owner.heaps:
		heaps[String(key)] = RecordState.value(owner.heaps[key])
	return {
		"id": owner.id,
		"tier": owner.tier,
		"board": FightSnapshot.units(owner.board),
		"hand": FightSnapshot.units(owner.hand),
		"slots": RecordState.value(owner.slots),
		"counters": RecordState.value(owner.counters),
		"heaps": heaps,
		"standing": RecordState.value(owner.standing),
	}


func _make_unit(game: GameSession, in_hand: bool) -> Unit:
	var choices: Array[StringName] = _all_ids if in_hand else _unit_ids
	var card_id: StringName = choices[_generator_rng.index(choices.size())]
	var card: Unit = game.new_unit(
		_generator_content.library.get_card(card_id), _generator_rng.range_int(0, 3) == 0
	)
	if card.is_spell():
		return card
	card.bought_copies = _generator_rng.range_int(0, 3)
	card.pool_copies = _generator_rng.range_int(0, 3)
	if _generator_rng.range_int(0, 1) == 0:
		card.stats.perm_attack = _generator_rng.range_int(0, 30)
		card.stats.perm_health = _generator_rng.range_int(0, 30)
	if _generator_rng.range_int(0, 4) == 0:
		card.stats.turn_attack = _generator_rng.range_int(0, 10)
		card.stats.turn_health = _generator_rng.range_int(0, 10)
	if _generator_rng.range_int(0, 9) == 0:
		card.stats.set_attack = _generator_rng.range_int(0, 30)
		card.stats.set_health = _generator_rng.range_int(1, 30)
	if _generator_rng.range_int(0, 4) == 0:
		card.grant(game.registry, KEYWORDS[_generator_rng.index(KEYWORDS.size())])
	if _generator_rng.range_int(0, 4) == 0:
		_grant_effect(game, card)
	return card


func _grant_effect(game: GameSession, card: Unit) -> void:
	var amount: int = _generator_rng.range_int(1, 8)
	match _generator_rng.range_int(0, 5):
		0:
			card.grant_effect(game.registry, &"aura_attack", {"amount": amount})
		1:
			card.grant_effect(game.registry, &"start_combat_damage", {"amount": amount})
		2:
			card.grant_effect(game.registry, &"rally_gain", {"attack": amount})
		3:
			card.grant_effect(game.registry, &"attacked_gain", {"health": amount})
		4:
			card.grant_effect(game.registry, &"kill_gain", {"attack": amount, "health": amount})
		5:
			card.grant_effect(
				game.registry, &"avenge_buff", {"every": 2, "attack": amount, "health": amount}
			)


func _count_coverage(saved: Dictionary, result: Dictionary) -> void:
	var reasons: Dictionary = _coverage["reasons"]
	var cards: Dictionary = _coverage["cards"]
	var reason: String = str(result["reason"])
	reasons[reason] = CoreUtil.to_int(reasons.get(reason, 0)) + 1
	for side: String in ["a", "b"]:
		var owner: Dictionary = saved[side]
		var board_count: int = 0
		for raw: Variant in owner["board"]:
			if raw != null:
				board_count += 1
		_coverage["board_sizes"][board_count] += 1
		_coverage["hand_sizes"][CoreUtil.to_array(owner["hand"]).size()] += 1
		for key: String in ["board", "hand"]:
			for raw: Variant in owner[key]:
				if raw == null:
					continue
				var unit: Dictionary = raw
				var card_id: String = str(unit["def"])
				cards[card_id] = CoreUtil.to_int(cards.get(card_id, 0)) + 1
				if CoreUtil.to_bool(unit["golden"]):
					_coverage["golden"] += 1
				if unit.has("grants"):
					_coverage["grants"] += 1
				if key == "hand" and _generator_content.library.get_card(card_id).is_spell():
					_coverage["spells_in_hand"] += 1
		for slot: Dictionary in owner["slots"]:
			if CoreUtil.to_int(slot["attack"]) > 0 or CoreUtil.to_int(slot["health"]) > 0:
				_coverage["slot_buffs"] += 1
			if not CoreUtil.to_array(slot["keywords"]).is_empty():
				_coverage["slot_keywords"] += 1
