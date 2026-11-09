extends GutTest
## Ring counts belong to their slots and must leave slot names and unit chips readable.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func test_counted_rings_clear_slot_names_unit_names_and_keyword_chips() -> void:
	for width: float in [122.0, 160.0, 209.0]:
		var board: BoardView = BoardView.new()
		board.theme = UiTheme.get_theme()
		board.configure("board", width, true, true)
		add_child_autofree(board)
		for slot: int in [0, 4]:
			var card: CardView = CardView.new()
			card.show_unit(
				{
					"name": "Hedge Witch",
					"text": "Start of Combat: lose Attack.",
					"attack": 46,
					"health": 48
				},
				CardView.Mode.BOARD
			)
			board.place_card(card, slot)
		var marks: Array = [{}, {}, {}, {}, {}, {}, {}]
		for slot: int in [0, 4]:
			marks[slot] = {"has_ring": true, "ring": "+45/+45 · 36", "ring_count": 36}
		board.set_marks(marks)
		await get_tree().process_frame
		var slot_marks: Control = board.get("_marks")
		var badges: Array = slot_marks.get("_ring_labels")
		var strips: Array = board.get("_labels")
		var names: Array = board.get("_label_names")
		for slot: int in [0, 4]:
			var badge: Label = badges[slot]
			var strip: Panel = strips[slot]
			var slot_name: Label = strip.get_child(0) as Label
			var unit_name: Label = names[slot]
			var keyword: Control = board.cards[slot].get("_chip")
			assert_eq(badge.text, "×36")
			assert_gte(badge.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
			assert_true(board.label_rect(slot).encloses(badge.get_rect()))
			assert_false(badge.get_global_rect().intersects(slot_name.get_global_rect()))
			if not unit_name.text.is_empty():
				assert_false(badge.get_global_rect().intersects(unit_name.get_global_rect()))
			assert_false(badge.get_global_rect().intersects(keyword.get_global_rect()))
		marks[0] = {"has_ring": true, "ring": "+1m/+1m · 12.3k", "ring_count": 12345}
		board.set_marks(marks)
		await get_tree().process_frame
		var large: Label = badges[0]
		var first_strip: Panel = strips[0]
		var first_slot_name: Label = first_strip.get_child(0) as Label
		assert_true(board.label_rect(0).encloses(large.get_rect()))
		assert_false(large.get_global_rect().intersects(first_slot_name.get_global_rect()))
