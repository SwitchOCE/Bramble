extends Control
## The game: the start screen, then one game against ghosts (GameController), then the result
## screen. Escape, or the cog at the top left of the recruit and fight screens (SettingsCog),
## opens the pause panel (Resume, Quit to start, Quit, and the setting for where a carried card
## drops); F11 toggles fullscreen.
## The stage is 1920 x 1080, letterboxed to the window (project settings: stretch canvas_items,
## aspect keep). scripts/export_smoke.sh boots the exported build and waits for READY_LINE.
## `--autoplay` after `--` on the command line starts a game at once with autoplay on; `--seed N`
## plays the game with that seed (the pause panel shows each game's seed).

const READY_LINE: String = "boot: main scene ready"
const GHOST_GAME_FINISHED: String = "boot: ghost game finished"
const GHOST_FIELD: String = "res://ghosts/field"
const GHOST_HOME: String = "user://ghosts"
const NO_GHOSTS: String = "Error G1: this build has no ghosts to play against."
const GHOSTS_USED: String = "Restart Bramble to play against more ghosts."

var content: GameContent
var ghost_store: LayeredGhostStore
var screen: Control
var browser: CardBrowser
var pause: PausePanel
## The cog that opens the pause panel, shown during a game.
var cog: SettingsCog
## The pause panel's own layer, above every screen's raised cards, splashes and hints.
var _browser_layer: CanvasLayer
var _pause_layer: CanvasLayer
## The cog's own layer, under the pause panel's (whose dim covers it), shown during a game.
var _cog_layer: CanvasLayer
var _seen_runs: Dictionary = {}
var _headless_autoplay: bool = false


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var field_at: int = args.find("--ghost-field")
	var field: String = GHOST_FIELD
	if field_at >= 0:
		if field_at + 1 >= args.size() or args[field_at + 1].begins_with("--"):
			printerr("ghosts: --ghost-field needs a directory")
			get_tree().quit(2)
			return
		field = args[field_at + 1]
	if ghost_store == null:
		ghost_store = LayeredGhostStore.new(GHOST_HOME, field)
	var replay_at: int = args.find("--replay-record")
	if replay_at >= 0:
		if replay_at + 1 >= args.size() or args[replay_at + 1].begins_with("--"):
			printerr("records: --replay-record needs a path")
			get_tree().quit(2)
			return
		var store_at: int = args.find("--ghost-store")
		var store: GhostStore = ghost_store
		if store_at >= 0:
			if store_at + 1 >= args.size() or args[store_at + 1].begins_with("--"):
				printerr("records: --ghost-store needs a directory")
				get_tree().quit(2)
				return
			store = GhostStore.new(args[store_at + 1])
		var result: Dictionary = RecordReplay.read(args[replay_at + 1], store)
		var ok: bool = CoreUtil.to_bool(result.get("ok", false))
		print(
			(
				(
					"records: matched %s turns (%s)"
					% [
						result.get("turns", 0),
						"complete" if result.get("complete", false) else "unfinished"
					]
				)
				if ok
				else "records: " + str(result.get("message", "failed"))
			)
		)
		get_tree().quit(0 if ok else 1)
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	content = GameContent.load_default()
	_make_cog()
	if args.has("--autoplay"):
		_headless_autoplay = DisplayServer.get_name() == "headless"
	show_start()
	print(READY_LINE)
	if args.has("--autoplay"):
		if (screen as StartScreen).play_enabled:
			start_game(true)
		elif _headless_autoplay:
			get_tree().quit(1)


func show_start() -> void:
	var available: Dictionary = GameFlow.pick_opponents(ghost_store, 0, _seen_runs)
	_show_start("" if available["ok"] else _unavailable_message(available))


func _show_start(message: String) -> void:
	var start: StartScreen = StartScreen.new()
	start.name = "Start"
	start.message = message
	start.play_enabled = message.is_empty()
	if start.play_enabled:
		start.play_requested.connect(func(_tribes: PackedStringArray) -> void: start_game())
	start.quit_requested.connect(quit)
	start.cards_requested.connect(open_browser)
	_swap(start)


