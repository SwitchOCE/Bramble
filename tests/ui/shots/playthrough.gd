extends SceneTree
## Scripted playthrough: drives the real App through full games on the core with a scripted
## player (tests/ui/player_driver.gd), watching every combat at 4x, and checks the layout of
## every recruit turn before and after its actions, a selected card, combat mid-fight and at
## its result, and game over (tests/ui/layout_check.gd). Prints one PROBLEM line per fault and
## a summary.
##   LP_NUM_THREADS=2 xvfb-run -a godot --rendering-driver opengl3 --audio-driver Dummy \
##     -s res://tests/ui/shots/playthrough.gd -- <WxH> [--late] [--level <id>] <seed> [...]
## tests/ui/full_ui_run.sh is the re-runnable run of whole games at both sizes, one process a game.
## --skilled plays to last (PlayerDriver.skilled); --cap <n> fields at most n units (board_cap).
## --late reaches the late game through the dev
## panel's own actions: each turn it sets tier 6, adds gold and spawns tier 4-6 units of this game's
## card set (some golden) until the hand is full, the player fills the board, the hand is filled
## again, and the layout is checked with a full board and a full hand; it plays LATE_ROUNDS rounds.
##
## Clicked for real, with what each press must do checked (the game changes, or the player is told
## why not): New game, Buy, Sell, Play, hero power, playing a unit by tapping it
## and a slot, Refresh, Freeze, tier up, Scout, Who?, Close, the pause menu, Settings and Back, the
## guide's
## pages, speed, Watch again from pause, Skip and Main menu. Not clicked: drags and drops (the
## screen's own drop handlers), the dev panel, Leave game, Quit. The New game signal is
## caught so a game can use this run's seed and lobby, so the first-game guide and the random seed
## aren't run.

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
const MainMenu := preload("res://src/ui/screens/main_menu.gd")
const SettingsScreen := preload("res://src/ui/screens/settings_screen.gd")
const Words := preload("res://tests/ui/playthrough_words.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")

const MAX_TURNS: int = 60
const LATE_ROUNDS: int = 5

var late: bool = false
var skilled: bool = false
var board_cap: int = 7
var level: String = "hard"
var _driver: PlayerDriver

var _problems: Dictionary[String, bool] = {}
var _bad_words: RegEx = Words.pattern([])


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
		elif args[i] == "--skilled":
			skilled = true
		elif args[i] == "--cap":
			i += 1
			board_cap = int(args[i])
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
	# Layout checks describe the resting screen, after the pointer's decorative lift retires.
	if screen is RecruitScreen:
		root.warp_mouse(Vector2(5, 1070))
		await _frames(12)
	for line: String in LayoutCheck.problems(screen, where, overlap):
		_problem(line)
	# The menu guide teaches the whole game, including tribes absent from this lobby.
	_check_words(screen, where, Words.pattern([]) if screen is HowToPlay else _bad_words)


## Reports each fault once, with the first place it was seen.
func _problem(line: String) -> void:
	var key: String = line.substr(line.find(": ") + 2)
	if not _problems.has(key):
		_problems[key] = true
		print("PROBLEM ", line)


## What a player reads has no bot numbers, no raw ids and nobody who isn't in the lobby.
func _check_words(node: Node, where: String, words_pattern: RegEx) -> void:
	var control: Control = node as Control
	if control != null and not control.is_visible_in_tree():
		return
	var words: String = ""
	if node is Label:
		words = (node as Label).text
	elif node is RichTextLabel:
		words = (node as RichTextLabel).get_parsed_text()
	if not words.is_empty():
		var found: RegExMatch = words_pattern.search(words)
		if found != null:
			_problem("%s: '%s' on screen in: %s" % [where, found.get_string(), words.left(70)])
	for child: Node in node.get_children():
		_check_words(child, where, words_pattern)


## Every miss so far becomes a problem.
func _drain_misses(where: String) -> void:
	for mismatch: String in _driver.drop_mismatches:
		_problem("%s: %s" % [where, mismatch])
	_driver.drop_mismatches.clear()
	for miss: String in _driver.missed_taps:
		_problem("%s: %s" % [where, miss])
	_driver.missed_taps.clear()


static func _button_named(under: Node, words: String) -> Button:
	for found: Node in under.find_children("*", "Button", true, false):
		var button: Button = found as Button
		if button.text == words and button.is_visible_in_tree():
			return button
	return null


## A button found by its words; not finding it is a problem of its own.
func _press_named(under: Node, words: String) -> void:
	var button: Button = _button_named(under, words)
	if button == null:
		_driver.expect(false, "no '%s' button on screen" % words)
		return
	_driver.press(button, words)


