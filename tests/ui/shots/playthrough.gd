extends SceneTree
## Scripted playthrough: drives the real App through full games on the core with a scripted
## player (tests/ui/player_driver.gd), watching every combat at 4x, and checks the layout of
## every recruit turn before and after its actions, a selected card, combat mid-fight and at
## its result, and game over (tests/ui/layout_check.gd). Prints one PROBLEM line per fault and
## a summary.
##   LP_NUM_THREADS=2 xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy \
##     -s res://tests/ui/shots/playthrough.gd -- <WxH> [--late] [--level <id>] <seed> [...]
## tests/ui/full_ui_run.sh is the re-runnable run of whole games at both sizes, one process a game.
## --late reaches the late game through
## the dev panel's own actions: each turn it sets tier 6, adds gold and spawns tier 4-6 units
## (some golden) until the hand is full, the player fills the board, the hand is filled again,
## and the layout is checked with a full board and a full hand; it plays LATE_ROUNDS rounds.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const PlayerDriver := preload("res://tests/ui/player_driver.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const Data := preload("res://src/ui/view_data.gd")
const Records := preload("res://src/ui/records.gd")
const DevPanel := preload("res://src/ui/widgets/dev_panel.gd")
const HowToPlay := preload("res://src/ui/screens/how_to_play.gd")

const MAX_TURNS: int = 60
const LATE_ROUNDS: int = 5

var late: bool = false
var level: String = "normal"
var _driver: PlayerDriver

var _problems: Dictionary[String, bool] = {}
var _bad_words: RegEx = RegEx.create_from_string(
	"\\bBot \\d|\\b[a-z]+_[a-z_]+\\b|\\bOozes?\\b|\\bBirds?\\b|\\bYou (has|goes)\\b"
)


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("usage: -- <WxH> [--late] <seed> [<seed> ...]")
		quit(2)
		return
	var dims: PackedStringArray = args[0].split("x")
	var window_size: Vector2i = Vector2i(int(dims[0]), int(dims[1]))
	DisplayServer.window_set_size(window_size)
	root.size = window_size
	var seeds: Array[int] = []
	var i: int = 1
	while i < args.size():
		if args[i] == "--late":
			late = true
		elif args[i] == "--level":
			i += 1
			level = args[i]
		else:
			seeds.append(int(args[i]))
		i += 1
	Records.path = "user://playthrough_records.cfg"
	@warning_ignore("missing_await")
	_run(seeds, "%s%s" % [args[0], " late" if late else ""])


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _check(screen: Control, where: String, overlap: bool = true) -> void:
	for line: String in LayoutCheck.problems(screen, where, overlap):
		_problem(line)
	_check_words(screen, where)


## Reports each fault once, with the first place it was seen.
func _problem(line: String) -> void:
	var key: String = line.substr(line.find(": ") + 2)
	if not _problems.has(key):
		_problems[key] = true
		print("PROBLEM ", line)


## What a player reads has no bot numbers, no raw ids and nobody who isn't in the lobby.
## --late spawns cards from every tribe through the dev panel, so it skips this.
func _check_words(node: Node, where: String) -> void:
	if late:
		return
	var control: Control = node as Control
	if control != null and not control.is_visible_in_tree():
		return
	var words: String = ""
	if node is Label:
		words = (node as Label).text
	elif node is RichTextLabel:
		words = (node as RichTextLabel).get_parsed_text()
	if not words.is_empty():
		var found: RegExMatch = _bad_words.search(words)
		if found != null:
			_problem("%s: '%s' on screen in: %s" % [where, found.get_string(), words.left(70)])
	for child: Node in node.get_children():
		_check_words(child, where)


## The other things a turn can open: scouting, with a tap on their board and on a small shop tile.
func _tour_scouting(recruit: RecruitScreen, driver: PlayerDriver, where: String) -> void:
	recruit.toggle_scout()
	await _frames(2)
	_check(recruit, where + " scouting")
	var theirs: Array = Data.a(recruit.state, "next_opponent_last_board")
	for slot: int in theirs.size():
		if theirs[slot] != null:
			driver.tap(recruit, "scout", slot)
			await _frames(2)
			_check(recruit, where + " scouting, their unit open")
			driver.tap(recruit, "scout", slot)
			break
	if not Data.a(recruit.state, "shop").is_empty():
		driver.tap(recruit, "shop", 0)
		await _frames(2)
		_check(recruit, where + " scouting, a shop tile open")
		driver.tap(recruit, "shop", 0)
	recruit.toggle_scout()
	await _frames(1)


## Once a game: the guide's pages, settings and pause over a live game.
func _tour_overlays(app: App, recruit: RecruitScreen, where: String) -> void:
	var guide: HowToPlay = app.open_guide()
	for page: int in HowToPlay.PAGES.size():
		guide.page = page
		guide.call("_show_page")
		await _frames(2)
		_check(guide, where + " guide page %d" % (page + 1), false)
	guide.queue_free()
	var settings: Control = app.open_settings()
	await _frames(2)
	_check(settings, where + " settings", false)
	settings.queue_free()
	recruit.call("_open_pause")
	await _frames(2)
	_check(recruit, where + " pause", false)
	var pause: Control = recruit.get("_pause")
	pause.queue_free()
	recruit.set("_pause", null)
	await _frames(1)


## The dev panel's own actions: tier 6, gold, and a full hand of tier 4-6 units.
## A hero offer or a Discover blocks the screen: check how it looks, then take the first card.
func _answer_choices(recruit: RecruitScreen, where: String) -> void:
	var picks: int = 0
	while recruit.get("_discover") != null and picks < 5:
		var picker: Control = recruit.get("_discover")
		_check(recruit, where + " recruit, choice open", false)
		var driver_pick: PlayerDriver = _driver
		var cards: Array = picker.get("cards")
		var first: Control = cards[0]
		if not driver_pick.call("_click_control", first, "tapped", "a choice"):
			picker.call("_on_card_tapped", "picker", 0)
		picks += 1
		await _frames(2)