func _unavailable_message(result: Dictionary) -> String:
	if result.get("exhausted", false):
		return GHOSTS_USED
	push_error("%s %s" % [NO_GHOSTS, result["message"]])
	return NO_GHOSTS


func start_game(autoplay: bool = false) -> void:
	var prepared: Dictionary = GameFlow.create(content, _seed(), ghost_store, _seen_runs)
	if not prepared["ok"]:
		_show_start(_unavailable_message(prepared))
		if _headless_autoplay:
			get_tree().quit(1)
		return
	var flow: GameFlow = prepared["flow"]
	for id: String in flow.session.run_ids:
		if not id.is_empty():
			_seen_runs[id] = true
	var game: GameController = GameController.new()
	game.name = "Game"
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.autoplay = autoplay
	game.game_finished.connect(show_result)
	game.cards_requested.connect(open_browser)
	_swap(game)
	game.start(flow)


func show_result(standings: Array[Dictionary], round_number: int) -> void:
	var result: ResultScreen = ResultScreen.new()
	result.name = "Result"
	result.standings = standings
	result.round_number = round_number
	result.play_again_requested.connect(start_game)
	result.start_screen_requested.connect(show_start)
	result.quit_requested.connect(quit)
	_swap(result)
	if _headless_autoplay:
		print(GHOST_GAME_FINISHED)
		get_tree().quit()


## The seed after `--seed` on the command line, else a random one.
func _seed() -> int:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var at: int = args.find("--seed")
	if at >= 0 and at + 1 < args.size() and args[at + 1].is_valid_int():
		return args[at + 1].to_int()
	return randi() % 1000000


func _make_cog() -> void:
	_cog_layer = CanvasLayer.new()
	_cog_layer.name = "CogLayer"
	_cog_layer.layer = 9
	add_child(_cog_layer)
	var holder: Control = Control.new()
	holder.name = "CogHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cog_layer.add_child(holder)
	var stage: Control = GlassUi.stage(holder)
	cog = SettingsCog.new()
	cog.name = "Cog"
	# paused with the game: while the panel is open, Resume and Escape close it
	cog.process_mode = Node.PROCESS_MODE_PAUSABLE
	cog.held = _card_held
	cog.pressed.connect(toggle_pause)
	cog.visible = false
	stage.add_child(cog)


## Whether a card is held on the recruit screen now (the cog then does nothing).
func _card_held() -> bool:
	var game: GameController = screen as GameController
	return game != null and game.recruit != null and game.recruit.is_holding()


func quit() -> void:
	get_tree().quit()


func toggle_pause() -> void:
	if browser != null:
		return
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
	# the cog reads the pointer ahead of the game (which takes any click in a fight to skip): it
	# stays after it
	cog.visible = next is GameController
	move_child(_cog_layer, -1)


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


## A separate layer keeps the game and its exact UI state alive under the dim.
func open_browser() -> void:
	if browser != null or pause != null or _card_held():
		return
	browser = CardBrowser.new()
	browser.name = "CardBrowser"
	browser.content = content
	browser.in_game = screen is GameController
	browser.process_mode = Node.PROCESS_MODE_ALWAYS
	browser.close_requested.connect(close_browser)
	_browser_layer = CanvasLayer.new()
	_browser_layer.name = "BrowserLayer"
	_browser_layer.layer = 10
	_browser_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_browser_layer)
	_browser_layer.add_child(browser)
	# StartScreen inherits ALWAYS from main, so explicitly disable its input as well.
	screen.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = true


func close_browser() -> void:
	if browser == null:
		return
	remove_child(_browser_layer)
	_browser_layer.queue_free()
	_browser_layer = null
	browser = null
	screen.process_mode = (
		Node.PROCESS_MODE_PAUSABLE if screen is GameController else Node.PROCESS_MODE_INHERIT
	)
	get_tree().paused = false
