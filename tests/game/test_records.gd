extends GutTest
## Records are read back from disk, not replayed from an in-memory copy of the game's inputs.

var _content: GameContent
var _previous_directory: String


func before_all() -> void:
	_content = GameContent.load_default()
	_previous_directory = GameRecord.directory
	GameRecord.directory = "res://build/test-records"


func after_all() -> void:
	GameRecord.directory = _previous_directory


func _play(game_seed: int, turns: int = 3) -> GameSession:
	var game: GameSession = _content.new_session(game_seed)
	game.config.round_limit = turns
	game.keep_fight_events = false
	var bots: Array[Bot] = []
	for seat: int in game.players.size():
		bots.append(FlowBot.new(Rng.derive(game_seed, "bot:%d" % seat)))
	while not game.over:
		game.start_round()
		for player: PlayerState in game.alive_players():
			bots[player.id].take_turn(game, player.id)
		game.finish_round()
	return game


func _entries(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		out.append(CoreUtil.to_dict(JSON.parse_string(line)))
	return out


func test_seeded_games_rebuild_all_turns_and_hidden_state_from_disk() -> void:
	for game_seed: int in [1, 7, 29, 999, 9223372036854775807]:
		var game: GameSession = _play(game_seed)
		var replay: Dictionary = RecordReplay.read(game.record.path)
		assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
		if not CoreUtil.to_bool(replay.get("ok", false)):
			continue
		assert_true(CoreUtil.to_bool(replay["complete"]))
		assert_eq(CoreUtil.to_int(replay["checkpoints"]), game.round_number * 3)
		var rebuilt: GameSession = replay["session"]
		assert_eq(RecordState.state_hash(rebuilt), RecordState.state_hash(game))
		assert_null(rebuilt.record, "replay does not create a second record")


func test_one_changed_action_names_the_first_differing_turn() -> void:
	var game: GameSession = _play(17)
	var entries: Array[Dictionary] = _entries(game.record.path)
	var changed: bool = false
	for entry: Dictionary in entries:
		var action: Dictionary = CoreUtil.to_dict(entry.get("action", {}))
		if (
			entry.get("op") == "act"
			and CoreUtil.to_int(entry.get("turn", 0)) == 2
			and action.get("type") in ["buy", "upgrade", "refresh"]
		):
			entry["action"] = {"type": "freeze"}
			changed = true
			break
	assert_true(changed, "planted a changed action on turn 2")
	if not changed:
		return
	var replay: Dictionary = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_eq(CoreUtil.to_int(replay["turn"]), 2)
	assert_string_contains(str(replay["message"]), "first differing turn 2")


func test_partial_human_game_records_refusals_and_explicit_end_turns() -> void:
	var flow: GameFlow = FlowFixture.live(_content, 41, ["mouse", "badger"])
	flow.start_round()
	assert_ne(flow.act({"type": "upgrade"}), "", "refused input is also retained")
	flow.session.end_turn(0)
	flow.finish_round()
	flow.start_round()
	flow.act({"type": "freeze"})
	var replay: Dictionary = RecordReplay.read(flow.session.record.path)
	assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
	assert_false(CoreUtil.to_bool(replay.get("complete", true)), "quit during recruit")
	if replay.get("ok", false):
		var rebuilt: GameSession = replay["session"]
		assert_eq(RecordState.state_hash(rebuilt), RecordState.state_hash(flow.session))
	var header: Dictionary = _entries(flow.session.record.path)[0]
	assert_true(header.has("build"))
	assert_eq(str(header["seed"]), "41")


func test_core_bot_runner_recipe_and_nondefault_config_replay() -> void:
	var content: ContentSet = ContentSet.load_folders(
		["res://src/content/shared", "res://tests/core/content/neutral"]
	)
	var config := GameConfig.new()
	config.players = 4
	config.round_limit = 2
	config.starting_armor = 5
	config.unit_weights_by_tier = [3, 5]
	config.spell_weights_by_tier = [2, 1]
	var game: GameSession = content.session(1234, config)
	while not game.over:
		game.start_round()
		for player: PlayerState in game.alive_players():
			var bot := RandomBot.new(
				Rng.derive(game.seed_value, "bot:%d:%d" % [player.id, game.round_number])
			)
			bot.take_turn(game, player.id)
		game.finish_round()
	var replay: Dictionary = RecordReplay.read(game.record.path)
	assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))
	assert_true(CoreUtil.to_bool(replay.get("complete", false)))


