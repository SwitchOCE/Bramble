extends GutTest
## The scripted player (tests/ui/player_driver.gd) plays whole games through the real App by
## calling the recruit screen's handlers, combats skipped to their result, to the game over
## screen. Every drop's _can_drop answer must match the rules. GUT fails the test on any engine
## or script error along the way. The full run, with combats watched at 4x and layout checks at
## both sizes, is tests/ui/shots/playthrough.gd.

const CorePort := preload("res://src/ui/adapter/core_port.gd")
const App := preload("res://src/ui/app.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const GameOverScreen := preload("res://src/ui/screens/game_over_screen.gd")
const PlayerDriver := preload("res://tests/ui/player_driver.gd")
const LayoutCheck := preload("res://tests/ui/layout_check.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const Records := preload("res://src/ui/records.gd")
const UnitViews := preload("res://src/ui/unit_views.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const SEEDS: Array[int] = [101, 202]
const MAX_TURNS: int = 60


func before_all() -> void:
	Records.path = "user://test_records.cfg"


func test_scripted_player_reaches_game_over() -> void:
	var app: App = App.new()
	add_child_autofree(app)
	var port: CorePort = CorePort.new()
	port.setup()
	app.setup(port)
	var all_counts: Dictionary = {}
	for game_seed: int in SEEDS:
		var driver: PlayerDriver = PlayerDriver.new(game_seed)
		app.start_game(game_seed)
		var turns: int = 0
		while app.current is RecruitScreen and turns < MAX_TURNS:
			driver.play_turn(app.current as RecruitScreen)
			turns += 1
			if app.current is CombatScreen:
				var combat: CombatScreen = app.current as CombatScreen
				combat.skip_to_end()
				assert_true(combat.is_showing_result())
				combat.finished.emit()
		assert_true(app.current is GameOverScreen, "seed %d ends at game over" % game_seed)
		for action: String in driver.counts:
			all_counts[action] = true
		assert_eq(driver.drop_mismatches, PackedStringArray(), "seed %d drops" % game_seed)
	for action: String in [
		"buy by tap", "buy by drop on board", "play by tap", "refused drop", "end turn"
	]:
		assert_true(all_counts.has(action), "the player used %s" % action)


## Nothing on a tile is cut at any size it's shown at, and the full rules text is a tap away.
func test_every_unit_fits_its_tiles_and_keeps_its_full_text() -> void:
	var port: CorePort = CorePort.new()
	port.setup(GameConfig.defaults())
	port.manual_choices = false
	var themed: Control = Control.new()
	themed.theme = UiTheme.get_theme()
	themed.size = Vector2(1920, 1080)
	add_child_autofree(themed)
	var sizes: Array = [
		[CardView.Mode.SHOP, 270.0],
		[CardView.Mode.SHOP, 196.0],
		[CardView.Mode.BOARD, 189.0],
		[CardView.Mode.BOARD, 171.0],
		[CardView.Mode.MINI, 130.0]
	]
	var checked: int = 0
	for def: Dictionary in port.library.all_units():
		# The slice's exact text is the UI branch's to fit: Woodcraft's card replaces this one.
		if def.has("set"):
			continue
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(def, golden)
			var rules: String = Data.s(view, "text")
			if not rules.is_empty():
				var full: String = CardDetail.full_text_bbcode(view)
				assert_true(full.contains(rules.left(8)), "full text: " + Data.s(view, "def_id"))
			for entry: Array in sizes:
				var card: CardView = CardView.new()
				var mode: CardView.Mode = entry[0]
				var width: float = entry[1]
				card.show_unit(view, mode)
				card.set_card_width(width)
				card.position = Vector2(200, 200)
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
				themed.add_child(card)
				var problems: PackedStringArray = LayoutCheck.problems(card, "tile", false)
				assert_eq(problems, PackedStringArray(), Data.s(view, "def_id"))
				card.free()
				checked += 1
	assert_gt(checked, 200)


func test_game_over_screen_lays_out_cleanly() -> void:
	var config: GameConfig = GameConfig.defaults()
	config.set_value("human_bot", "greedy")
	var app: App = App.new()
	add_child_autofree(app)
	var port: CorePort = CorePort.new()
	port.setup(config)
	app.setup(port)
	app.start_game(20261104)
	var turns: int = 0
	while app.current is RecruitScreen and turns < MAX_TURNS:
		(app.current as RecruitScreen).call("_on_end_turn")
		if app.current is CombatScreen:
			(app.current as CombatScreen).finished.emit()
		turns += 1
	assert_true(app.current is GameOverScreen)
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: Control = app.current
	assert_eq(LayoutCheck.problems(screen, "game over"), PackedStringArray())
