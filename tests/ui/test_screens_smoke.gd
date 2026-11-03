extends GutTest
## Every screen loads and renders a fixture state without errors, and the app moves between
## them: menu -> recruit -> combat -> recruit -> combat -> game over, and sandbox -> fight.

const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const App := preload("res://src/ui/app.gd")
const MainScene: PackedScene = preload("res://src/main/main.tscn")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")


func _app() -> App:
	var app: App = App.new()
	add_child_autofree(app)
	app.setup(FixturePort.new())
	return app


func _cards_in(node: Node, zone: String) -> int:
	var count: int = 0
	for child: Node in node.find_children("*", "", true, false):
		if (
			child is CardView
			and (child as CardView).zone == zone
			and not child.is_queued_for_deletion()
		):
			count += 1
	return count


func test_main_scene_opens_the_menu() -> void:
	var main: Control = MainScene.instantiate() as Control
	add_child_autofree(main)
	var title: Label = main.find_child("Title", true, false) as Label
	assert_not_null(title, "menu title exists")
	assert_eq(title.text, "Bramble")


func test_menu_has_play_sandbox_quit() -> void:
	var app: App = _app()
	assert_true(app.current is MainMenu)
	for button_name: String in ["Play", "Sandbox", "Quit"]:
		assert_not_null(app.current.find_child(button_name, true, false), button_name)


func test_recruit_renders_round7_fixture() -> void:
	var app: App = _app()
	app.start_game()
	var port: FixturePort = app.port as FixturePort
	port.use_state("recruit_round7")
	app.show_recruit()
	await wait_process_frames(2)
	assert_true(app.current is RecruitScreen)
	assert_eq(_cards_in(app.current, "shop"), 5, "5 shop cards")
	assert_eq(_cards_in(app.current, "board"), 6, "6 board units")
	assert_eq(_cards_in(app.current, "hand"), 2, "2 hand cards")


func test_recruit_tap_select_and_refused_action_shows_reason() -> void:
	var app: App = _app()
	app.start_game()
	var screen: RecruitScreen = app.current as RecruitScreen
	screen.call("_on_tapped", "shop", 0)
	var selected: Dictionary = screen.get("_selected")
	var zone: String = selected.get("zone", "")
	assert_eq(zone, "shop", "tap selects the shop card")
	screen.call("_on_buy_selected")
	var toast: Label = screen.get("_toast")
	assert_string_contains(toast.text, "Fixture mode")


func test_end_turn_plays_combat_then_next_recruit_then_game_over() -> void:
	var app: App = _app()
	app.start_game()
	(app.current as RecruitScreen).call("_on_end_turn")
	assert_true(app.current is CombatScreen, "end turn shows the fight")
	var combat: CombatScreen = app.current as CombatScreen
	combat.skip_to_end()
	assert_true(combat.is_showing_result(), "result shown after skip")
	assert_eq(_cards_in(combat, "combat"), 1, "only Belladonna Sprite survives")
	combat.finished.emit()
	assert_true(app.current is RecruitScreen, "back to recruit")
	(app.current as RecruitScreen).call("_on_end_turn")
	(app.current as CombatScreen).finished.emit()
	assert_true(app.current is GameOverScreen, "game over after the last state")


func test_combat_plays_back_over_time() -> void:
	var app: App = _app()
	app.start_game()
	(app.current as RecruitScreen).call("_on_end_turn")
	var combat: CombatScreen = app.current as CombatScreen
	combat.set_speed(4.0)
	await wait_seconds(1.5)
	assert_gt(combat.next_index, 3, "events advance while playing")
	combat.toggle_play()
	var paused_at: int = combat.next_index
	await wait_seconds(0.5)
	assert_eq(combat.next_index, paused_at, "paused playback holds")


func test_combat_handles_every_event_type() -> void:
	var screen: CombatScreen = CombatScreen.new()
	add_child_autofree(screen)
	var data: Dictionary = FixturePort.load_json("res://tests/ui/data/combat_all_events.json")
	screen.setup(data, PackedStringArray(["You", "Bot 2"]), 0, "test")
	screen.skip_to_end()
	assert_true(screen.is_showing_result())
	assert_eq(screen.model.winner, 1)


func test_sandbox_places_and_fights() -> void:
	var app: App = _app()
	app.show_sandbox()
	var sandbox: SandboxScreen = app.sandbox
	assert_gt(_cards_in(sandbox, "library"), 30, "library shows the units")
	sandbox.place(0, 1, "hoglet_mother", false)
	sandbox.place(1, 1, "stoat_captain", true)
	assert_eq(_cards_in(sandbox, "own"), 1)
	assert_eq(_cards_in(sandbox, "enemy"), 1)
	sandbox.call("_on_fight")
	assert_true(app.current is CombatScreen, "fight shows the combat screen")
	(app.current as CombatScreen).finished.emit()
	assert_same(app.current, sandbox, "back to the same sandbox")
	assert_eq(_cards_in(sandbox, "own"), 1, "boards kept")


func test_game_over_lists_standings() -> void:
	var app: App = _app()
	(app.port as FixturePort).use_state("recruit_game_over")
	app.show_game_over()
	assert_true(app.current is GameOverScreen)
	var placement: Label = app.current.get("_placement")
	assert_eq(placement.text, "3rd place")


func test_brick_back_slots_sit_between_front_slots() -> void:
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	board.configure("board", 100.0, true, 20.0)
	for back: int in 3:
		var left: Vector2 = board.slot_position(back)
		var right: Vector2 = board.slot_position(back + 1)
		var behind: Vector2 = board.slot_position(4 + back)
		assert_almost_eq(behind.x, (left.x + right.x) / 2.0, 0.01, "B%d centred" % (back + 1))
		assert_gt(behind.y, left.y, "back row below the front row")
