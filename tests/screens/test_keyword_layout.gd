extends GutTest
## The keyword column moves as one piece and only changes sides when it is too tall.


func _assert_clear(rects: Array[Rect2], source: Rect2, protected: Array[Rect2]) -> void:
	var occupied: Array[Rect2] = [source]
	occupied.append_array(protected)
	for rect: Rect2 in rects:
		assert_true(Rect2(0, 0, 1920, 1080).encloses(rect))
		for other: Rect2 in occupied:
			assert_false(rect.intersects(other))
		occupied.append(rect)


func test_details_join_below_rules_even_when_the_group_must_move_up() -> void:
	var card: Rect2 = Rect2(0, 0, 230, 400)
	var words: Rect2 = Rect2(250, 0, 340, 200)
	var source: Rect2 = Rect2(900, 300, 140, 250)
	var sizes: Array[Vector2] = [Vector2(340, 200), Vector2(340, 200), Vector2(340, 200)]
	var result: Array[Vector2] = KeywordLayout.arrange(
		card, words, Vector2(600, 900), source, sizes
	)
	assert_eq(result.size(), 4)
	if result.size() != 4:
		return
	var main: Rect2 = Rect2(result[0] + words.position, words.size)
	var rects: Array[Rect2] = [Rect2(result[0] + card.position, card.size), main]
	var y: float = main.end.y
	for i: int in sizes.size():
		assert_eq(result[i + 1].x, main.position.x)
		assert_eq(result[i + 1].y, y)
		rects.append(Rect2(result[i + 1], sizes[i]))
		y += sizes[i].y
	_assert_clear(rects, source, [])


func test_too_tall_column_falls_beside_rules_as_an_intact_top_aligned_stack() -> void:
	var card: Rect2 = Rect2(0, 0, 230, 400)
	var words: Rect2 = Rect2(250, 0, 340, 500)
	var source: Rect2 = Rect2(1700, 300, 140, 250)
	var protected: Array[Rect2] = [Rect2(20, 400, 160, 160), Rect2(1700, 850, 180, 180)]
	var sizes: Array[Vector2] = [Vector2(340, 400), Vector2(340, 400)]
	var result: Array[Vector2] = KeywordLayout.arrange(
		card, words, Vector2(600, 200), source, sizes, protected
	)
	assert_eq(result.size(), 3)
	if result.size() != 3:
		return
	var main: Rect2 = Rect2(result[0] + words.position, words.size)
	assert_eq(result[1], Vector2(main.end.x, main.position.y), "away from enlarged card, no gap")
	assert_eq(result[2], result[1] + Vector2(0, sizes[0].y), "keep detail panes touching")
	_assert_clear(
		[
			Rect2(result[0] + card.position, card.size),
			main,
			Rect2(result[1], sizes[0]),
			Rect2(result[2], sizes[1])
		],
		source,
		protected
	)


func test_icon_only_details_move_as_one_touching_column_around_protected_controls() -> void:
	var source: Rect2 = Rect2(900, 300, 140, 250)
	var protected: Array[Rect2] = [Rect2(20, 400, 160, 160), Rect2(1700, 850, 180, 180)]
	var sizes: Array[Vector2] = [Vector2(330, 300), Vector2(330, 250)]
	var result: Array[Vector2] = KeywordLayout.arrange(
		Rect2(), Rect2(), source.position, source, sizes, protected
	)
	assert_eq(result.size(), 3)
	if result.size() != 3:
		return
	assert_eq(result[2], result[1] + Vector2(0, sizes[0].y))
	_assert_clear([Rect2(result[1], sizes[0]), Rect2(result[2], sizes[1])], source, protected)


func test_side_fallback_flips_to_the_left_when_enlarged_card_is_on_the_right() -> void:
	var card: Rect2 = Rect2(360, 0, 230, 400)
	var words: Rect2 = Rect2(0, 0, 340, 500)
	var source: Rect2 = Rect2(1700, 300, 140, 250)
	var sizes: Array[Vector2] = [Vector2(340, 400), Vector2(340, 400)]
	var result: Array[Vector2] = KeywordLayout.arrange(
		card, words, Vector2(600, 200), source, sizes
	)
	assert_eq(result.size(), 3)
	if result.size() != 3:
		return
	var main: Rect2 = Rect2(result[0] + words.position, words.size)
	assert_eq(result[1], main.position - Vector2(sizes[0].x, 0))
	assert_eq(result[2], result[1] + Vector2(0, sizes[0].y))
	_assert_clear(
		[
			Rect2(result[0] + card.position, card.size),
			main,
			Rect2(result[1], sizes[0]),
			Rect2(result[2], sizes[1])
		],
		source,
		[]
	)
