extends GutTest

const CombatScreen := preload("res://src/ui/screens/combat_screen.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const Guide := preload("res://src/ui/screens/how_to_play.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_engine_result_lines_fit_desktop_and_phone_without_smaller_type() -> void:
	for phone: bool in [false, true]:
		CardView.window_override = Vector2(1688, 780) if phone else Vector2(1920, 1080)
		var screen := CombatScreen.new()
		add_child_autofree(screen)
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(2337, 1080) if phone else Vector2(1920, 1080)
		screen._layout()
		screen.model.winner = 1
		screen.model.damage = 18
		screen.model.damage_uncapped = 18
		screen._log_text.side_names = PackedStringArray(["You", "Hob Mumblecrust"])
		screen.model.result_rules = {
			"winner": 1,
			"last_blow": true,
			"last_blow_kind": "effect",
			"damage_base": 6,
			"round_toll": 12,
			"damage_uncapped": 18,
			"alive": 4,
			"damage_cap": 0,
			"last_stand_sides": [0]
		}
		screen._show_result()
		await get_tree().process_frame
		var text: Label = screen._result_text
		for words: String in [
			"Last Blow", "6 + 12 toll = 18", "Cap lifted: 4 left", "Last Stand", "1 Health"
		]:
			assert_string_contains(text.text, words)
		assert_lte(text.get_minimum_size().y, text.size.y, "all result lines fit")
		assert_gte(text.get_theme_font_size("font_size"), 36)


func test_guide_names_every_adopted_engine() -> void:
	var words: String = ""
	for page: Dictionary in Guide.PAGES:
		words += str(page["text"])
	for rule: String in [
		"Last Blow",
		"Start of Combat",
		"four",
		"Last Stand",
		"2+ Health",
		"Ghosts",
		"tier 3, Harvest Supper"
	]:
		assert_string_contains(words, rule)
