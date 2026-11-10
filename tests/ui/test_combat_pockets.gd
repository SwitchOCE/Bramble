extends GutTest
## Combat's changing floor state remains readable without captions or relation lines.

const BoardView := preload("res://src/ui/widgets/board_view.gd")
const SlotMarks := preload("res://src/ui/widgets/slot_marks.gd")
const UiTheme := preload("res://src/ui/ui_theme.gd")


func _board() -> BoardView:
	var board: BoardView = BoardView.new()
	board.combat_mode = true
	board.configure("enemy", 189, false, true, true)
	add_child_autofree(board)
	return board


func _visible_words(node: Node) -> PackedStringArray:
	var words: PackedStringArray = []
	var label: Label = node as Label
	if label != null and label.is_visible_in_tree() and not label.text.is_empty():
		words.append(label.text)
	for child: Node in node.get_children():
		words.append_array(_visible_words(child))
	return words


func test_combat_pockets_have_no_empty_slot_codes_ring_or_nest_captions() -> void:
	var board: BoardView = _board()
	var marks: Array = []
	marks.resize(7)
	marks.fill({})
	marks[0] = {"has_ring": true, "ring": "+3/+3", "ring_count": 2}
	marks[4] = {"nest": true, "nest_left": 1, "egg_attack": 3, "egg_health": 3}
	board.set_marks(marks)
	assert_false(board.with_labels, "combat cannot reserve a name-strip row")
	assert_false(board.with_notes)
	assert_eq(_visible_words(board), PackedStringArray())
	for slot: Control in board.slots:
		var wordless: bool = slot.get("wordless")
		assert_true(wordless)
		assert_gte(slot.size.x, 90.0, "marked empty pocket remains a full tap target")


func test_combat_hex_and_trap_keep_amounts_and_reader_state_without_words() -> void:
	var board: BoardView = _board()
	board.set_hex(0, 3, 25)
	board.set_trap(0, 4)
	var marks: SlotMarks = board.get("_marks")
	assert_eq(marks._hex_labels[0].text, "−3\n−25%")
	assert_eq(marks._trap_labels[0].text, "4")
	assert_gte(marks._hex_labels[0].get_theme_font_size("font_size"), UiTheme.MIN_FONT)
	assert_gte(marks._trap_labels[0].get_theme_font_size("font_size"), UiTheme.MIN_FONT)
	assert_eq(_visible_words(board).size(), 2, "two numeric state nodes")
	board.clear()
	assert_true(marks._hex_labels.is_empty())
	assert_true(marks._trap_labels.is_empty())
	assert_eq(_visible_words(board), PackedStringArray(), "replay clears its floor state")