func test_fight_boards_are_after_end_turn_with_all_ghost_rules_data() -> void:
	var game: GameSession = _play(17, 2)
	var snapshots: int = 0
	var actions_by_player: Dictionary = {}
	for entry: Dictionary in _entries(game.record.path):
		if entry.get("op") == "act":
			actions_by_player[CoreUtil.to_int(entry["player"])] = true
		if entry.get("op") != "fight_boards":
			continue
		snapshots += 1
		var players: Array = entry["players"]
		assert_eq(players.size(), 8, "all eight players before early fights")
		for raw: Variant in players:
			var player: Dictionary = raw
			for key: String in [
				"id", "tier", "board", "hand", "slots", "counters", "heaps", "standing"
			]:
				assert_true(player.has(key), "ghost has %s" % key)
			var board: Array = player["board"]
			assert_eq(board.size(), game.geometry.slot_count)
			for unit_raw: Variant in board:
				if unit_raw == null:
					continue
				var unit: Dictionary = unit_raw
				var stats: Dictionary = CoreUtil.to_dict(unit.get("stats", {}))
				assert_eq(CoreUtil.to_int(stats.get("turn_attack", 0)), 0, "this-turn buffs ended")
				assert_false(unit.has("mechanics"), "base mechanics come from the card")
				assert_true(unit.has("def"), "card id for reconstruction")
	assert_eq(snapshots, 2)
	assert_eq(actions_by_player.size(), 8, "every player's actions")


func test_hash_covers_state_that_the_ui_omits() -> void:
	var game: GameSession = _content.new_session(5)
	game.record_recipe = {}
	game.start_round()
	var previous: String = RecordState.state_hash(game)
	game.player(0).gold_next_turn += 1
	assert_ne(RecordState.state_hash(game), previous)
	previous = RecordState.state_hash(game)
	game.recruit.shop_rng(game.player(0)).next_u32()
	assert_ne(RecordState.state_hash(game), previous, "RNG words")
	previous = RecordState.state_hash(game)
	game.player(0).heap(&"test").add(&"id", 1)
	assert_ne(RecordState.state_hash(game), previous, "heap")
	var heap: CardHeap = game.player(0).heap(&"test")
	heap.entries.clear()
	previous = RecordState.state_hash(game)
	heap.add(&"id", 1)
	heap.entries.clear()
	assert_ne(RecordState.state_hash(game), previous, "heap sequence even when empty")
	assert_false(RecordState.session_state(game).has("unit_odds"))
	assert_false(RecordState.session_state(game).has("spell_odds"))


func test_older_record_formats_are_refused_before_replay() -> void:
	for format: int in [1, 2]:
		var entries: Array[Dictionary] = [{"op": "header", "format": format}]
		var replay: Dictionary = RecordReplay.rebuild(entries)
		assert_false(CoreUtil.to_bool(replay["ok"]))
		assert_eq(CoreUtil.to_int(replay["turn"]), 0)
		assert_string_contains(str(replay["message"]), "unsupported record format %d" % format)


func test_same_seed_games_get_separate_files_and_changed_build_is_refused() -> void:
	var first: GameSession = _play(7, 1)
	var second: GameSession = _play(7, 1)
	assert_ne(first.record.path, second.record.path)
	var entries: Array[Dictionary] = _entries(first.record.path)
	var build: Dictionary = entries[0]["build"]
	build["rules_hash"] = "different"
	var replay: Dictionary = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_string_contains(str(replay["message"]), "build differs")


func test_missing_checkpoint_or_unknown_operation_fails() -> void:
	var game: GameSession = _play(7, 1)
	var entries: Array[Dictionary] = _entries(game.record.path)
	entries[1].erase("hash")
	var replay: Dictionary = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_eq(CoreUtil.to_int(replay["turn"]), 1)
	entries = _entries(game.record.path)
	entries[1]["op"] = "bogus"
	replay = RecordReplay.rebuild(entries)
	assert_false(CoreUtil.to_bool(replay["ok"]))
	assert_string_contains(str(replay["message"]), "unknown operation")


func test_ghost_opponents_keep_their_actual_board_and_reserve_hand() -> void:
	var game: GameSession = _play(3, 50)
	var ghost_fights: int = 0
	for entry: Dictionary in _entries(game.record.path):
		if entry.get("op") != "fight_boards":
			continue
		var players: Array = entry["players"]
		for raw: Variant in players:
			var player: Dictionary = raw
			if CoreUtil.to_int(player["id"]) != Matchmaking.GHOST:
				continue
			ghost_fights += 1
			assert_true(player.has("of"))
			assert_eq(CoreUtil.to_array(player["board"]).size(), game.geometry.slot_count)
			assert_true(player.has("hand"))
	assert_gt(ghost_fights, 0, "a complete game encountered the eliminated player's ghost")
	var replay: Dictionary = RecordReplay.read(game.record.path)
	assert_true(CoreUtil.to_bool(replay.get("ok", false)), str(replay.get("message", "")))


