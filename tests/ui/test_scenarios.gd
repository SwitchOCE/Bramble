extends GutTest
## The sandbox's Scenarios tab: the list shows each scene's title, library entry, units, watch
## line and note; Load fills both boards through CombatSandbox.load_scenario (overrides and
## display names included); Fight plays it at the scenario's seed under its title.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CombatModel := preload("res://src/ui/screens/combat_model.gd")
const CombatLog := preload("res://src/ui/screens/combat_log.gd")
const Data := preload("res://src/ui/view_data.gd")


func _app() -> App:
	var app: App = App.new()
	add_child_autofree(app)
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)
	app.show_sandbox()
	return app


func _all_text(node: Node) -> String:
	var parts: PackedStringArray = []
	for label: Node in node.find_children("*", "Label", true, false):
		parts.append((label as Label).text)
	return "\n".join(parts)


func test_the_list_shows_every_scenario_with_its_watch_line() -> void:
	var app: App = _app()
	var sandbox: SandboxScreen = app.sandbox
	sandbox.show_tab("Scenarios")
	var scenarios: Array[Dictionary] = app.port.scenarios()
	assert_gt(scenarios.size(), 5, "the core's scenarios")
	var list: VBoxContainer = sandbox.get("_scenario_list")
	assert_eq(list.get_child_count(), scenarios.size())
	var text: String = _all_text(list)
	for scenario: Dictionary in scenarios:
		assert_string_contains(text, Data.s(scenario, "title"))
		assert_string_contains(text, "Watch: " + Data.s(scenario, "watch"))
		assert_string_contains(text, "Library entry %d" % Data.i(scenario, "entry"))


func test_load_fills_both_boards_and_fight_plays_it() -> void:
	var app: App = _app()
	var sandbox: SandboxScreen = app.sandbox
	sandbox.show_tab("Scenarios")
	var load_button: Button = sandbox.find_child("Load_nightshade_tall", true, false) as Button
	assert_not_null(load_button)
	load_button.pressed.emit()
	var theirs: Array = sandbox.boards[1]
	var huge: Dictionary = Data.entry(theirs, 0)
	assert_eq(Data.s(huge, "display_name"), "Huge unit")
	assert_eq(Data.i(huge, "health"), 100)
	var banner: Label = sandbox.get("_banner")
	assert_true(banner.visible)
	assert_string_starts_with(banner.text, "Nightshade against one huge unit. Watch: ")
	sandbox.call("_on_fight")
	assert_true(app.current is CombatScreen, "Fight plays the scenario")
	var combat: CombatScreen = app.current as CombatScreen
	var title: Label = combat.get("_title")
	assert_string_contains(title.text, "Nightshade against one huge unit")
	var found: bool = false
	for entry: Variant in combat.events:
		var event: Dictionary = entry
		if Data.s(event, "type") == "health_loss" and Data.i(event, "amount") == 50:
			found = true
	assert_true(found, "the scenario's seed gives its expected halving (100 -> 50)")


func test_editing_a_loaded_scenario_says_so_and_clear_forgets_it() -> void:
	var app: App = _app()
	var sandbox: SandboxScreen = app.sandbox
	sandbox.load_scenario("nightshade_tall")
	sandbox.place(1, 3, "field_vole", false)
	var banner: Label = sandbox.get("_banner")
	assert_string_contains(banner.text, "(edited)")
	sandbox.clear_boards()
	assert_false(banner.visible)
	assert_eq(sandbox.scenario_title, "")


## Repeat Fight on an unedited scenario replays its own seed, so its watch line stays true; once
## edited, each Fight takes the next seed (review, 4 Nov).
func test_repeat_fight_replays_an_unedited_scenario_seed() -> void:
	var app: App = _app()
	var sandbox: SandboxScreen = app.sandbox
	sandbox.load_scenario("nightshade_tall")
	var scenario_seed: int = sandbox.fight_seed
	for i: int in 2:
		sandbox.call("_on_fight")
		assert_eq(sandbox.fight_seed, scenario_seed, "Fight %d keeps the scenario's seed" % (i + 1))
		app.show_sandbox()
	sandbox.place(1, 3, "field_vole", false)
	sandbox.call("_on_fight")
	assert_eq(sandbox.fight_seed, scenario_seed + 1, "edited: the next Fight takes a new seed")


func test_every_scenario_loads_and_fights_with_a_log_line_per_event() -> void:
	var app: App = _app()
	var port: CorePort = app.port as CorePort
	var sandbox: SandboxScreen = app.sandbox
	for scenario: Dictionary in port.scenarios():
		var id: String = Data.s(scenario, "id")
		sandbox.load_scenario(id)
		var tiers: Array = sandbox.get("_tiers")
		var result: Dictionary = port.sandbox_fight(sandbox.boards, sandbox.fight_seed, tiers)
		assert_false(result.has("error"), "%s: %s" % [id, Data.s(result, "error")])
		var model: CombatModel = CombatModel.new()
		var log_lines: CombatLog = CombatLog.new()
		for entry: Variant in Data.a(result, "events"):
			var event: Dictionary = entry
			var line: String = log_lines.describe(event, model)
			assert_ne(line, "(%s)" % Data.s(event, "type"), "%s: a real line" % id)
			model.apply(event)
		assert_true(model.finished, "%s fights to the end" % id)


func test_scenario_files_are_in_every_export_preset() -> void:
	var presets: String = FileAccess.get_file_as_string("res://export_presets.cfg")
	var filters: int = presets.count('include_filter="')
	assert_gt(filters, 0)
	assert_eq(presets.count("content/scenarios/*.json"), filters, "every preset")
