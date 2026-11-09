extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")

const FieldTestData := preload("res://tests/core/field_test_data.gd")
const Settings := preload("res://src/ui/settings.gd")
const SettingsScreen := preload("res://src/ui/screens/settings_screen.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")

var _old_path: String
var _old_opponents: String
var _old_enabled: bool
var _old_library_path: String


func before_each() -> void:
	_old_path = Settings.path
	_old_opponents = Settings.opponents
	_old_enabled = Settings.field_mode_enabled
	_old_library_path = Settings.field_library_path
	Settings.path = "user://test_field_settings.cfg"
	Settings.opponents = "bots"
	Settings.field_mode_enabled = true
	Settings.field_library_path = FieldTestData.path()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = _old_path
	Settings.opponents = _old_opponents
	Settings.field_mode_enabled = _old_enabled
	Settings.field_library_path = _old_library_path


func test_opponent_choice_buttons_persist_and_are_touch_sized() -> void:
	var screen := SettingsScreen.new()
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(1920, 1080)
	add_child_autofree(screen)
	screen.call("_layout")
	assert_eq(screen.opponent_buttons[0].text, "Bots")
	assert_eq(screen.opponent_buttons[1].text, "Strong field")
	for button: Button in screen.opponent_buttons:
		assert_gte(button.size.y, 122.0)
		assert_gte(button.size.x, 300.0)
	screen.opponent_buttons[1].pressed.emit()
	Settings.opponents = "bots"
	Settings.load_saved()
	assert_eq(Settings.opponents, "field")
	screen.opponent_buttons[0].pressed.emit()
	Settings.opponents = "field"
	Settings.load_saved()
	assert_eq(Settings.opponents, "bots")


func test_settings_choice_starts_field_through_app_and_core_port_then_restores_bots() -> void:
	var port := CorePort.new()
	port.setup()
	var app := App.new()
	add_child_autofree(app)
	app.setup(port)
	var settings := app.open_settings()
	settings.opponent_buttons[1].pressed.emit()
	app.start_game(5)
	assert_not_null(port.session)
	assert_true(app.current is RecruitScreen)
	if port.session == null:
		return
	assert_eq(port.config.get_string("opponents"), "field")
	assert_eq(port.config.get_string("field_strength"), "top4")
	assert_eq(port.config.get_string("field_library"), Settings.field_library_path)
	assert_not_null(port.session._field)
	assert_eq(port.choose(0), "")
	assert_eq(port.end_turn(), "")
	port.config.set_value("starting_health", 999)
	settings.opponent_buttons[0].pressed.emit()
	app.start_game(5)
	assert_not_null(port.session)
	assert_eq(port.config.get_string("opponents"), "bots")
	assert_eq(port.config.get_string("field_library"), "")
	assert_eq(port.config.get_int("starting_health"), GameConfig.SLICE_HEALTH)
	assert_null(port.session._field)


func test_explicit_config_is_not_overridden_by_saved_field_choice() -> void:
	Settings.opponents = "field"
	var config := GameConfig.defaults()
	config.set_value("starting_health", 17)
	var port := CorePort.new()
	port.setup(config)
	assert_eq(port.new_game(5), "")
	assert_eq(port.get_state()["health"], 17)
	assert_null(port.session._field)


func test_invalid_saved_opponent_value_defaults_to_bots() -> void:
	var file := ConfigFile.new()
	file.set_value("game", "opponents", "unknown")
	file.save(Settings.path)
	Settings.opponents = "field"
	Settings.load_saved()
	assert_eq(Settings.opponents, "bots")


func test_feature_off_hides_choice_and_ignores_a_saved_field_preference() -> void:
	Settings.field_mode_enabled = false
	Settings.opponents = "field"
	var screen := SettingsScreen.new()
	add_child_autofree(screen)
	assert_true(screen.opponent_buttons.is_empty())
	var tray: Control = screen.get("_tray")
	assert_false(tray.visible)
	var port := CorePort.new()
	port.setup()
	assert_eq(port.new_game(5), "")
	assert_eq(port.config.get_string("opponents"), "bots")
	assert_eq(port.config.get_string("field_library"), "")
	assert_null(port.session._field)