func test_plain_and_golden_card_snapshots_omit_fixed_data() -> void:
	var game: GameSession = _content.new_session(1)
	var definition: UnitDef = _content.library.get_card(&"hedge-knight")
	for golden: bool in [false, true]:
		var card: Unit = Unit.create(definition, 91, golden, game.registry, game.config.stat_max)
		var saved: Dictionary = FightSnapshot.unit(card)
		assert_eq(saved, {"def": String(definition.id), "uid": 91, "golden": golden})
		var restored: Unit = FightSnapshot.restore_unit(saved, game, 3)
		assert_eq(restored.copies, 1)
		assert_eq(restored.attack(), card.attack())
		assert_eq(restored.health(), card.health())
		assert_eq(
			JSON.stringify(RecordState.value(restored.mechanics)),
			JSON.stringify(RecordState.value(card.mechanics))
		)
		assert_eq(restored.slot, 3)


func test_snapshot_round_trip_keeps_dynamic_layers_and_grants() -> void:
	var game: GameSession = _content.new_session(2)
	var card: Unit = Unit.create(
		_content.library.get_card(&"hedge-knight"), 92, true, game.registry, game.config.stat_max
	)
	card.stats.perm_attack = 8
	card.stats.set_health = 0
	card.stats.renown = 4
	card.stats.aura_attack = 2
	card.counters["test"] = 3
	card.copies = 3
	card.bought_copies = 2
	assert_true(card.grant(game.registry, &"divine_shield"))
	assert_true(
		card.grant_effect(game.registry, &"play_buff", {"attack": 3, "health": 4, "to": "self"})
	)
	card.aura_mechanics.append(game.registry.bind_given(&"taunt", {}))
	var saved: Dictionary = CoreUtil.to_dict(
		JSON.parse_string(JSON.stringify(FightSnapshot.unit(card)))
	)
	var restored: Unit = FightSnapshot.restore_unit(saved, game)
	assert_eq(
		JSON.stringify(RecordState.value(restored.stats)),
		JSON.stringify(RecordState.value(card.stats))
	)
	assert_eq(
		JSON.stringify(RecordState.value(restored.counters)),
		JSON.stringify(RecordState.value(card.counters))
	)
	assert_eq(
		JSON.stringify(RecordState.value(restored.mechanics)),
		JSON.stringify(RecordState.value(card.mechanics))
	)
	assert_eq(
		JSON.stringify(RecordState.value(restored.aura_mechanics)),
		JSON.stringify(RecordState.value(card.aura_mechanics))
	)
	assert_eq(restored.bought_copies, card.bought_copies)
	assert_eq(restored.copies, card.copies)
	var encoded: String = JSON.stringify(saved)
	for forbidden: String in ["stat_max", "_kinds", "_golden_ints", "base_health", "set_attack"]:
		assert_false(encoded.contains(forbidden), "omit fixed/default %s" % forbidden)


func test_slot_renown_and_unit_counters_survive_the_fight_payload() -> void:
	var game: GameSession = _content.new_session(41)
	game.config.round_limit = 1
	game.keep_fight_events = false
	game.start_round()
	var player: PlayerState = game.player(0)
	player.slots[2].renown = 3
	player.slots[5].renown = 1
	var card: Unit = game.new_unit(_content.library.get_card(&"sentry"), false)
	player.place(card, 2)
	card.counters[&"test_count"] = 4
	card.counters[&"supply:pigeon_sentry"] = 3
	game.recruit.refresh_auras(player)
	game.finish_round()
	var saved: Dictionary = {}
	for entry: Dictionary in _entries(game.record.path):
		if entry.get("op") != "fight_boards":
			continue
		for raw: Variant in entry["players"]:
			var each: Dictionary = raw
			if CoreUtil.to_int(each["id"]) == player.id:
				saved = each
	assert_false(saved.is_empty(), "the payload was read back from disk")
	if saved.is_empty():
		return
	var slots: Array = saved["slots"]
	assert_eq(CoreUtil.to_int(slots[2]["renown"]), 4, "slots[].renown, the slot a unit stands in")
	assert_eq(CoreUtil.to_int(slots[5]["renown"]), 1, "an empty slot keeps its Renown")
	assert_eq(CoreUtil.to_int(slots[0]["renown"]), 0)
	var unit_saved: Dictionary = CoreUtil.to_dict(CoreUtil.to_array(saved["board"])[2])
	var counters_saved: Dictionary = RecordState.value(unit_saved["counters"])
	assert_eq(counters_saved, {"supply:pigeon_sentry": 2, "test_count": 4}, "counters are saved")
	assert_eq(CoreUtil.to_int(CoreUtil.to_dict(unit_saved["stats"])["renown"]), 4)
	var restored: Unit = FightSnapshot.restore_unit(unit_saved, game, 2)
	assert_eq(
		JSON.stringify(RecordState.value(restored.counters)),
		JSON.stringify({"supply:pigeon_sentry": 2, "test_count": 4}),
		"counters survive the round trip"
	)
	assert_eq(restored.stats.renown, 4, "so does the Renown its stats showed")
