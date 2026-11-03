extends SceneTree
## Renders one UI screen from the fixtures and saves a native-size PNG. Needs a real renderer:
##   xvfb-run -a -s "-screen 0 2560x1440x24" godot --rendering-driver opengl3 \
##     --audio-driver Dummy -s res://tests/ui/shots/screenshot.gd -- <screen> <WxH> <out.png>
## Screens: menu, recruit1, recruit7, recruit7_drag, combat_mid, combat_end, sandbox, game_over.
## tests/ui/render_screens.sh renders them all and converts them to JPEG.

const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const SandboxScreen := preload("res://src/ui/screens/sandbox_screen.gd")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("usage: -- <screen> <WxH> <out.png>")
		quit(2)
		return
	var dims: PackedStringArray = args[1].split("x")
	var window_size: Vector2i = Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(window_size)
	root.size = window_size
	@warning_ignore("missing_await")
	_run(args[0], window_size, args[2])


func _run(screen_name: String, window_size: Vector2i, out_path: String) -> void:
	await process_frame
	var port: FixturePort = FixturePort.new()
	var app: App = App.new()
	root.add_child(app)
	app.setup(port)
	match screen_name:
		"menu":
			pass
		"recruit1", "recruit7", "recruit7_select":
			app.start_game()
			port.use_state("recruit_round1" if screen_name == "recruit1" else "recruit_round7")
			app.show_recruit()
			if screen_name == "recruit7_select":
				var recruit: RecruitScreen = app.current as RecruitScreen
				recruit.call("_on_tapped", "board", 1)
		"combat_mid", "combat_end":
			app.start_game()
			port.use_state("recruit_round7")
			port.end_turn()
			app.show_game_combat()
			var combat: CombatScreen = app.current as CombatScreen
			combat.playing = false
			for i: int in 3:
				await process_frame
			if screen_name == "combat_end":
				combat.skip_to_end()
			else:
				# Play at 1x until Nightshade's halving has just landed.
				combat.playing = true
				while combat.next_index < 7:
					await process_frame
				for i: int in 25:
					await process_frame
		"sandbox":
			app.show_sandbox()
			var sandbox: SandboxScreen = app.sandbox
			sandbox.place(1, 1, "stoat_captain", false)
			sandbox.place(1, 2, "field_vole", false)
			sandbox.place(1, 5, "sett_warden", true)
			sandbox.place(0, 1, "hoglet_mother", false)
			sandbox.place(0, 5, "belladonna_sprite", false)
			sandbox.call("_on_tapped", "library", 3)
		"game_over":
			port.use_state("recruit_game_over")
			app.show_game_over()
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
