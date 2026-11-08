extends GutTest
@warning_ignore_start("unsafe_call_argument", "unsafe_method_access")
const RecruitView := preload("res://src/ui/screens/recruit_view.gd")
const BoardView := preload("res://src/ui/widgets/board_view.gd")


func test_horseshoe_is_visible_on_empty_slot_and_distinct_from_a_ring() -> void:
	var effects: Array = [
		[],
		[
			{
				"name": "Horseshoe",
				"attack": 0,
				"health": 0,
				"text": "Next fight: the Ring across gives half."
			}
		],
		[],
		[],
		[],
		[],
		[]
	]
	var marks: Array = RecruitView.slot_marks({"slot_effects": effects})
	var mark: Dictionary = marks[1]
	assert_false(mark["has_ring"])
	assert_true(mark["horseshoe"])
	assert_string_contains(RecruitView.slot_note(mark, 1), "F2: Horseshoe (next fight)")
	var board: BoardView = BoardView.new()
	board.configure("board", 180, true, true)
	add_child_autofree(board)
	board.set_marks(marks)
	assert_true(board.slots[1].filled)
	assert_null(board.cards[1], "spell does not occupy the playable slot")