func _boost(recruit: RecruitScreen, rng: RandomNumberGenerator, where: String) -> void:
	var dev: DevPanel = recruit.get("_dev")
	var tier: SpinBox = dev.get("_tier")
	tier.value = 6
	dev.call("_on_set_tier")
	for i: int in 3:
		dev.call("_on_add_gold")
	_fill_hand(recruit, rng)
	recruit.toggle_dev_panel()
	await _frames(2)
	_check(recruit, where + " recruit, dev panel open")
	recruit.toggle_dev_panel()


## A full board (no empty slot) and a hand at the state's hand_limit.
static func _is_full(state: Dictionary) -> bool:
	var hand: int = Data.a(state, "hand").size()
	return not Data.a(state, "board").has(null) and hand >= Data.i(state, "hand_limit", 10)


func _fill_hand(recruit: RecruitScreen, rng: RandomNumberGenerator) -> void:
	var dev: DevPanel = recruit.get("_dev")
	var units: OptionButton = dev.get("_units")
	var golden: CheckBox = dev.get("_golden")
	var late_units: Array[int] = []
	for i: int in units.item_count:
		var tier: int = units.get_item_text(i).substr(1, 1).to_int()
		if tier >= 4:
			late_units.append(i)
	var limit: int = Data.i(recruit.state, "hand_limit", 10)
	for attempt: int in limit + 4:
		if Data.a(recruit.state, "hand").size() >= limit or late_units.is_empty():
			return
		units.select(late_units[rng.randi_range(0, late_units.size() - 1)])
		golden.button_pressed = rng.randf() < 0.3
		dev.call("_on_spawn")


func _run(seeds: Array[int], size_name: String) -> void:
	await process_frame
	var app: App = App.new()
	root.add_child(app)
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)
	for game_seed: int in seeds:
		var driver: PlayerDriver = PlayerDriver.new(game_seed)
		driver.viewport = root
		_driver = driver
		_check(app.current, "%s seed %d menu" % [size_name, game_seed])
		app.difficulty = level
		app.start_game(game_seed)
		var turns: int = 0
		while turns < MAX_TURNS:
			await _frames(2)
			var where: String = (
				"%s seed %d round %d" % [size_name, game_seed, Data.i(port.get_state(), "round")]
			)
			if late and turns >= LATE_ROUNDS:
				print("LATE seed %d: stopped after %d rounds" % [game_seed, turns])
				break
			if app.current is RecruitScreen:
				var recruit: RecruitScreen = app.current as RecruitScreen
				await _answer_choices(recruit, where)
				if turns == 1 and not late:
					await _tour_overlays(app, recruit, where)
				if late:
					await _boost(recruit, driver.rng, where)
				_check(recruit, where + " recruit")
				if not late:
					await _tour_scouting(recruit, driver, where)
				var board: Array = Data.a(recruit.state, "board")
				for slot: int in board.size():
					if board[slot] != null:
						recruit.call("_on_tapped", "board", slot)
						await _frames(2)
						_check(recruit, where + " recruit, board card selected")
						recruit.call("_on_tapped", "board", slot)
						break
				driver.act(recruit)
				await _frames(2)
				await _answer_choices(recruit, where)
				_check(recruit, where + " recruit, after the turn's actions")
				if late:
					# Triples and sells can leave gaps: play from the hand again, then refill it.
					for fill: int in 3:
						driver.call("_play_hand", recruit)
						_fill_hand(recruit, driver.rng)
						if _is_full(recruit.state):
							break
					await _frames(2)
					var hand: int = Data.a(recruit.state, "hand").size()
					var placed: int = 0
					for unit: Variant in Data.a(recruit.state, "board"):
						placed += 1 if unit != null else 0
					var toast: Label = recruit.get("_toast")
					print(
						(
							"LATE %s: tier %d, board %d/7, hand %d (%s)"
							% [where, Data.i(recruit.state, "tier"), placed, hand, toast.text]
						)
					)
					var limit: int = Data.i(recruit.state, "hand_limit", 10)
					if not _is_full(recruit.state):
						var counts: String = "board %d/7, hand %d/%d" % [placed, hand, limit]
						_problems[where + " not full"] = true
						print("PROBLEM %s: late check not full (%s)" % [where, counts])
					_check(recruit, where + " recruit, full board and hand")
					recruit.call("_on_tapped", "hand", hand - 1)
					await _frames(2)
					_check(recruit, where + " recruit, hand card selected")
					recruit.call("_on_tapped", "hand", hand - 1)
				for mismatch: String in driver.drop_mismatches:
					print("PROBLEM %s: %s" % [where, mismatch])
				driver.drop_mismatches.clear()
				for miss: String in driver.missed_taps:
					_problem("%s: %s" % [where, miss])
				driver.missed_taps.clear()
				driver.end_turn(recruit)
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
				var moments: PackedStringArray = app.current.get("moments")
				print("MOMENTS seed %d: %s" % [game_seed, " | ".join(moments)])
				app.show_menu()
				await _frames(2)
				break
			else:
				print("PROBLEM %s: unexpected screen %s" % [where, app.current])
				break
		if turns >= MAX_TURNS:
			print("PROBLEM seed %d: no game over after %d turns" % [game_seed, MAX_TURNS])
	var smallest: int = LayoutCheck.smallest_text
	print(
		(
			"PLAYTHROUGH %s: %d distinct problems, smallest text %d"
			% [size_name, _problems.size(), smallest]
		)
	)
	quit(0)
