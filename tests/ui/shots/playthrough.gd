extends SceneTree
## Scripted playthrough: drives the real App through full games on the core, as a player would
## (tests/ui/player_driver.gd), watching every combat at 4x, and checks the layout of every
## recruit turn, a selected card, combat mid-fight and at its result, and game over
## (tests/ui/layout_check.gd). Prints one PROBLEM line per fault and a summary.
##   LP_NUM_THREADS=2 xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy \
##     -s res://tests/ui/shots/playthrough.gd -- <WxH> <seed> [<seed> ...]

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const PlayerDriver := preload("res://tests/ui/player_driver.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const Data := preload("res://src/ui/view_data.gd")

const MAX_TURNS: int = 60

var _problems: Dictionary[String, bool] = {}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <WxH> <seed> [<seed> ...]")
		quit(2)
		return
	var dims: PackedStringArray = args[0].split("x")
	var window_size: Vector2i = Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(window_size)
	root.size = window_size
	var seeds: Array[int] = []
	for i: int in range(1, args.size()):
		seeds.append(int(args[i]))
	@warning_ignore("missing_await")
	_run(seeds, args[0])


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _check(screen: Control, where: String, overlap: bool = true) -> void:
	for line: String in LayoutCheck.problems(screen, where, overlap):
		# Report each fault once, with the first place it was seen.
		var key: String = line.substr(line.find(": ") + 2)
		if not _problems.has(key):
			_problems[key] = true
			print("PROBLEM ", line)


func _run(seeds: Array[int], size_name: String) -> void:
	await process_frame
	var app: App = App.new()
	root.add_child(app)
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)
	for game_seed: int in seeds:
		var driver: PlayerDriver = PlayerDriver.new(game_seed)
		app.start_game(game_seed)
		var turns: int = 0
		while turns < MAX_TURNS:
			await _frames(2)
			var where: String = (
				"%s seed %d round %d" % [size_name, game_seed, Data.i(port.get_state(), "round")]
			)
			if app.current is RecruitScreen:
				var recruit: RecruitScreen = app.current as RecruitScreen
				_check(recruit, where + " recruit")
				var board: Array = Data.a(recruit.state, "board")
				for slot: int in board.size():
					if board[slot] != null:
						recruit.call("_on_tapped", "board", slot)
						await _frames(2)
						_check(recruit, where + " recruit, board card selected")
						recruit.call("_on_tapped", "board", slot)
						break
				driver.play_turn(recruit)
				turns += 1
			elif app.current is CombatScreen:
				var combat: CombatScreen = app.current as CombatScreen
				combat.set_speed(4.0)
				var frames: int = 0
				while not combat.is_showing_result() and frames < 4000:
					await process_frame
					frames += 1
					if frames == 40:
						_check(combat, where + " combat mid-fight", false)
				await _frames(2)
				_check(combat, where + " combat result")
				combat.finished.emit()
			elif app.current is GameOverScreen:
				_check(app.current, where + " game over")
				var state: Dictionary = port.get_state()
				print(
					(
						"GAME seed %d: place %s after %d turns, actions %s"
						% [game_seed, str(state.get("placement")), turns, driver.counts]
					)
				)
				break
			else:
				print("PROBLEM %s: unexpected screen %s" % [where, app.current])
				break
		if turns >= MAX_TURNS:
			print("PROBLEM seed %d: no game over after %d turns" % [game_seed, MAX_TURNS])
	print("PLAYTHROUGH %s: %d distinct problems" % [size_name, _problems.size()])
	quit(0)
