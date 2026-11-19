extends GutTest

# Seed 1002, seat 5, turns 1 to 4 from scripts/records.sh games=2 first_seed=1001.
const FIXTURE: String = "res://tests/core/fixtures/ghost_run.json"
const FIGHT_SEED: int = 41723

var _content: GameContent


func before_all() -> void:
	_content = GameContent.load_default()


func test_reads_run_and_hashes_the_exact_file_bytes() -> void:
	var run: GhostRun = _read_fixture()
	assert_eq(run.id, FileAccess.get_sha256(FIXTURE))
	assert_eq(run.last_turn, 4)
	assert_eq(run.turn_for_round(2), 2)
	assert_eq(run.reason_for_round(4), "same_turn")
	assert_eq(run.payload_for_round(1), CoreUtil.to_dict(_fixture()["turns"][0]["payload"]))
	assert_eq(run.turn_for_round(5), 4)
	assert_eq(run.reason_for_round(5), "run_ended")
	assert_eq(run.payload_for_round(5), run.payload_for_round(4))

	var text: String = FileAccess.get_file_as_string(FIXTURE) + "\n"
	var parsed: Dictionary = GhostRun.parse(text.to_utf8_buffer())
	assert_true(CoreUtil.to_bool(parsed["ok"]), str(parsed.get("message", "")))
	var changed: GhostRun = parsed["run"]
	assert_ne(changed.id, run.id, "Trailing whitespace changes the run id")
	assert_eq(changed.id, text.sha256_text())
	assert_eq(changed.payload_for_round(4), run.payload_for_round(4))


func test_refuses_a_missing_turn() -> void:
	var data: Dictionary = _fixture()
	var turns: Array = data["turns"]
	turns.remove_at(1)
	_assert_refused(_parse(data), "missing turn 2")


func test_refuses_uids_that_reach_the_seat_stride() -> void:
	var data: Dictionary = _fixture()
	data["turns"][3]["payload"]["board"][3]["uid"] = GhostRun.UID_STRIDE
	_assert_refused(_parse(data), "payload.board: unit uid 1000000 must be below 1000000")
	data = _fixture()
	data["turns"][3]["payload"]["hand"][0]["uid"] = GhostRun.UID_STRIDE
	_assert_refused(_parse(data), "payload.hand: unit uid 1000000 must be below 1000000")


func test_refuses_invalid_json_and_malformed_fields() -> void:
	_assert_refused(GhostRun.parse("{".to_utf8_buffer()), "invalid run JSON")
	var data: Dictionary = _fixture()
	data["format"] = 2
	_assert_refused(_parse(data), "expected run format 1")
	data = _fixture()
	data["source"]["game_seed"] = 1002
	_assert_refused(_parse(data), "source.game_seed")
	data = _fixture()
	data["turns"][0]["payload"]["slots"][0]["keywords"] = "pigeon_reserve"
	_assert_refused(_parse(data), "turn 1: payload.slots")
	data = _fixture()
	data["turns"][3]["payload"]["board"][3]["counters"]["supply:pigeon_sentry"] = true
	_assert_refused(_parse(data), "turn 4: payload.board: unit counters must be an integer")


func test_refuses_unknown_cards_when_a_library_is_given() -> void:
	var data: Dictionary = _fixture()
	data["turns"][3]["payload"]["board"][3]["def"] = "missing-from-library"
	var cards: Dictionary = data["cards"]
	cards["missing-from-library"] = cards["sentry"]
	cards.erase("sentry")
	_assert_refused(_parse(data), "unknown card 'missing-from-library'")
	assert_true(CoreUtil.to_bool(GhostRun.parse(JSON.stringify(data).to_utf8_buffer())["ok"]))

	data = _fixture()
	data["turns"][0]["payload"]["heaps"]["thorn_compost"]["entries"][0]["id"] = "missing-heap-card"
	_assert_refused(_parse(data), "payload.heaps.thorn_compost: unknown card 'missing-heap-card'")


