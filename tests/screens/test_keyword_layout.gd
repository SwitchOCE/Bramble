extends GutTest

const CARD: Rect2 = Rect2(0, 0, 224, 400)
const WORDS: Rect2 = Rect2(240, 0, 340, 200)


func test_card_and_words_keep_the_preferred_position_when_clear() -> void:
	var at: Vector2 = Vector2(982, 386)
	assert_eq(KeywordLayout.place(CARD, WORDS, at, [Rect2(26, 214, 330, 640)]), at)


func test_card_and_words_move_as_one_clear_of_the_column_and_controls() -> void:
	var column: Rect2 = Rect2(26, 214, 330, 640)
	var control: Rect2 = Rect2(500, 500, 140, 250)
	var stage: Rect2 = Rect2(0, 0, 1920, 1080)
	var at: Vector2 = KeywordLayout.place(CARD, WORDS, Vector2(200, 600), [column, control])
	for local: Rect2 in [CARD, WORDS]:
		var rect: Rect2 = Rect2(at + local.position, local.size)
		assert_true(stage.encloses(rect))
		assert_false(rect.intersects(column))
		assert_false(rect.intersects(control))


func test_words_alone_move_left_of_the_right_screen_edge() -> void:
	var words: Rect2 = Rect2(0, 0, 340, 400)
	var at: Vector2 = KeywordLayout.place(Rect2(), words, Vector2(1700, 900), [])
	assert_eq(at, Vector2(1568, 668))
