extends Control
## The game: the start screen, then one game against bots (GameController), then the result
## screen. Escape opens the pause panel (Resume, Quit to start, Quit); F11 toggles fullscreen.
## The stage is 1920 x 1080, letterboxed to the window (project settings: stretch canvas_items,
## aspect keep). scripts/export_smoke.sh boots the exported build and waits for READY_LINE.
## `--autoplay` after `--` on the command line starts a game at once with autoplay on; `--seed N`
## plays the game with that seed (the pause panel shows each game's seed).

const READY_LINE: String = "boot: main scene ready"

var content: GameContent
var screen: Control
var pause: PausePanel
## The pause panel's own layer, above every screen's raised cards, splashes and hints.
var _pause_layer: CanvasLayer
var _tribes: PackedStringArray = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	content = GameContent.load_default()
	if OS.get_cmdline_user_args().has("--autoplay"):
		start_game(PackedStringArray(), true)
	else:
		show_start()
	print(READY_LINE)


func show_start() -> void:
	var start: StartScreen = StartScreen.new()
	start.name = "Start"
	start.tribes = content.tribe_ids()
	for tribe_id: String in start.tribes:
		start.names[tribe_id] = content.tribe_name(tribe_id)
	# back from a game: the tribes it had are still chosen
	start.choose(_tribes)
	start.play_requested.connect(start_game)
	start.quit_requested.connect(quit)
	_swap(start)


func start_game(tribes: PackedStringArray, autoplay: bool = false) -> void:
	_tribes = tribes
	var game: GameController = GameController.new()
	game.name = "Game"
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.autoplay = autoplay
	game.game_finished.connect(show_result)
	_swap(game)
	game.start(content, _seed(), tribes)


func show_result(standings: Array[Dictionary], round_number: int) -> void:
	var result: ResultScreen = ResultScreen.new()
	result.name = "Result"
	result.standings = standings
	result.round_number = round_number
	result.play_again_requested.connect(func() -> void: start_game(_tribes))
	result.start_screen_requested.connect(show_start)
	result.quit_requested.connect(quit)
	_swap(result)


## The seed after `--seed` on the command line, else a random one.
func _seed() -> int:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var at: int = args.find("--seed")
	if at >= 0 and at + 1 < args.size() and args[at + 1].is_valid_int():
		return args[at + 1].to_int()
	return randi() % 1000000


func quit() -> void:
	get_tree().quit()


func toggle_pause() -> void:
	if pause != null:
		_close_pause()
		return
	if not screen is GameController:
		return
	pause = PausePanel.new()
	pause.name = "Pause"
	var game: GameController = screen as GameController
	if game.flow != null:
		pause.game_seed = game.flow.game_seed
	pause.process_mode = Node.PROCESS_MODE_ALWAYS
	pause.resume_requested.connect(_close_pause)
	pause.quit_to_start_requested.connect(
		func() -> void:
			_close_pause()
			show_start()
	)
	pause.quit_requested.connect(quit)
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseLayer"
	_pause_layer.layer = 10
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	_pause_layer.add_child(pause)
	get_tree().paused = true


func _close_pause() -> void:
	if pause != null:
		remove_child(_pause_layer)
		_pause_layer.queue_free()
		_pause_layer = null
		pause = null
	get_tree().paused = false


func _swap(next: Control) -> void:
	if screen != null:
		remove_child(screen)
		screen.queue_free()
	screen = next
	add_child(next)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F11:
		var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		get_viewport().set_input_as_handled()
