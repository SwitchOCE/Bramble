extends GutTest
## The scripted player (tests/ui/player_driver.gd) plays whole games through the real App and
## the recruit screen's own input paths, combats skipped to their result, to the game over
## screen. GUT fails the test on any engine or script error along the way. The full run, with
## combats watched at 4x and layout checks at both sizes, is tests/ui/shots/playthrough.gd.

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
	for action: String in ["buy by tap", "buy by drag to board", "play by tap", "end turn"]:
		assert_true(all_counts.has(action), "the player used %s" % action)


func test_layout_check_finds_a_label_that_does_not_fit() -> void:
	var box: HBoxContainer = HBoxContainer.new()
	add_child_autofree(box)
	box.size = Vector2(60, 40)
	var label: Label = Label.new()
	label.text = "far too long for sixty pixels"
	label.clip_text = true
	label.custom_minimum_size = Vector2(60, 0)
	box.add_child(label)
	await get_tree().process_frame
	var found: PackedStringArray = LayoutCheck.problems(box, "test")
	assert_eq(found.size(), 1)
	assert_string_contains(found[0], "wider than its box")


func test_long_card_text_is_cut_at_a_sentence_not_mid_word() -> void:
	var port: CorePort = CorePort.new()
	port.setup()
	var view: Dictionary = UnitViews.from_def(port.library.get_unit("sett_warden"))
	var card: CardView = CardView.new()
	add_child_autofree(card)
	card.set_card_width(168)
	card.show_unit(view, CardView.Mode.FULL)
	await get_tree().process_frame
	var label: Label = card.get("_text_label")
	assert_eq(label.get_visible_line_count(), label.get_line_count(), "nothing hidden")
	if label.text != Data.s(view, "text"):
		assert_eq(label.text, "Hunker. …", "whole sentences, then the ellipsis")
