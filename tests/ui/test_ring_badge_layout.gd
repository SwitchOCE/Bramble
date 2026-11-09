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


func test_redbreast_keeps_its_name_beside_the_ring_count_in_the_overview() -> void:
	var expected_names: Array[String] = ["Witch", "Redbreast", "Hearth"]
	for window: Vector2 in [Vector2(1688, 780), Vector2(1920, 1080)]:
		CardView.window_override = window
		var board := BoardView.new()
		board.theme = UiTheme.get_theme()
		board.configure("board", 209.0, true, true)
		add_child_autofree(board)
		for slot: int in [4, 5, 6]:
			var card := CardView.new()
			card.show_unit(
				{
					"name": ["Hedge Witch", "Mr Redbreast", "Hob in the Hearth"][slot - 4],
					"attack": 5,
					"health": 7
				},
				CardView.Mode.BOARD
			)
			board.place_card(card, slot)
		var marks: Array = [{}, {}, {}, {}, {}, {}, {}]
		for slot: int in [4, 5, 6]:
			var count: int = 36 if slot == 4 else 2
			marks[slot] = {"has_ring": true, "ring_count": count}
		board.set_marks(marks)
		await get_tree().process_frame
		var names: Array = board.get("_label_names")
		var strips: Array = board.get("_labels")
		var slot_marks: Control = board.get("_marks")
		var badges: Array = slot_marks.get("_ring_labels")
		for slot: int in [4, 5, 6]:
			var name_label: Label = names[slot]
			var strip: Panel = strips[slot]
			var coordinate: Label = strip.get_child(0) as Label
			var badge: Label = badges[slot]
			assert_eq(name_label.text, expected_names[slot - 4])
			assert_gte(
				name_label.size.x,
				(
					name_label
					. get_theme_font("font")
					. get_string_size(
						name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.MIN_FONT
					)
					. x
				),
				"the complete last word fits without clipping or an ellipsis"
			)
			assert_eq(coordinate.text, "B%d" % (slot - 3))
			assert_true(coordinate.is_visible_in_tree())
			assert_true(board.label_rect(slot).encloses(badge.get_rect()))
			assert_false(badge.get_global_rect().intersects(name_label.get_global_rect()))
			assert_false(badge.get_global_rect().intersects(coordinate.get_global_rect()))
			assert_gte(name_label.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
		board.configure("board", 180.0, true, true)
		board.configure("board", 209.0, true, true)
		await get_tree().process_frame
		var redbreast: Label = names[5]
		assert_eq(
			redbreast.text, "Redbreast", "returning from the reader restores the overview name"
		)
	CardView.window_override = Vector2.ZERO