## From the menu by clicks, as a player would. The leaf's signal starts this run's seed and lobby.
func _start_by_clicks(app: App, game_seed: int, where: String) -> void:
	var menu: MainMenu = app.current as MainMenu
	var chosen: Array[bool] = []
	menu.play_requested.disconnect(app.request_new_game)
	menu.play_requested.connect(func() -> void: chosen.append(true))
	_press_named(menu, "New game")
	await _frames(2)
	_driver.expect(chosen.size() == 1, "New game requests one game directly")
	app.start_game(game_seed)
	_bad_words = Words.pattern(Data.a(app.port.get_state(), "lobby_tribes"))
	_drain_misses(where)


## The other things a turn can open: scouting, with a tap on their board, their hero or what a ghost
## is, a small shop tile, and now and then a purchase through that tile.
func _tour_scouting(recruit: RecruitScreen, driver: PlayerDriver, where: String) -> void:
	var scout: Control = recruit.get("_scout")
	var token: Button = recruit.get("_scout_token")
	var hero: Control = scout.get("_hero")
	var detail: Control = recruit.get("_detail")
	var lobby: Control = recruit.get("_lobby")
	var next_tap: Control
	for plaque: Control in lobby.get("plaques"):
		if CoreUtil.to_bool(plaque.get("is_next")):
			next_tap = plaque.get("tap")
			break
	driver.expect(next_tap != null, "Scout: next opponent portrait is present")
	if next_tap == null:
		return
	driver.expect(
		CoreUtil.to_bool(driver.call("_click_control", next_tap, "tapped", "Scout portrait")),
		"Scout: the next opponent portrait receives the click"
	)
	await _frames(2)
	driver.expect(scout.visible, "Scout: their board didn't open")
	await _check(recruit, where + " scouting")
	if RecruitView.is_ghost_next(recruit.state):
		var ghost: Dictionary = detail.get("shown")
		driver.expect(
			(
				detail.visible
				and (Data.s(ghost, "name") + " " + Data.s(ghost, "text")).to_lower().contains(
					"ghost"
				)
			),
			"Ghost: opening Scout shows who the ghost is"
		)
		await _check(recruit, where + " scouting, ghost identity")
	var theirs: Array = Data.a(recruit.state, "next_opponent_last_board")
	for slot: int in theirs.size():
		if theirs[slot] != null:
			driver.tap(recruit, "scout", slot)
			await _frames(2)
			await _check(recruit, where + " scouting, their unit open")
			break
	if hero.is_visible_in_tree():
		var before: Dictionary = detail.get("shown")
		driver.expect(
			CoreUtil.to_bool(driver.call("_click_control", hero, "tapped", "Who portrait")),
			"Who?: the scouting portrait receives the click"
		)
		await _frames(2)
		var after: Dictionary = detail.get("shown")
		driver.expect(after != before or before.is_empty(), "Who?: the panel didn't change")
		driver.expect(detail.visible, "Who?: nothing shown")
		await _check(recruit, where + " scouting, who they are")
	else:
		driver.expect(
			RecruitView.is_ghost_next(recruit.state), "Who?: living opponent has no portrait"
		)
	driver.press(token, "Close")
	await _frames(2)
	driver.expect(not scout.visible, "Close: their board stayed open")
	if not Data.a(recruit.state, "shop").is_empty():
		driver.tap(recruit, "shop", 0)
		await _frames(2)
		await _check(recruit, where + " after scouting, a shop tile open")
		var card: Dictionary = Data.entry(Data.a(recruit.state, "shop"), 0)
		var hand: int = Data.a(recruit.state, "hand").size()
		var affordable: bool = Data.i(card, "cost", 3) <= Data.i(recruit.state, "gold")
		if affordable and driver.rng.randf() < 0.25 and hand < 7:
			driver.call("_press_detail_action", recruit, "Buy")
			await _frames(2)
			driver.expect(
				Data.a(recruit.state, "hand").size() > hand, "buying after scouting failed"
			)
			await _check(recruit, where + " after scouting, bought from a shop tile")
		else:
			driver.tap(recruit, "shop", 0)
	_drain_misses(where)


