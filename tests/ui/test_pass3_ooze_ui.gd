extends GutTest
## Fixed recruit cards only: no game or lobby runs, and no new reminder labels.
@warning_ignore_start("unsafe_call_argument")

const CardView := preload("res://src/ui/widgets/card_view.gd")
const CardDetail := preload("res://src/ui/widgets/card_detail.gd")
const OozeMarks := preload("res://src/ui/widgets/ooze_marks.gd")
const RecruitScreen := preload("res://src/ui/screens/recruit_screen.gd")
const FixturePort := preload("res://src/ui/adapter/fixture_port.gd")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const RecruitOozes := preload("res://src/ui/screens/recruit_oozes.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func _ooze() -> Dictionary:
	return {
		"iid": 91,
		"def_id": "little_dollop",
		"name": "Little Dollop",
		"tier": 1,
		"attack": 31,
		"health": 42,
		"text": "Belly 1. Digest. Buying into this costs 1 gold less.",
		"tribes": ["Oozes"],
		"keywords": ["Belly", "Digest"],
		"ooze_ladle": true,
		"ooze_digest_preview": Vector2i(12, 17),
		"held": [{"def_id": "field_vole", "name": "Field Vole", "tribes": ["Hedgerow"]}]
	}


func test_ladle_and_held_meal_are_wordless_marks_inside_the_portrait() -> void:
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		CardView.window_override = window
		var card: CardView = CardView.new()
		add_child_autofree(card)
		card.show_unit(_ooze(), CardView.Mode.BOARD)
		card.set_card_width(189)
		var art: Control = card.get("_art")
		var marks: OozeMarks = card.get("_ooze_marks")
		assert_true(marks.ladle)
		assert_not_null(marks.meal)
		assert_eq(marks.get_child_count(), 0, "drawn marks add no text nodes")
		assert_eq(marks.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_true(Rect2(Vector2.ZERO, art.size).encloses(marks.get_rect()))
		assert_eq(card.unit["attack"], 31)
		assert_eq(card.unit["health"], 42)
		assert_false(card.chip_shown.contains("12/17"), "Digest preview stays in the reader")
		assert_string_contains(CardDetail.full_text_bbcode(card.unit), "+12/+17")


func test_live_soup_stats_use_a_pot_mark_and_reader_breakdown() -> void:
	var view: Dictionary = _ooze()
	view["held"] = []
	view["ooze_ladle"] = false
	view["ooze_soup_bonus"] = Vector2i(7, 9)
	var card: CardView = CardView.new()
	add_child_autofree(card)
	card.show_unit(view)
	var marks: OozeMarks = card.get("_ooze_marks")
	assert_true(marks.soup)
	assert_null(marks.meal)
	assert_false(marks.ladle)
	assert_string_contains(CardDetail.full_text_bbcode(view), "Stone Soup: +7/+9")
	assert_string_contains(CardDetail.full_text_bbcode(view), "kept when bought")
	assert_eq(card.unit["attack"], 31, "the UI does not add Soup to stats a second time")
	assert_eq(
		CardView.chip_text({"text": "Shop units gain an eighth of your biggest Ooze's stats."}),
		"Shop grows"
	)
	assert_eq(
		CardView.chip_text(
			{"text": "Oozes in front of this gain half more from eating non-Oozes."}
		),
		"Eat bonus"
	)
	assert_eq(
		CardView.chip_text(
			{
				"text":
				"After your biggest Ooze eats a non-Ooze: your other Oozes gain half its stats."
			}
		),
		"Meal share"
	)


func test_marks_clear_when_a_reused_card_no_longer_has_ooze_state() -> void:
	var card: CardView = CardView.new()
	add_child_autofree(card)
	card.show_unit(_ooze())
	card.show_unit({"name": "Field Vole", "def_id": "field_vole", "tribes": ["Hedgerow"]})
	var marks: OozeMarks = card.get("_ooze_marks")
	assert_false(marks.visible)
	assert_null(marks.meal)
	assert_false(marks.ladle)
	assert_false(marks.soup)
	var legacy: Dictionary = _ooze()
	legacy.erase("ooze_ladle")
	legacy.erase("ooze_digest_preview")
	card.show_unit(legacy)
	assert_null(marks.meal, "legacy Belly faces remain unchanged")


func test_nell_hover_highlights_the_resolved_eater_and_aspic_the_front_slots() -> void:
	var nell: Dictionary = {
		"def_id": "dishwater_nell",
		"text": "Start of Turn: the biggest Ooze next to this eats your shop's lowest-tier unit.",
		"ooze_nell_eaters": [1]
	}
	assert_eq(RecruitView.related_slots(nell, 5), [1])
	assert_string_contains(RecruitView.geometry_note(nell, 5), "Current eater: F2")
	nell["ooze_nell_eaters"] = [1, 2]
	assert_eq(RecruitView.related_slots(nell, 5), [1, 2])
	var board: BoardView = BoardView.new()
	add_child_autofree(board)
	var interaction: RecruitOozes = RecruitOozes.new()
	var preview: Dictionary = interaction.hover(board, nell, 5, true)
	assert_eq(board.get("_relations"), [1, 2])
	assert_string_contains(str(preview["text"]), "Current eater: F2 and F3")
	interaction.hover(board, {}, 5, false)
	assert_eq(board.get("_relations"), [])
	nell["ooze_nell_eaters"] = []
	assert_eq(RecruitView.related_slots(nell, 5), [])
	assert_eq(RecruitView.geometry_note(nell, 5), "No Ooze next to this.")
	assert_eq(
		RecruitView.related_slots({"text": "Oozes in front of this gain half more."}, 4), [0, 1]
	)


func test_elder_share_landing_pulses_once_per_new_serial_without_a_label() -> void:
	var port: FixturePort = FixturePort.new()
	port.use_state_file("res://tests/ui/data/recruit_slice.json")
	var state: Dictionary = port.get_state()
	var view: Dictionary = _ooze()
	view["ooze_share_serial"] = 1
	state["board"] = [view, null, null, null, null, null, null]
	var screen: RecruitScreen = RecruitScreen.new()
	add_child_autofree(screen)
	screen.setup(port)
	var board: Control = screen.get("_board")
	var cards: Array = board.get("cards")
	var first: CardView = cards[0]
	var mark: OozeMarks = first.get("_ooze_marks")
	assert_eq(mark.landing, 1.0)
	assert_eq(mark.get_child_count(), 0)
	screen.render()
	cards = board.get("cards")
	var second: CardView = cards[0]
	mark = second.get("_ooze_marks")
	assert_eq(mark.landing, 0.0, "rendering unchanged state does not replay the landing")
	view["ooze_share_serial"] = 2
	screen.render()
	cards = board.get("cards")
	var third: CardView = cards[0]
	mark = third.get("_ooze_marks")
	assert_eq(mark.landing, 1.0)
	await wait_process_frames(2)
