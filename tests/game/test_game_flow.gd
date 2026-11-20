extends GutTest
## Build the field from this build's records, so the tests also catch a rules-version mismatch.

@warning_ignore_start("unsafe_call_argument")

var _content: GameContent
var _store: LayeredGhostStore


func before_all() -> void:
	_content = GameContent.load_default()
	_store = FlowFixture.test_store()


func test_stand_in_content_loads_clean() -> void:
	var stand_in: GameContent = GameContent.load_folders(["res://src/content/shared"])
	assert_eq(stand_in.errors, PackedStringArray(), "no load errors")
	assert_gt(stand_in.library.drawable_cards(false).size(), 10, "units to buy")
	assert_eq(stand_in.art_for("t1_plain"), "hedgehog-1", "stand-in art name")


func test_a_whole_ghost_game_ends_saves_the_player_and_replays() -> void:
	var flow: GameFlow = _matched(7)
	assert_eq(flow.session.runs.size(), 7)
	assert_false(flow.session.runs.has(GameFlow.HUMAN))
	assert_eq(flow.content.tribes.size(), 5)
	assert_eq(flow.session.record_recipe["tribes"], [], "all tribes")
	var driver := SimpleBot.new(Rng.derive(7, "human"))
	var fights_seen: int = 0
	while not flow.is_over() and flow.human_alive():
		flow.start_round()
		driver.take_turn(flow.session, GameFlow.HUMAN)
		var fight: Dictionary = flow.finish_round()
		assert_false(fight.is_empty(), "the living player fought")
		fights_seen += 1
	flow.play_out()
	assert_true(flow.is_over())
	assert_eq(driver.refused, 0)
	assert_gt(fights_seen, 2)
	var places: Array = []
	for row: Dictionary in flow.standings():
		places.append(row["place"])
	assert_eq(places, [1, 2, 3, 4, 5, 6, 7, 8])

	var id: String = flow.save_player_run()
	assert_ne(id, "")
	var saved: Dictionary = GhostStore.new(_store.directory).fetch(id)
	assert_true(saved["ok"], str(saved.get("message", "")))
	var info: Dictionary = saved["info"]
	assert_eq(info["kind"], "player")
	assert_eq(info["placement"], flow.human().placement)
	assert_eq(info["last_turn"], fights_seen)
	var replay: Dictionary = RecordReplay.read(flow.session.record.path, _store)
	assert_true(replay["ok"], str(replay.get("message", "")))
	assert_true(replay["complete"])
	assert_eq(replay["checkpoints"], flow.session.round_number * 3)
	assert_eq(RecordState.state_hash(replay["session"]), RecordState.state_hash(flow.session))


func test_match_excludes_seen_runs_and_never_picks_players() -> void:
	var first: GameFlow = _matched(13)
	var seen: Dictionary = {}
	for id: String in first.session.run_ids.slice(1):
		seen[id] = true
	var second: Dictionary = GameFlow.create(_content, 13, _store, seen)
	assert_true(second["ok"], str(second.get("message", "")))
	var flow: GameFlow = second["flow"]
	for id: String in flow.session.run_ids.slice(1):
		assert_false(seen.has(id), "a run can only be picked once in an app session")
		var found: Dictionary = _store.fetch(id)
		assert_eq(found["info"]["kind"], "bot")
		seen[id] = true
	assert_eq(seen.size(), 14)
	var exhausted: Dictionary = GameFlow.create(_content, 13, _store, seen)
	assert_false(exhausted["ok"])
	assert_string_contains(exhausted["message"], "found 0")


func test_an_empty_field_refuses_the_game() -> void:
	var root: String = FlowFixture.new_root()
	var store := LayeredGhostStore.new(root.path_join("player"), root.path_join("empty"))
	var result: Dictionary = GameFlow.create(_content, 13, store)
	assert_false(result["ok"])
	assert_string_contains(result["message"], "need 7 eligible ghost runs, found 0")


func test_run_seats_skip_recruit_and_fight_on_their_recorded_board() -> void:
	var flow: GameFlow = _matched(11)
	flow.start_round()
	assert_ne(flow.act({"type": "upgrade"}), "", "turn 1 cannot afford an upgrade")
	var seat: int = flow.session.opponent_of(GameFlow.HUMAN)
	var opponent: PlayerState = flow.session.player(seat)
	var run: GhostRun = flow.session.runs[seat]
	assert_true(opponent.turn_ended)
	assert_eq(opponent.board_count(), 0, "the core will load the board at combat")
	var recruit: Dictionary = ViewAdapter.recruit_state(flow)
	assert_eq(recruit["next_opponent"]["name"], flow.name_of(seat))
	assert_eq(recruit["next_opponent"]["health"], opponent.health)
	var next: Dictionary = recruit["next_opponent"]
	assert_false(next.has("board"))
	flow.act({"type": "end_turn"})
	var fight: Dictionary = flow.finish_round()
	var before: Dictionary = fight["before"]["opponent"]
	var recorded: Array = run.payload_for_round(1)["board"]
	var loaded: Array = before["board"]
	assert_true(loaded.any(func(card: Variant) -> bool: return card != null))
	for slot: int in recorded.size():
		var card: Variant = recorded[slot]
		if card == null:
			assert_null(loaded[slot])
		else:
			assert_eq(loaded[slot]["id"], card["def"])
			var uid: int = CoreUtil.to_int(card["uid"]) + seat * GhostRun.UID_STRIDE
			assert_eq(CoreUtil.to_int(loaded[slot]["uid"]), uid)


func _matched(seed_value: int) -> GameFlow:
	var made: Dictionary = GameFlow.create(_content, seed_value, _store)
	assert_true(made["ok"], str(made.get("message", "")))
	return made["flow"]