func test_restores_the_same_run_into_any_seat_and_replaces_its_fight_state() -> void:
	var run: GhostRun = _read_fixture()
	var payload: Dictionary = run.payload_for_round(4)
	for seat: int in range(8):
		var game: GameSession = _content.new_session(1002)
		var player: PlayerState = game.player(seat)
		var offset: int = seat * GhostRun.UID_STRIDE
		player.place(game.new_unit(_content.library.get_card(&"sentry"), false), 0)
		player.hand.append(game.new_unit(_content.library.get_card(&"sentry"), false))
		player.health = 19
		player.slots[3].keywords.append(&"pigeon_reserve")
		player.counters["old"] = 3
		player.heap(&"old").add(&"sentry", 1)
		FightSnapshot.restore_player(payload, player, game, offset)
		var expected: Dictionary = payload.duplicate(true)
		expected["id"] = seat
		expected["board"][3]["uid"] = 63 + offset
		expected["hand"][0]["uid"] = 50 + offset
		assert_eq(player.health, 19)
		assert_eq(player.board[3].slot, 3)
		assert_eq(game._next_uid, 64 if offset == 0 else 3)
		assert_eq(
			CoreUtil.to_dict(RecordState.fight_players(game)[seat]),
			CoreUtil.to_dict(RecordState.value(expected))
		)

		FightSnapshot.restore_player(run.payload_for_round(1), player, game, offset)
		assert_eq(player.board_count(), 0)
		assert_eq(player.hand.size(), 0)
		assert_eq(player.slots[3].renown, 0)
		assert_eq(player.heap(&"thorn_compost").size(), 2)
	assert_eq(payload, run.payload_for_round(4))


func test_fixed_seed_fight_is_independent_of_the_destination_seat() -> void:
	var run: GhostRun = _read_fixture()
	var from_two: Dictionary = _fight_in_seat(run, 2)
	var from_five: Dictionary = _fight_in_seat(run, 5)
	assert_gt(CoreUtil.to_int(from_two["attacks"]), 0, "Both sides actually fight")
	assert_eq(CoreUtil.to_array(from_two["survivor_recruit_uids"]), [[2_000_063], []])
	assert_eq(CoreUtil.to_array(from_five["survivor_recruit_uids"]), [[5_000_063], []])
	from_two.erase("survivor_recruit_uids")
	from_five.erase("survivor_recruit_uids")
	assert_eq(from_two, from_five)


func _fight_in_seat(run: GhostRun, seat: int) -> Dictionary:
	var game: GameSession = _content.new_session(1002)
	var ghost: PlayerState = game.player(seat)
	var opponent: PlayerState = game.player(0)
	opponent.place(game.new_unit(_content.library.get_card(&"hopper"), false), 3)
	opponent.place(game.new_unit(_content.library.get_card(&"hopper"), false), 4)
	FightSnapshot.restore_player(run.payload_for_round(4), ghost, game, seat * GhostRun.UID_STRIDE)
	var combat: Combat = Combat.create(
		game.geometry, game.config, game.registry, game.library, FIGHT_SEED
	)
	return combat.run(
		[ghost.board, opponent.board],
		[seat, opponent.id],
		[ghost, opponent],
		[false, true],
		[ghost.hand, opponent.hand]
	)


func _read_fixture() -> GhostRun:
	var result: Dictionary = GhostRun.read(FIXTURE, _content.library, _content.registry)
	assert_true(CoreUtil.to_bool(result["ok"]), str(result.get("message", "")))
	return result.get("run")


func _fixture() -> Dictionary:
	return CoreUtil.to_dict(JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)))


func _parse(data: Dictionary) -> Dictionary:
	return GhostRun.parse(
		JSON.stringify(data).to_utf8_buffer(), _content.library, _content.registry
	)


func _assert_refused(result: Dictionary, reason: String) -> void:
	assert_false(CoreUtil.to_bool(result["ok"]))
	assert_string_contains(str(result.get("message", "")), reason)
