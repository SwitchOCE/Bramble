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
const UnitViews := preload("res://src/ui/unit_views.gd")
const Data := preload("res://src/ui/view_data.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")

const SEEDS: Array[int] = [101, 202]
const MAX_TURNS: int = 60


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


func test_no_card_text_is_hidden_or_cut_at_138_to_168_px() -> void:
	var port: CorePort = CorePort.new()
	port.setup()
	# Cards are built outside the tree, then added under the app's theme, as the screens do.
	var themed: Control = Control.new()
	themed.theme = UiTheme.get_theme()
	add_child_autofree(themed)
	var checked: int = 0
	for def: Dictionary in port.library.all_units():
		# The slice's exact text is the UI branch's to fit: Woodcraft's card replaces this one.
		if def.has("set"):
			continue
		for golden: bool in [false, true]:
			var view: Dictionary = UnitViews.from_def(def, golden)
			var text: String = Data.s(view, "text")
			if text.is_empty():
				continue
			for width: int in range(138, 170, 2):
				var card: CardView = CardView.new()
				card.show_unit(view, CardView.Mode.FULL)
				card.set_card_width(float(width))
				themed.add_child(card)
				await get_tree().process_frame
				var label: Label = card.get("_text_label")
				var where: String = (
					"%s%s at %d px ('%s')"
					% [Data.s(view, "def_id"), " golden" if golden else "", width, label.text]
				)
				assert_true(
					label.get_visible_line_count() >= label.get_line_count(), "hidden: " + where
				)
				assert_false(label.text.ends_with(" …"), "cut: " + where)
				for chip: String in card.keyword_chips:
					assert_true(
						text.contains(chip + "."), "chip is a sentence of the text: " + where
					)
				card.queue_free()
				checked += 1
	assert_gt(checked, 200, "every unit with text, base and golden, at every width")


## The shorter portrait is for text still too long once its keyword chips are pulled, not for
## any card with a chip (review, 4 Nov).
func test_a_chip_alone_keeps_the_full_portrait() -> void:
	var port: CorePort = CorePort.new()
	port.setup()
	var themed: Control = Control.new()
	themed.theme = UiTheme.get_theme()
	add_child_autofree(themed)
	var def: Dictionary = port.library.get_unit("still_water_heron")
	var card: CardView = CardView.new()
	card.show_unit(UnitViews.from_def(def), CardView.Mode.FULL)
	card.set_card_width(168.0)
	themed.add_child(card)
	await get_tree().process_frame
	assert_false(card.keyword_chips.is_empty(), "the heron's keyword moves to a chip")
	assert_eq(card.text_font_size, 16)
	var tall: bool = card.get("_tall_text")
	assert_false(tall, "full portrait")


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
