extends GutTest
@warning_ignore_start("unsafe_call_argument")

const Events := preload("res://src/core/combat/combat_events.gd")
const App := preload("res://src/ui/app.gd")
const Model := preload("res://src/ui/screens/combat_model.gd")
const Over := preload("res://src/ui/screens/game_over_screen.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const Screen := preload("res://src/ui/screens/combat_screen.gd")
const Recruit := preload("res://src/ui/screens/recruit_screen.gd")
const CK := preload("res://tests/core/combat_kit.gd")


func _fight() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var combat := Combat.create(CK.library, GameConfig.full_game(), rng)
	var fight: Dictionary = combat.run(
		[CK.board({0: CK.plain(1, 1)}), CK.board({0: CK.plain(20, 20)})], [1, 1], [7, 0], 0
	)
	var events: Array = fight["events"]
	# A legacy setup event even carries misleading ids: only combat_start is authoritative.
	events.push_front(
		{"type": "status", "target": 999, "status": "lent_swoop", "on": true, "player_ids": [0, 9]}
	)
	fight["round"] = 1
	fight["opponent_id"] = 7
	return fight


func test_prefixed_fight_keeps_human_on_side_one_in_app_model_board_and_play_readers() -> void:
	var fight: Dictionary = _fight()
	var events: Array = fight["events"]
	var start: Dictionary = Events.start(events)
	assert_eq(App.player_side(start, 0), 1)
	var state: Dictionary = {
		"player_id": 0,
		"board": [],
		"standings": [{"player_id": 7, "name": "Hob"}, {"player_id": 0, "is_human": true}],
	}
	assert_eq(App.side_names(start, state), PackedStringArray(["Hob", "You"]))
	var boards: Array = start["boards"]
	assert_eq(Over.final_board(state, fight), boards[1])
	var model := Model.new()
	for event: Dictionary in events:
		model.apply(event)
	assert_eq(model.player_ids, [7, 0])
	var lines: PackedStringArray = []
	PlayView.fight_lines(fight, state, lines)
	assert_string_contains(lines[0], "You won")
	var game: PlayGame = PlayGame.start(11)
	var summary: Dictionary = PlayTurns.fight_summary(game, fight)
	assert_eq(summary["result"], "win")


func test_missing_human_identity_is_unknown_instead_of_side_zero() -> void:
	assert_eq(Events.start([{"type": "status", "player_ids": [0, 7]}]), {})
	assert_eq(App.player_side({}, 0), -1)
	assert_eq(App.player_side({"player_ids": [7, 8]}, 0), -1)
	assert_eq(App.player_side({"player_ids": ["unknown", 7]}, 0), -1)


func test_app_shows_actual_human_side_after_prefixed_event() -> void:
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	port._last_combat = _fight()
	var app := App.new()
	add_child_autofree(app)
	app.setup(port)
	app.show_game_combat()
	var screen: Screen = app.current as Screen
	assert_not_null(screen)
	assert_eq(screen.bottom_side, 1)


func test_app_refreshes_recruit_when_combat_is_missing_the_player() -> void:
	var port := FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	port._last_combat = _fight()
	var events: Array = port._last_combat["events"]
	Events.start(events)["player_ids"] = [7, 8]
	var app := App.new()
	add_child_autofree(app)
	app.setup(port)
	app.show_recruit()
	var stale: Control = app.current
	port._state["gold"] = 9
	app.show_game_combat()
	assert_push_error("Cannot show a fight without the player")
	assert_true(stale.is_queued_for_deletion(), "the previous recruit screen is replaced")
	var recruit: Recruit = app.current as Recruit
	assert_not_null(recruit)
	assert_eq(CoreUtil.to_int(recruit.state["gold"]), 9, "recruit shows the latest core state")
	assert_engine_error_count(0)
	await wait_process_frames(1)


func test_core_port_exposes_ids_from_real_start_after_a_prefixed_event() -> void:
	var port := CorePort.new()
	port.setup(GameConfig.full_game())
	port.new_game(11)
	port.choose(0)
	port.end_turn()
	var fight: Dictionary = port.session.get_last_combat()
	var events: Array = fight["events"]
	var ids: Array = Events.start(events)["player_ids"]
	events.push_front({"type": "status", "target": 999, "status": "lent_swoop", "on": true})
	assert_eq(port.get_last_combat()["player_ids"], ids)
