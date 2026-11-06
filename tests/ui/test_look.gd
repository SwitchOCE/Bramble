extends GutTest
## One look, the settings and records that save, the first-run guide, and the layout check itself:
## it must fail on text under the phone minimum and on tap targets too small for a finger.
@warning_ignore_start("unsafe_call_argument")

const App := preload("res://src/ui/app.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const Settings := preload("res://src/ui/settings.gd")
const Records := preload("res://src/ui/records.gd")
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CardPicker := preload("res://src/ui/widgets/card_picker.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const SlotView := preload("res://src/ui/widgets/slot_view.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")
const SettingsScreen := preload("res://src/ui/screens/settings_screen.gd")


func before_each() -> void:
	Settings.path = "user://test_settings.cfg"
	Records.path = "user://test_look_records.cfg"
	DirAccess.remove_absolute(Settings.path)
	DirAccess.remove_absolute(Records.path)
	Settings.reset()


func after_all() -> void:
	Settings.reset()


func test_the_phone_minimum_is_worked_out_from_the_phone() -> void:
	assert_eq(LayoutCheck.min_font(), 31)
	assert_eq(UiTheme.MIN_FONT, LayoutCheck.min_font())
	assert_eq(LayoutCheck.min_tap(Vector2(2337, 1080)), 122.0)
	assert_eq(LayoutCheck.min_tap(Vector2(1920, 1080)), 88.0)


func test_layout_check_fails_small_text_and_small_tap_targets() -> void:
	var root: Control = Control.new()
	root.size = Vector2(1000, 800)
	add_child_autofree(root)
	var small: Label = Label.new()
	small.text = "tiny"
	small.add_theme_font_size_override("font_size", 20)
	small.size = Vector2(200, 60)
	root.add_child(small)
	var button: Button = Button.new()
	button.text = "ok"
	button.add_theme_font_size_override("font_size", 40)
	button.position = Vector2(0, 100)
	button.size = Vector2(60, 60)
	root.add_child(button)
	var problems: String = "\n".join(LayoutCheck.problems(root, "test"))
	assert_string_contains(problems, "text 20 under the minimum 31")
	assert_string_contains(problems, "tap target 60 under the minimum")


func test_settings_save_and_load() -> void:
	Settings.fight_speed = 4.0
	Settings.volume = 35
	Settings.reduce_motion = true
	Settings.show_dev_panel = true
	Settings.save()
	Settings.reset()
	Settings.load_saved()
	assert_eq(Settings.fight_speed, 4.0)
	assert_eq(Settings.volume, 35)
	assert_true(Settings.reduce_motion)
	assert_true(Settings.show_dev_panel)


func test_settings_screen_changes_save_straight_away() -> void:
	var screen: SettingsScreen = SettingsScreen.new()
	add_child_autofree(screen)
	screen.speed_tokens[1].pressed.emit()
	screen.dev_latch.button_pressed = true
	Settings.reset()
	Settings.load_saved()
	assert_eq(Settings.fight_speed, 2.0)
	assert_true(Settings.show_dev_panel)


func test_records_keep_the_best_per_difficulty() -> void:
	assert_eq(Records.summary("easy"), "Not played yet")
	assert_true(Records.add_game("easy", 5))
	assert_false(Records.add_game("easy", 6))
	assert_true(Records.add_game("easy", 1))
	assert_eq(Records.best_placement("easy"), 1)
	assert_eq(Records.wins("easy"), 1)
	assert_eq(Records.games("easy"), 3)
	assert_eq(Records.best_placement("hard"), 0)


func test_dev_panel_is_hidden_until_the_setting_is_on() -> void:
	var port: FixturePort = FixturePort.new()
	port.new_game(1)
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var token: Control = screen.get("_dev_token")
	assert_false(token.visible)
	Settings.show_dev_panel = true
	screen.refresh_settings()
	assert_true(token.visible)


func test_sandbox_leaf_follows_the_dev_setting() -> void:
	var menu: MainMenu = MainMenu.new()
	add_child_autofree(menu)
	var words: Array = []
	for child: Node in menu.get_children():
		if child is Button:
			words.append((child as Button).text)
	assert_false(words.has("Sandbox"))
	assert_true(words.has("New game"))
	assert_true(words.has("How to play"))


func test_first_new_game_opens_the_guide_then_starts() -> void:
	var app: App = App.new()
	add_child_autofree(app)
	var port: FixturePort = FixturePort.new()
	app.setup(port)
	app.choose_difficulty("hard")
	assert_eq(app.difficulty, "hard")
	assert_true(app.current is MainMenu, "the guide comes first")
	var guide: HowToPlay = null
	for child: Node in app.get_children():
		if child is HowToPlay:
			guide = child
	assert_not_null(guide)
	guide.call("_close")
	assert_true(app.current is RecruitScreen, "closing the guide starts the game")
	assert_true(Settings.seen_guide)


func test_the_guide_has_pages_and_goes_through_them() -> void:
	var guide: HowToPlay = HowToPlay.new()
	add_child_autofree(guide)
	var closed: Array = []
	guide.closed.connect(func() -> void: closed.append(true))
	for i: int in HowToPlay.PAGES.size():
		assert_eq(guide.page, i)
		guide.call("_go", 1)
	assert_eq(closed.size(), 1)


func test_spell_cards_are_a_different_shape_and_discover_must_be_answered() -> void:
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_heroes.json")
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var shop: Control = screen.get("_shop_cards")
	assert_true(CardView.is_spell((shop.get_child(2) as CardView).unit))
	var picker: CardPicker = screen.get("_discover")
	assert_not_null(picker)
	assert_eq(picker.cards.size(), 3)
	var back: Control = picker.get("_back")
	assert_false(back.visible, "no way out but choosing")


func test_empty_slots_say_where_they_sit() -> void:
	assert_eq(SlotView.note(3), "in front of B3")
	assert_eq(SlotView.note(1), "ahead of B1 & B2")
	assert_eq(SlotView.note(6), "behind F3 & F4")