## Once a game, by clicks: pause, settings and back, the guide's pages, back to the game.
func _tour_overlays(app: App, recruit: RecruitScreen, driver: PlayerDriver, where: String) -> void:
	var gear: Button = recruit.get("_menu_token")
	driver.press(gear, "gear")
	await _frames(2)
	var pause: Control = recruit.get("_pause")
	driver.expect(pause != null, "gear: no pause menu")
	if pause == null:
		_drain_misses(where)
		return
	await _check(recruit, where + " pause", false)
	_press_named(pause, "Settings")
	await _frames(2)
	var settings: SettingsScreen = _overlay(app, "settings") as SettingsScreen
	driver.expect(settings != null, "Settings: didn't open")
	if settings != null:
		await _check(settings, where + " settings", false)
		var back: Button = settings.get("_back")
		driver.press(back, "Settings Back")
		await _frames(2)
		driver.expect(
			not is_instance_valid(settings) or settings.is_queued_for_deletion(), "Back: stayed"
		)
	_press_named(pause, "How to play")
	await _frames(2)
	var guide: HowToPlay = _overlay(app, "guide") as HowToPlay
	driver.expect(guide != null, "How to play: didn't open")
	if guide != null:
		for page: int in HowToPlay.PAGES.size():
			driver.expect(guide.page == page, "guide: on page %d, wanted %d" % [guide.page, page])
			await _check(guide, where + " guide page %d" % (page + 1), false)
			var next_leaf: Button = guide.get("_next")
			driver.press(next_leaf, "guide Next")
			await _frames(2)
		driver.expect(
			not is_instance_valid(guide) or guide.is_queued_for_deletion(), "guide stayed"
		)
	_press_named(pause, "Back to game")
	await _frames(2)
	var still_open: Control = recruit.get("_pause")
	driver.expect(still_open == null, "Back to game: pause stayed")
	_drain_misses(where)


static func _overlay(app: App, kind: String) -> Control:
	for child: Node in app.get_children():
		if child.is_queued_for_deletion():
			continue
		if kind == "settings" and child is SettingsScreen:
			return child as Control
		if kind == "guide" and child is HowToPlay:
			return child as Control
	return null


## Cycle the speed token, watch playback and wait for the real automatic return.
## Once a game, replay from the pause menu and skip using its glyph token.
func _watch_fight(app: App, combat: CombatScreen, where: String, replay: bool) -> void:
	var speed_token: Button = combat.get("_speed_button")
	for tap: int in 3:
		if is_equal_approx(combat.speed, 4.0):
			break
		_driver.press(speed_token, "speed")
	_driver.expect(is_equal_approx(combat.speed, 4.0), "speed token: speed is %s" % combat.speed)
	var checked_end: bool = false
	if replay:
		var gear: Button = combat.get("_gear")
		_driver.press(gear, "pause fight")
		await _frames(2)
		_press_named(combat, "Watch again")
		await _frames(2)
		_driver.expect(not combat.model.finished, "Watch again: fight did not restart")
		var skip: Button = combat.get("_skip_button")
		_driver.press(skip, "Skip")
		_driver.expect(combat.model.finished, "Skip: fight did not finish")
		await _check(combat, where + " skipped combat end")
		checked_end = true
	var frames: int = 0
	while is_instance_valid(combat) and app.current == combat and frames < 4000:
		var pending: Array = combat.get("_tweens")
		var moving: bool = false
		for tween: Tween in pending:
			moving = moving or (tween.is_valid() and tween.get_loops_left() != 0)
		if combat.model.finished and not checked_end and not moving:
			await _check(combat, where + " combat end")
			checked_end = true
		if frames == 40 and not combat.model.finished:
			await _check(combat, where + " combat mid-fight", false)
		await process_frame
		frames += 1
	_driver.expect(
		not is_instance_valid(combat) or app.current != combat,
		"fight did not automatically return after %d frames" % frames
	)
	_driver.expect(checked_end, "combat end: no settled layout was checked")
	_drain_misses(where)


## The dev panel's own actions: tier 6, gold, and a full hand of tier 4-6 units.
## A hero offer or a Discover blocks the screen: check how it looks, then take the first card.
func _answer_choices(recruit: RecruitScreen, where: String) -> void:
	var picks: int = 0
	while recruit.get("_discover") != null and picks < 5:
		var picker: Control = recruit.get("_discover")
		await _check(recruit, where + " recruit, choice open", false)
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
	await _check(recruit, where + " recruit, dev panel open")
	recruit.toggle_dev_panel()


## A full board (no empty slot) and a hand at the state's hand_limit.
static func _is_full(state: Dictionary) -> bool:
	var hand: int = Data.a(state, "hand").size()
	return (
		not Data.a(state, "board").has(null)
		and hand >= Data.i(state, "hand_limit", GameConfig.full_game().get_int("hand_limit"))
	)


