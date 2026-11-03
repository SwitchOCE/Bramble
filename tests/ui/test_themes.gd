extends GutTest
## The look switch (Plain, Folk Print): every screen builds under each direction with no layout
## problems at desktop and phone sizes; switching rebuilds the screen and the game goes on; the
## choice is saved to user:// settings.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Directions := preload("res://src/ui/theme_directions.gd")
const Data := preload("res://src/ui/view_data.gd")

const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1688, 780)]
const SEED: int = 20261104
const MAX_TURNS: int = 60
const TEST_SETTINGS: String = "user://test_theme_settings.cfg"

var _root_size: Vector2i
var _settings_path: String


func before_each() -> void:
	_root_size = get_tree().root.size
	_settings_path = UiTheme.settings_path
	UiTheme.settings_path = TEST_SETTINGS


func after_each() -> void:
	get_tree().root.size = _root_size
	UiTheme.use(Directions.PLAIN, false)
	UiTheme.settings_path = _settings_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _app(human_bot: String = "") -> App:
	var config: GameConfig = GameConfig.defaults()
	if not human_bot.is_empty():
		config.set_value("human_bot", human_bot)
	var app: App = App.new()
	add_child_autofree(app)
	var port: CorePort = CorePort.new()
	port.setup(config)
	app.setup(port)
	return app


func _settle() -> void:
	for i: int in 3:
		await get_tree().process_frame


func _check(screen: Control, where: String, overlap: bool = true) -> void:
	await _settle()
	assert_eq(LayoutCheck.problems(screen, where, overlap), PackedStringArray(), where)


func test_every_screen_lays_out_under_each_look_at_both_sizes() -> void:
	for id: String in Directions.ORDER:
		for window: Vector2i in SIZES:
			UiTheme.use(id, false)
			get_tree().root.size = window
			var at: String = "%s %dx%d" % [id, window.x, window.y]
			var app: App = _app("greedy")
			await _check(app.current, at + " menu")
			app.show_sandbox()
			await _check(app.current, at + " sandbox")
			app.sandbox.show_tab("scenarios")
			await _check(app.current, at + " sandbox scenarios")
			app.start_game(SEED)
			(app.current as RecruitScreen).toggle_dev_panel()
			await _check(app.current, at + " recruit with dev panel")
			(app.current as RecruitScreen).toggle_dev_panel()
			await _check(app.current, at + " recruit")
			(app.current as RecruitScreen).call("_on_end_turn")
			assert_true(app.current is CombatScreen)
			await _check(app.current, at + " combat", false)
			var turns: int = 0
			while not app.current is GameOverScreen and turns < MAX_TURNS:
				if app.current is CombatScreen:
					(app.current as CombatScreen).finished.emit()
				elif app.current is RecruitScreen:
					(app.current as RecruitScreen).call("_on_end_turn")
				turns += 1
			assert_true(app.current is GameOverScreen, at + " reaches game over")
			await _check(app.current, at + " game over")
			app.queue_free()
			await get_tree().process_frame


func test_switching_mid_game_rebuilds_the_screen_and_the_game_goes_on() -> void:
	var app: App = _app()
	app.start_game(SEED)
	var before: RecruitScreen = app.current as RecruitScreen
	var state: Dictionary = app.port.get_state()
	app.set_look(Directions.FOLK_PRINT, false)
	assert_eq(UiTheme.direction, Directions.FOLK_PRINT)
	assert_true(app.current is RecruitScreen, "still recruiting")
	assert_ne(app.current, before, "the screen was rebuilt")
	assert_eq(app.port.get_state(), state, "the game state is untouched")
	assert_eq(app.theme, UiTheme.get_theme())
	var note: Label = app.current.find_child("FightNote", true, false)
	assert_true(note.visible, "Folk Print shows the next fight under End turn")
	assert_string_starts_with(note.text, "then fight ")
	app.set_look(Directions.PLAIN, false)
	note = app.current.find_child("FightNote", true, false)
	assert_false(note.visible, "Plain keeps today's End turn")


func test_the_menu_switch_saves_the_choice() -> void:
	var app: App = _app()
	assert_true(app.current is MainMenu)
	var option: Button = app.current.find_child("Look_" + Directions.FOLK_PRINT, true, false)
	option.pressed.emit()
	assert_eq(UiTheme.direction, Directions.FOLK_PRINT)
	assert_true(app.current is MainMenu, "the menu was rebuilt")
	assert_eq(UiTheme.saved_direction(), Directions.FOLK_PRINT, "saved to user:// settings")
	var pressed: Button = app.current.find_child("Look_" + Directions.FOLK_PRINT, true, false)
	assert_true(pressed.button_pressed, "the rebuilt switch shows the choice")


func test_fight_note_names_the_next_opponent() -> void:
	var state: Dictionary = {
		"next_opponent_id": 3,
		"standings":
		[{"player_id": 2, "name": "Bramblewick"}, {"player_id": 3, "name": "Old Tansy"}],
	}
	assert_eq(RecruitScreen.fight_note(state), "then fight Old Tansy")
	assert_eq(RecruitScreen.fight_note({"next_opponent_id": -1}), "then fight the ghost")
	assert_eq(RecruitScreen.fight_note({}), "")
