extends SceneTree
## Editor probe with --main-pack pointing at an exported PCK. This file is not shipped: every
## res:// preload and scene comes from the pack. Stock templates disallow --script overrides.

const App := preload("res://src/ui/app.gd")
const CorePort := preload("res://src/ui/adapter/core_port.gd")
const Settings := preload("res://src/ui/settings.gd")
const Records := preload("res://src/ui/records.gd")
const Sfx := preload("res://src/ui/sfx.gd")


func _initialize() -> void:
	Settings.path = "user://export_smoke_field_settings.cfg"
	Records.path = "user://export_smoke_field_records.cfg"
	Settings.reset()
	# Exercise disabled-field behavior even in an opt-in dry-run pack. Ordinary
	# feature-off presets already initialize this to false.
	Settings.field_mode_enabled = false
	@warning_ignore("missing_await")
	_run()


func _run() -> void:
	await process_frame
	if not _valid_template():
		quit(1)
		return
	var scene: PackedScene = load("res://src/main/main.tscn")
	var main: Node = scene.instantiate()
	root.add_child(main)
	# This probe checks opponent settings, not audio playback. Avoid starting a
	# discover voice immediately before headless teardown.
	Sfx._instance = null
	var app: App = main.get("app")
	var port: CorePort = app.port as CorePort
	var screen := app.open_settings()
	if not screen.opponent_buttons.is_empty():
		_fail("Strong field UI choice is present with the feature off", main)
		return
	if port.config.get_string("opponents") != "bots":
		_fail("feature-off default opponents are not Bots", main)
		return
	# An old saved preference must still use Bots when the feature is off.
	Settings.opponents = "field"
	Settings.save()
	app.start_game(5)
	if port.session == null or port.config.get_string("opponents") != "bots":
		_fail("saved field preference did not fall back to Bots", main)
		return
	if port.session._field != null or port.config.get_string("field_library") != "":
		_fail("field configuration leaked into the Bots game", main)
		return
	if port.choose(0) != "" or port.end_turn() != "":
		_fail("exported Bots game could not play its first round", main)
		return
	print("export-field-smoke: feature off; Strong field choice absent; saved preference uses Bots")
	root.remove_child(main)
	main.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	quit(0)


func _valid_template() -> bool:
	var validator := FieldLibrary.new()
	var manifest: Dictionary = validator._content_manifest()
	if validator.error != "" or manifest.is_empty():
		printerr("export-field-smoke: FAILED gameplay validation unavailable: %s" % validator.error)
		return false
	print("export-field-smoke: gameplay validation available in player pack")
	if not FileAccess.file_exists(FieldLibrary.BUNDLED_PATH):
		printerr("export-field-smoke: FAILED player export lacks the field library")
		return false
	return true


func _fail(problem: String, main: Node) -> void:
	printerr("export-field-smoke: FAILED %s" % problem)
	root.remove_child(main)
	main.queue_free()
	quit(1)