func _fill_hand(recruit: RecruitScreen, rng: RandomNumberGenerator) -> void:
	var dev: DevPanel = recruit.get("_dev")
	var units: OptionButton = dev.get("_units")
	var golden: CheckBox = dev.get("_golden")
	var late_units: Array[int] = []
	var ids: PackedStringArray = dev.get("_ids")
	var in_game: Dictionary = {}
	var library: UnitLibrary = (recruit.port as CorePort).library
	for def: Dictionary in library.pool_units(GameConfig.full_game().card_set()):
		in_game[str(def["id"])] = true
	for i: int in units.item_count:
		var tier: int = units.get_item_text(i).substr(1, 1).to_int()
		if tier >= 4 and in_game.has(ids[i]):
			late_units.append(i)
	var limit: int = Data.i(
		recruit.state, "hand_limit", GameConfig.full_game().get_int("hand_limit")
	)
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
		driver.skilled = skilled
		driver.board_cap = board_cap
		_driver = driver
		await _check(app.current, "%s seed %d menu" % [size_name, game_seed])
		await _start_by_clicks(app, game_seed, "%s seed %d" % [size_name, game_seed])
		var turns: int = 0
		var ghosts: int = 0
		var top_tier: int = 1
		var fights: int = 0
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
					await _tour_overlays(app, recruit, driver, where)
				if late:
					await _boost(recruit, driver.rng, where)
				await _check(recruit, where + " recruit")
				await _tour_scouting(recruit, driver, where)
				var board: Array = Data.a(recruit.state, "board")
				for slot: int in board.size():
					if board[slot] != null:
						driver.tap(recruit, "board", slot)
						await _frames(2)
						await _check(recruit, where + " recruit, board card selected")
						driver.tap(recruit, "board", slot)
						break
				driver.act(recruit)
				await _frames(2)
				await _answer_choices(recruit, where)
				await _settle(recruit)
				await _check(recruit, where + " recruit, after the turn's actions")
				if late:
					await _check_full(recruit, driver, where)
				_drain_misses(where)
				top_tier = maxi(top_tier, Data.i(recruit.state, "tier", 1))
				ghosts += 1 if RecruitView.is_ghost_next(recruit.state) else 0
				driver.end_turn(recruit)
				turns += 1
			elif app.current is CombatScreen:
				var combat: CombatScreen = app.current as CombatScreen
				await _watch_fight(app, combat, where, fights == 1)
				fights += 1
			elif app.current is GameOverScreen:
				await _check(app.current, where + " game over")
				var state: Dictionary = port.get_state()
				print(
					(
						"GAME seed %d: place %s after %d turns, ghosts %d, top tier %d, actions %s"
						% [
							game_seed,
							str(state.get("placement")),
							turns,
							ghosts,
							top_tier,
							driver.counts
						]
					)
				)
				var moments: PackedStringArray = app.current.get("moments")
				print("MOMENTS seed %d: %s" % [game_seed, " | ".join(moments)])
				_press_named(app.current, "Main menu")
				await _frames(2)
				driver.expect(app.current is MainMenu, "Main menu: stayed on game over")
				if not app.current is MainMenu:
					app.show_menu()
					await _frames(2)
				_drain_misses(where)
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


## A card new to the hand swells for a moment on purpose (_pulse_new_hand_card): wait that out.
func _settle(recruit: RecruitScreen) -> void:
	var grid: Node = recruit.get("_hand_cards")
	for frame: int in 120:
		var action: Control = recruit.get("_action_motion")
		var feedback: Control = recruit.get("_feedback")
		var swollen: bool = CoreUtil.to_bool(action.get("active")) or feedback.is_processing()
		for child: Node in grid.get_children():
			swollen = swollen or (child as Control).scale.x > 1.001
		if not swollen:
			return
		await process_frame


## --late: gaps filled, the full board and hand checked, then the crowded hand laid out in full.
func _check_full(recruit: RecruitScreen, driver: PlayerDriver, where: String) -> void:
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
	if not _is_full(recruit.state):
		var limit: int = Data.i(
			recruit.state, "hand_limit", GameConfig.full_game().get_int("hand_limit")
		)
		_problem("%s: late check not full (board %d/7, hand %d/%d)" % [where, placed, hand, limit])
	await _check(recruit, where + " recruit, full board and hand")
	driver.tap(recruit, "hand", 0)
	await _frames(2)
	await _check(recruit, where + " recruit, hand card selected")
	driver.tap(recruit, "hand", 0)
	var grid: Node = recruit.get("_hand_cards")
	var more: Button = grid.get_child(grid.get_child_count() - 1) as Button
	if more != null:
		grid.notification(Container.NOTIFICATION_SORT_CHILDREN)
		driver.press(more, "more of the hand")
		await _frames(2)
		await _check(recruit, where + " recruit, whole hand open", false)
		_press_named(recruit, "Back")
		await _frames(2)
