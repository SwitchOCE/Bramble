extends GutTest
## Ring counts are changing state; geometry and unit rules leave the floor marks.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const CardView := preload("res://src/ui/widgets/card_view.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")
const StatNumbers := preload("res://src/ui/stat_numbers.gd")


func after_each() -> void:
	CardView.window_override = Vector2.ZERO


func test_only_multiple_own_rings_have_a_number_and_it_clears_the_stat_beads() -> void:
	for width: float in [122.0, 160.0, 209.0]:
		var board := BoardView.new()
		board.theme = UiTheme.get_theme()
		board.configure("board", width, true, true)
		add_child_autofree(board)
		var card := CardView.new()
		card.show_unit(
			{"def_id": "field_vole", "name": "Field Vole", "attack": 46, "health": 48},
			CardView.Mode.BOARD
		)
		board.place_card(card, 0)
		var marks: Array = [{"has_ring": true, "ring_count": 1}, {}, {}, {}, {}, {}, {}]
		board.set_marks(marks)
		var slot_marks: Control = board.get("_marks")
		var labels: Array = slot_marks.get("_ring_labels")
		var label: Label = labels[0]
		assert_false(label.visible, "one Ring already reads through its dots")
		for count: int in [2, 36, 12345]:
			marks[0]["ring_count"] = count
			board.set_marks(marks)
			assert_true(label.visible)
			assert_eq(label.text, StatNumbers.compact(count))
			assert_gte(label.get_theme_font_size("font_size"), UiTheme.MIN_FONT)
			for key: String in ["_attack_badge", "_health_badge"]:
				var bead: Control = card.get(key)
				assert_false(label.get_global_rect().intersects(bead.get_global_rect()))
		for strip: Control in board.get("_labels"):
			assert_false(strip.visible)


func test_scout_ring_floor_marks_keep_state_without_count_or_unit_name_strips() -> void:
	var board := BoardView.new()
	board.configure("scout", 136, false, true)
	add_child_autofree(board)
	board.set_marks([{"has_ring": true, "ring_count": 36}, {}, {}, {}, {}, {}, {}])
	var marks: Control = board.get("_marks")
	var labels: Array = marks.get("_ring_labels")
	var label: Label = labels[0]
	assert_false(label.visible)
	assert_true(board.slots[0].filled)
	for strip: Control in board.get("_labels"):
		assert_false(strip.visible)
