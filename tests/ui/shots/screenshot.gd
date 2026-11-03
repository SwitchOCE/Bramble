extends SceneTree
## Renders one UI screen from real rules-core state and saves a native-size PNG. Needs a real
## renderer:
##   xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- <screen> <WxH> <out.png> \
##     [look]
## `look` is a ThemeDirections id (plain, folk_print); Plain if left out.
## Screens: menu, recruit, recruit_select, recruit_triple (a dev-spawned triple), recruit_late
## (tier 6, full board and hand, through the dev panel), dev,
## combat_mid, combat_end, sandbox, sandbox_scenarios, sandbox_fight, game_over. The human's
## turns are played by a bot (config human_bot) for a few rounds so the board has units.
## tests/ui/render_screens.sh renders them all and converts them to JPEG.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const SEED: int = 20261104
const BOT_ROUNDS: int = 6


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3 and args.size() != 4:
		printerr("usage: -- <screen> <WxH> <out.png> [look]")
		quit(2)
		return
	if args.size() == 4:
		UiTheme.use(args[3], false)
	var dims: PackedStringArray = args[1].split("x")
	var window_size: Vector2i = Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(window_size)
	root.size = window_size
	@warning_ignore("missing_await")
	_run(args[0], window_size, args[2])


## A core game whose human is played by a bot for `rounds` rounds (or until it is out).
func _bot_game(app: App, rounds: int) -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("human_bot", "tribe")
	var port: CorePort = CorePort.new()
	port.setup(config)
	app.setup(port)
	port.new_game(SEED)
	for i: int in rounds:
		if port.is_over() or port.get_state().get("placement") != null:
			break
		port.end_turn()


func _play_until(combat: CombatScreen, index: int) -> void:
	combat.playing = true
	var frames: int = 0
	while combat.next_index < index and frames < 2000:
		await process_frame
		frames += 1
	for i: int in 22:
		await process_frame


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	await process_frame
	var app: App = App.new()
	root.add_child(app)
	match screen_name:
		"menu":
			var port: CorePort = CorePort.new()
			port.setup()
			app.setup(port)
		"recruit_triple":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var triple_screen: RecruitScreen = app.current as RecruitScreen
			var panel: Object = triple_screen.get("_dev")
			var ids: PackedStringArray = panel.get("_ids")
			var options: OptionButton = panel.get("_units")
			options.select(ids.find("field_vole"))
			for i: int in 3:
				panel.call("_on_spawn")
			var hand: Array = Data.a(app.port.get_state(), "hand")
			for i: int in hand.size():
				if Data.b(Data.entry(hand, i), "golden", false):
					triple_screen.call("_on_tapped", "hand", i)
		"recruit_late":
			# Tier 6 through the dev panel: tier 4-6 units (every third golden) fill the board, then
			# the hand.
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var late_screen: RecruitScreen = app.current as RecruitScreen
			var late_panel: Object = late_screen.get("_dev")
			var tier_box: SpinBox = late_panel.get("_tier")
			tier_box.value = 6
			late_panel.call("_on_set_tier")
			var late_options: OptionButton = late_panel.get("_units")
			var golden_box: CheckBox = late_panel.get("_golden")
			var picks: Array[int] = []
			for i: int in late_options.item_count:
				if late_options.get_item_text(i).substr(1, 1).to_int() >= 4:
					picks.append(i)
			for round_trip: int in 2:
				for i: int in 12:
					late_options.select(picks[(i * 5 + round_trip * 3) % picks.size()])
					golden_box.button_pressed = i % 3 == 0
					late_panel.call("_on_spawn")
				if round_trip == 0:
					for i: int in 7:
						var state: Dictionary = app.port.get_state()
						var board: Array = Data.a(state, "board")
						var empty: int = board.find(null)
						if empty < 0 or Data.a(state, "hand").is_empty():
							break
						late_screen.call("_on_tapped", "hand", 0)
						late_screen.call("_on_tapped", "board", empty)
		"recruit", "recruit_select", "dev":
			_bot_game(app, BOT_ROUNDS)
			app.show_recruit()
			var recruit: RecruitScreen = app.current as RecruitScreen
			if screen_name == "recruit_select":
				recruit.call("_on_tapped", "shop", 0)
			elif screen_name == "dev":
				recruit.toggle_dev_panel()
				var dev: Object = recruit.get("_dev")
				dev.call("_on_add_gold")
		"combat_mid", "combat_end":
			_bot_game(app, BOT_ROUNDS)
			app.show_game_combat()
			var combat: CombatScreen = app.current as CombatScreen
			combat.playing = false
			for i: int in 3:
				await process_frame
			if screen_name == "combat_end":
				combat.skip_to_end()
			else:
				await _play_until(combat, mini(9, combat.events.size() - 2))
		"sandbox_scenarios":
			var scenario_port: CorePort = CorePort.new()
			scenario_port.setup()
			app.setup(scenario_port)
			app.show_sandbox()
			app.sandbox.show_tab("Scenarios")
			app.sandbox.load_scenario("nightshade_tall")
		"sandbox", "sandbox_fight":
			var port: CorePort = CorePort.new()
			port.setup()
			app.setup(port)
			app.show_sandbox()
			var sandbox: SandboxScreen = app.sandbox
			sandbox.place(1, 0, "stoat_captain", false)
			sandbox.place(1, 1, "old_badger", true)
			sandbox.place(1, 2, "sett_warden", false)
			sandbox.place(1, 5, "fairy_monarch", false)
			sandbox.place(0, 1, "hoglet_mother", false)
			sandbox.place(0, 2, "bitter_toad", false)
			sandbox.place(0, 5, "belladonna_sprite", false)
			sandbox.set_stats(1, 1, 40, 70)
			if screen_name == "sandbox":
				sandbox.call("_on_tapped", "enemy", 1)
			else:
				sandbox.call("_on_fight")
				var fight: CombatScreen = app.current as CombatScreen
				fight.playing = false
				for i: int in 3:
					await process_frame
				await _play_until(fight, mini(8, fight.events.size() - 2))
		"game_over":
			_bot_game(app, 60)
			app.show_recruit()
		_:
			printerr("unknown screen: %s" % screen_name)
			quit(2)
			return
	for i: int in 20:
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image.get_size() != window_size:
		printerr("screenshot: got %s, wanted %s" % [image.get_size(), window_size])
		quit(1)
		return
	image.save_png(out_path)
	print("screenshot: saved %s %s" % [out_path, image.get_size()])
	quit(0)
