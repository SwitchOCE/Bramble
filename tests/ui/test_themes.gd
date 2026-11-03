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
const CardView := preload("res://src/ui/widgets/card_view.gd")
const ShapeBadge := preload("res://src/ui/widgets/shape_badge.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")

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


## Plain must look exactly as it did before looks became data: the card's badges keep the
## pre-theme fills, rings and 3 px inset outline at every size (scope review, 4 Nov).
func test_plain_card_badges_match_the_pre_theme_look() -> void:
	UiTheme.use(Directions.PLAIN, false)
	var port: CorePort = CorePort.new()
	port.setup()
	var view: Dictionary = UnitViews.from_def(port.library.get_unit("still_water_heron"))
	view["cost"] = 3
	# Pre-theme values: [fill, ring] of each round badge, ring 3 px drawn inside the box.
	var before: Dictionary = {
		"_tier_badge": [Color("1d1d1b"), Color("f2c14e")],
		"_cost_badge": [Color("f2c14e"), Color("1d1d1b")],
		"_attack_badge": [Color("f2b53c"), Color("1d1d1b")],
		"_health_badge": [Color("d9443a"), Color("1d1d1b")],
	}
	for width: float in [96.0, 168.0, 280.0]:
		var card: CardView = CardView.new()
		add_child_autofree(card)
		card.show_unit(view, CardView.Mode.FULL)
		card.set_card_width(width)
		for key: String in before:
			var badge: ShapeBadge = card.get(key)
			var where: String = "%s at %d px" % [key, int(width)]
			var colours: Array = before[key]
			var fill: Color = colours[0]
			var ring: Color = colours[1]
			var face: StyleBoxFlat = badge.circle_box()
			assert_eq(badge.shape, "circle", where)
			assert_eq(face.bg_color, fill, where + " fill")
			assert_eq(face.border_color, ring, where + " ring")
			assert_eq(face.border_width_left, 3, where + " ring width")
			assert_eq(face.corner_radius_top_left, 999, where)
		var ribbon: Control = card.get("_ribbon")
		assert_false(ribbon.visible, "no name ribbon in Plain")
		var window: Panel = card.get("_window")
		assert_eq(window.clip_children, CanvasItem.CLIP_CHILDREN_DISABLED, "no arch clip in Plain")
	assert_true(UiTheme.HEALTH_TEXT.is_equal_approx(Color("d9443a").lightened(0.35)))


func test_the_font_licences_ship_in_every_export_preset() -> void:
	var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	var filters: int = presets.count('include_filter="')
	assert_gt(filters, 0)
	assert_eq(presets.count("assets/fonts/*.txt"), filters, "every preset")
